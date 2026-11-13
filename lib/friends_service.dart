import 'dart:convert';

import 'package:http/http.dart' as http;

import 'content.dart';

/// Public reads are credential-free and do not wait for a Pages rebuild.
class FriendsService {
  FriendsService({http.Client? client, List<FriendLink> initial = friends})
    : _client = client ?? http.Client(),
      _initial = List.unmodifiable(initial);
  final http.Client _client;
  final List<FriendLink> _initial;
  String? _etag;
  List<FriendLink>? _cache;
  String? _savedSha;
  DateTime? _protectUntil;
  int _revision = 0;
  List<FriendLink> get snapshot => _cache ?? _initial;

  /// Preserve an acknowledged write while public GitHub caches catch up.
  void acceptSaved(List<FriendLink> links, String sha) {
    _cache = List.unmodifiable(links);
    _savedSha = sha;
    _protectUntil = DateTime.now().add(const Duration(minutes: 2));
    _etag = null;
    _revision++;
  }

  Future<List<FriendLink>> load() async {
    final revision = _revision;
    try {
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
          base64Decode(
            (json['content'] as String).replaceAll(RegExp(r'\s'), ''),
          ),
        ),
      );
      if (revision != _revision) return snapshot;
      if (_savedSha != null &&
          json['sha'] != _savedSha &&
          DateTime.now().isBefore(_protectUntil!)) {
        return snapshot;
      }
      _savedSha = null;
      _etag = response.headers['etag'];
      return _cache = links;
    } catch (_) {
      if (revision != _revision) return snapshot;
      // Never replace a newer in-session snapshot with an older CDN fallback.
      if (_cache != null) rethrow;
      for (final uri in [
        Uri.https(
          'raw.githubusercontent.com',
          '/blueokanna/blueokanna.github.io/main/content/friends.json',
        ),
        if (Uri.base.scheme == 'https' || Uri.base.scheme == 'http')
          Uri.base.resolve('/friends.json'),
      ]) {
        try {
          final fallback = await _client
              .get(uri)
              .timeout(const Duration(seconds: 5));
          if (fallback.statusCode != 200 ||
              fallback.bodyBytes.length > 262144) {
            continue;
          }
          final links = FriendLink.decode(utf8.decode(fallback.bodyBytes));
          if (revision != _revision) return snapshot;
          return _cache = links;
        } catch (_) {
          /* Try the deployed snapshot if the public CDN is unavailable. */
        }
      }
      rethrow;
    }
  }

  void dispose() => _client.close();
}
