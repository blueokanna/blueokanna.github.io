import 'dart:convert';
import 'package:http/http.dart' as http;

Uri? safeWebUri(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
          uri.scheme == 'https' &&
          uri.host.isNotEmpty &&
          uri.userInfo.isEmpty
      ? uri
      : null;
}

class Repository {
  const Repository(
      this.name, this.description, this.url, this.language, this.stars);
  final String name, description, url, language;
  final int stars;
}

class RepositoryService {
  RepositoryService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  List<Repository>? _cache;
  DateTime? _loadedAt;
  Future<List<Repository>> load({bool refresh = false}) async {
    if (!refresh &&
        _cache != null &&
        DateTime.now().difference(_loadedAt!) < const Duration(minutes: 10)) {
      return _cache!;
    }
    final response = await _client.get(
        Uri.https('api.github.com', '/users/blueokanna/repos',
            {'per_page': '100', 'sort': 'updated'}),
        headers: {
          'Accept': 'application/vnd.github+json'
        }).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw StateError('GitHub HTTP ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    if (data is! List) throw const FormatException('Expected repositories');
    final repos = <Repository>[];
    for (final item in data) {
      if (item is! Map<String, dynamic> ||
          item['archived'] == true ||
          item['fork'] == true) {
        continue;
      }
      final name = item['name'], url = item['html_url'];
      if (name is! String ||
          url is! String ||
          safeWebUri(url)?.host != 'github.com') {
        continue;
      }
      repos.add(Repository(
          name,
          item['description'] is String ? item['description'] as String : '',
          url,
          item['language'] is String ? item['language'] as String : 'Code',
          item['stargazers_count'] is int
              ? item['stargazers_count'] as int
              : 0));
    }
    _cache = List.unmodifiable(repos.take(6));
    _loadedAt = DateTime.now();
    return _cache!;
  }

  void dispose() => _client.close();
}
