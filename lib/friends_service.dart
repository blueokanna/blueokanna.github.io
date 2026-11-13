import 'dart:convert';

import 'package:http/http.dart' as http;

import 'content.dart';

/// Public reads are credential-free and do not wait for a Pages rebuild.
class FriendsService {
  FriendsService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  String? _etag;
  List<FriendLink>? _cache;
  Future<List<FriendLink>> load() async {
    final response = await _client
        .get(
          Uri.https(
            'api.github.com',
            '/repos/blueokanna/blueokanna.github.io/contents/content/friends.json',
            {'ref': 'main'},
          ),
          headers: {
            'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28',
            if (_etag != null) 'If-None-Match': _etag!,
          },
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode == 304 && _cache != null) return _cache!;
    if (response.statusCode == 404) return friends;
    if (response.statusCode != 200) {
      throw StateError('GitHub HTTP ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['size'] is! int ||
        json['size'] > 262144 ||
        json['encoding'] != 'base64') {
      throw const FormatException('Invalid blogroll response');
    }
    final links = FriendLink.decode(
      utf8.decode(
        base64Decode((json['content'] as String).replaceAll(RegExp(r'\s'), '')),
      ),
    );
    _etag = response.headers['etag'];
    return _cache = links;
  }

  void dispose() => _client.close();
}
