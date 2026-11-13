import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pulselink_site/content.dart';
import 'package:pulselink_site/friends_service.dart';
import 'package:pulselink_site/publishing.dart';

const token = 'github_pat_test_only_not_a_real_credential';
http.Response owner() =>
    http.Response('{"login":"blueokanna","id":56761243}', 200);
http.Response repo() =>
    http.Response('{"owner":{"id":56761243},"permissions":{"push":true}}', 200);
void main() {
  http.Response snapshot(List<FriendLink> links, String sha) {
    final encoded = FriendLink.encode(links);
    return http.Response(
      jsonEncode({
        'sha': sha,
        'size': utf8.encode(encoded).length,
        'encoding': 'base64',
        'content': base64Encode(utf8.encode(encoded)),
      }),
      200,
    );
  }

  test('save wins over in-flight reads and stale public cache', () async {
    final pending = Completer<http.Response>();
    var requests = 0;
    final saved = [
      ...friends,
      const FriendLink(
        name: 'New',
        url: 'https://example.org',
        desc: '',
        descEn: '',
      ),
    ];
    final service = FriendsService(
      client: MockClient((_) async {
        requests++;
        if (requests == 1) return pending.future;
        if (requests == 2) return snapshot(friends, 'old');
        return snapshot(saved, 'saved');
      }),
    );
    addTearDown(service.dispose);
    final reading = service.load();
    service.acceptSaved(saved, 'saved');
    pending.complete(snapshot(friends, 'old'));
    expect(
      (await reading).map((link) => link.url),
      saved.map((link) => link.url),
    );
    expect(
      (await service.load()).map((link) => link.url),
      saved.map((link) => link.url),
    );
    expect(
      (await service.load()).map((link) => link.url),
      saved.map((link) => link.url),
    );
    expect(
      service.snapshot.map((link) => link.url),
      saved.map((link) => link.url),
    );
  });
  test('rate-limited public reads use CDN without credentials', () async {
    final service = FriendsService(
      client: MockClient((request) async {
        expect(request.headers.containsKey('Authorization'), isFalse);
        if (request.url.host == 'api.github.com') {
          return http.Response('{}', 403);
        }
        expect(request.url.host, 'raw.githubusercontent.com');
        return http.Response(
          FriendLink.encode(friends),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(service.dispose);
    expect(
      (await service.load()).map((link) => link.url),
      friends.map((link) => link.url),
    );
  });
  test('friend data rejects executable URLs, credentials and duplicates', () {
    for (final url in [
      'javascript:alert(1)',
      'http://example.org',
      'https://owner:secret@example.org',
    ]) {
      expect(
        () => FriendLink.encode([
          FriendLink(name: 'x', url: url, desc: '', descEn: ''),
        ]),
        throwsFormatException,
      );
    }
    expect(
      () => FriendLink.encode([friends.first, friends.first]),
      throwsFormatException,
    );
    expect(
      FriendLink.decode(FriendLink.encode(friends)).map((f) => f.url),
      friends.map((f) => f.url),
    );
    expect(
      () => FriendLink.decode('{"version":2,"links":[]}'),
      throwsFormatException,
    );
    expect(
      () => FriendLink.encode(List.filled(101, friends.first)),
      throwsFormatException,
    );
  });
  test(
    'same name with wrong numeric account ID never obtains write capability',
    () async {
      final publisher = Publisher(
        client: MockClient((request) async {
          expect(request.method, 'GET');
          return http.Response('{"login":"blueokanna","id":1}', 200);
        }),
      );
      addTearDown(publisher.dispose);
      await publisher.connect(token);
      expect(publisher.canPublish, isFalse);
      await expectLater(
        publisher.publishFriends(friends),
        throwsA(isA<PublishingException>()),
      );
    },
  );
  test(
    'every friend write verifies identity again and preserves SHA',
    () async {
      var identities = 0, writes = 0;
      final publisher = Publisher(
        client: MockClient((request) async {
          expect(request.url.host, 'api.github.com');
          if (request.url.path == '/user') {
            identities++;
            return owner();
          }
          if (request.method == 'GET') return repo();
          writes++;
          expect(
            request.url.path,
            '/repos/blueokanna/blueokanna.github.io/contents/content/friends.json',
          );
          final data = jsonDecode(request.body);
          expect(data['sha'], 'original');
          expect(data['branch'], 'main');
          expect(
            FriendLink.decode(utf8.decode(base64Decode(data['content'])))
                .map((link) => link.url),
            friends.map((link) => link.url),
          );
          return http.Response('{"content":{"sha":"new"}}', 200);
        }),
      );
      addTearDown(publisher.dispose);
      await publisher.connect(token);
      expect(await publisher.publishFriends(friends, sha: 'original'), 'new');
      expect(identities, 2);
      expect(writes, 1);
    },
  );
  test('logout during revalidation prevents the PUT', () async {
    final pending = Completer<http.Response>();
    var identities = 0;
    final publisher = Publisher(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        if (request.url.path == '/user') {
          return ++identities == 1 ? owner() : pending.future;
        }
        return repo();
      }),
    );
    addTearDown(publisher.dispose);
    await publisher.connect(token);
    final result = publisher.publishFriends(friends);
    publisher.disconnect();
    pending.complete(owner());
    await expectLater(result, throwsA(isA<PublishingException>()));
  });
  test('conflicts are surfaced without automatic overwrite or retry', () async {
    var writes = 0;
    final publisher = Publisher(
      client: MockClient((request) async {
        if (request.url.path == '/user') return owner();
        if (request.method == 'GET') return repo();
        writes++;
        return http.Response('{}', 409);
      }),
    );
    addTearDown(publisher.dispose);
    await publisher.connect(token);
    await expectLater(
      publisher.publishFriends(friends, sha: 'stale'),
      throwsA(isA<PublishingException>()),
    );
    expect(writes, 1);
  });
  test('public refresh uses ETags and never sends credentials', () async {
    var requests = 0;
    final service = FriendsService(
      client: MockClient((request) async {
        expect(request.headers.containsKey('Authorization'), isFalse);
        if (++requests == 2) {
          expect(request.headers['If-None-Match'], 'etag');
          return http.Response('', 304);
        }
        final encoded = FriendLink.encode(friends);
        return http.Response(
          jsonEncode({
            'size': utf8.encode(encoded).length,
            'encoding': 'base64',
            'content': base64Encode(utf8.encode(encoded)),
          }),
          200,
          headers: {'etag': 'etag'},
        );
      }),
    );
    addTearDown(service.dispose);
    expect(
      (await service.load()).map((link) => link.url),
      friends.map((link) => link.url),
    );
    expect(
      (await service.load()).map((link) => link.url),
      friends.map((link) => link.url),
    );
  });
}
