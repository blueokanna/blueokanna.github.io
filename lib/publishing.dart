import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'localization.dart';
import 'content.dart';

class PublishingException implements Exception {
  const PublishingException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ArticleDraft {
  const ArticleDraft({
    required this.id,
    required this.language,
    required this.title,
    required this.summary,
    required this.category,
    required this.body,
  });
  factory ArticleDraft.fromJson(Map<String, dynamic> json) => ArticleDraft(
    id: json['id'] as String,
    language: json['language'] as String,
    title: json['title'] as String,
    summary: json['summary'] as String,
    category: json['category'] as String,
    body: json['body'] as String,
  );
  final String id, language, title, summary, category, body;
  Map<String, String> toJson() => {
    'id': id,
    'language': language,
    'title': title,
    'summary': summary,
    'category': category,
    'body': body,
  };
  void validate() {
    if (!RegExp(r'^[a-z][a-z0-9-]{1,63}$').hasMatch(id) ||
        !languages.containsKey(language)) {
      throw const PublishingException('文章 ID 须为 2–64 位小写字母、数字或连字符，且以字母开头。');
    }
    if (title.trim().isEmpty ||
        title.length > 160 ||
        summary.trim().isEmpty ||
        summary.length > 600 ||
        category.trim().isEmpty ||
        category.length > 40 ||
        body.trim().isEmpty ||
        utf8.encode(body).length > 131072) {
      throw const PublishingException('请填写标题、摘要、分类和正文；正文上限为 128 KiB。');
    }
  }

  String encode() {
    validate();
    final metadata = {...toJson()}..remove('body');
    return '---\n${jsonEncode(metadata)}\n---\n\n${body.trim()}\n';
  }

  static ArticleDraft decode(String text) {
    final match = RegExp(r'^---\r?\n([^\n]+)\r?\n---\r?\n').firstMatch(text);
    if (match == null) throw const PublishingException('文章元数据格式不受支持。');
    final json = jsonDecode(match.group(1)!) as Map<String, dynamic>;
    final draft = ArticleDraft.fromJson({
      ...json,
      'body': text.substring(match.end).trim(),
    });
    draft.validate();
    return draft;
  }
}

/// GitHub is the authority. UI role checks are convenience, never a security
/// boundary. The credential is memory-only and sent only to api.github.com.
class Publisher extends ChangeNotifier {
  Publisher({http.Client? client}) : _client = client ?? http.Client();
  static const repository = 'blueokanna/blueokanna.github.io';
  static const branch = 'main';
  final http.Client _client;
  String? _token, login;
  bool _canPublish = false;
  bool get canPublish => _canPublish;
  static const ownerId = 56761243;
  int _generation = 0;
  bool _closed = false;
  Map<String, String> _headers(String token) => {
    'Accept': 'application/vnd.github+json',
    'Authorization': 'Bearer $token',
    'X-GitHub-Api-Version': '2022-11-28',
    'Content-Type': 'application/json',
  };
  Future<http.Response> _request(
    String method,
    String path,
    String token, {
    Object? body,
  }) async {
    final request = http.Request(
      method,
      Uri.https(
        'api.github.com',
        path,
        method == 'GET' && path.contains('/contents/') ? {'ref': branch} : null,
      ),
    );
    request.headers.addAll(_headers(token));
    request.followRedirects = false;
    if (body != null) request.body = jsonEncode(body);
    try {
      return await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw const PublishingException('GitHub 请求超时。发布结果可能尚未返回，请先读取远程版本再重试。');
    } on http.ClientException {
      throw const PublishingException('无法连接 GitHub，请检查网络后重试。');
    }
  }

  void _require(http.Response response, Set<int> accepted) {
    if (accepted.contains(response.statusCode)) return;
    throw PublishingException(switch (response.statusCode) {
      401 => 'GitHub 令牌无效或已过期，请重新登录。',
      403 => 'GitHub 拒绝了请求。请检查 Contents 写权限、仓库规则或 API 限流。',
      404 => 'GitHub 未找到资源，或令牌未获准访问此仓库。',
      409 || 422 => '远程文件已有变化、ID 已存在或仓库规则拒绝提交。请读取远程版本，合并后重试。',
      _ => 'GitHub 请求失败（HTTP ${response.statusCode}），未确认发布成功。',
    });
  }

  Future<void> connect(String token) async {
    if (!RegExp(r'^github_pat_[A-Za-z0-9_]{20,240}$').hasMatch(token)) {
      throw const PublishingException(
        '请输入 GitHub fine-grained personal access token。',
      );
    }
    final generation = ++_generation;
    _token = null;
    login = null;
    _canPublish = false;
    notifyListeners();
    final response = await _request('GET', '/user', token);
    _require(response, {200});
    final user = jsonDecode(response.body) as Map<String, dynamic>;
    var owner = false;
    if (user['login'] == 'blueokanna' && user['id'] == ownerId) {
      final repoResponse = await _request('GET', '/repos/$repository', token);
      _require(repoResponse, {200});
      final repo = jsonDecode(repoResponse.body) as Map<String, dynamic>;
      owner =
          repo['owner']['id'] == ownerId &&
          repo['permissions']?['push'] == true;
    }
    if (_closed || generation != _generation) return;
    _token = owner ? token : null;
    login = user['login'] as String;
    _canPublish = owner;
    notifyListeners();
  }

  String _credential() {
    if (_token == null || !canPublish) {
      throw const PublishingException('仅已验证的仓库所有者 blueokanna 可以发布。');
    }
    return _token!;
  }

  String _path(String language, String id) {
    if (!languages.containsKey(language) ||
        !RegExp(r'^[a-z][a-z0-9-]{1,63}$').hasMatch(id)) {
      throw const PublishingException('文章 ID 或语言无效。');
    }
    return '/repos/$repository/contents/content/posts/$language/$id.md';
  }

  Future<({ArticleDraft draft, String sha})> read(
    String language,
    String id,
  ) async {
    final response = await _request('GET', _path(language, id), _credential());
    _require(response, {200});
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final draft = ArticleDraft.decode(
      utf8.decode(
        base64Decode((json['content'] as String).replaceAll(RegExp(r'\s'), '')),
      ),
    );
    if (draft.id != id || draft.language != language) {
      throw const PublishingException('文件路径与文章元数据不一致。');
    }
    return (draft: draft, sha: json['sha'] as String);
  }

  Future<String> publish(ArticleDraft draft, {String? sha}) async {
    final encoded = draft.encode();
    final token = await _verifiedCredential();
    final response = await _request(
      'PUT',
      _path(draft.language, draft.id),
      token,
      body: {
        'message':
            '${sha == null ? 'Publish' : 'Update'} ${draft.language}/${draft.id}',
        'content': base64Encode(utf8.encode(encoded)),
        'branch': branch,
        if (sha != null) 'sha': sha,
      },
    );
    _require(response, {200, 201});
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['content']['sha'] as String;
  }

  Future<String> _verifiedCredential() async {
    final token = _credential();
    final generation = _generation;
    final response = await _request('GET', '/user', token);
    _require(response, {200});
    final user = jsonDecode(response.body) as Map<String, dynamic>;
    if (_closed ||
        generation != _generation ||
        user['login'] != 'blueokanna' ||
        user['id'] != ownerId) {
      throw const PublishingException('身份已失效，请重新验证 blueokanna 账号。');
    }
    return token;
  }

  Future<({List<FriendLink> links, String? sha})> readFriends() async {
    final generation = _generation;
    final response = await _request(
      'GET',
      '/repos/$repository/contents/content/friends.json',
      _credential(),
    );
    if (_closed || generation != _generation) {
      throw const PublishingException('会话已结束。');
    }
    if (response.statusCode == 404) return (links: List.of(friends), sha: null);
    _require(response, {200});
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final links = FriendLink.decode(
      utf8.decode(
        base64Decode((data['content'] as String).replaceAll(RegExp(r'\s'), '')),
      ),
    );
    return (links: links, sha: data['sha'] as String);
  }

  Future<String> publishFriends(List<FriendLink> links, {String? sha}) async {
    final content = FriendLink.encode(links);
    final token = await _verifiedCredential();
    final response = await _request(
      'PUT',
      '/repos/$repository/contents/content/friends.json',
      token,
      body: {
        'message': 'Update blogroll',
        'branch': branch,
        'content': base64Encode(utf8.encode(content)),
        if (sha != null) 'sha': sha,
      },
    );
    _require(response, {200, 201});
    return (jsonDecode(response.body) as Map<String, dynamic>)['content']['sha']
        as String;
  }

  void disconnect() {
    _generation++;
    _token = null;
    login = null;
    _canPublish = false;
    if (!_closed) notifyListeners();
  }

  @override
  void dispose() {
    _closed = true;
    disconnect();
    _client.close();
    super.dispose();
  }
}
