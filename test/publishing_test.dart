import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pulselink_site/publishing.dart';

const token = 'github_pat_test_only_not_a_real_credential';
const draft = ArticleDraft(
  id: 'test-post',
  language: 'zh-CN',
  title: '中文标题',
  summary: '摘要',
  category: '工程',
  body: '## 测试\n\n```dart\nprint("你好");\n```',
);

void main() {
  test('Markdown round trip preserves UTF-8, fences and metadata', () {
    expect(ArticleDraft.decode(draft.encode()).toJson(), draft.toJson());
    expect(
      () => ArticleDraft.decode('---\n!!js/function x\n---\ntext'),
      throwsA(anything),
    );
    expect(
      () =>
          ArticleDraft.fromJson({...draft.toJson(), 'id': '../escape'})
              .encode(),
      throwsA(isA<PublishingException>()),
    );
  });
  test('anonymous and non-owner sessions never issue writes', () async {
    var requests = 0;
    final publisher = Publisher(
      client: MockClient((request) async {
        requests++;
        expect(request.method, 'GET');
        return http.Response(jsonEncode({'login': 'reader', 'id': 2}), 200);
      }),
    );
    addTearDown(publisher.dispose);
    await expectLater(
      publisher.publish(draft),
      throwsA(isA<PublishingException>()),
    );
    expect(requests, 0);
    await publisher.connect(token);
    expect(publisher.login, 'reader');
    expect(publisher.canPublish, false);
    await expectLater(
      publisher.publish(draft),
      throwsA(isA<PublishingException>()),
    );
    expect(requests, 1);
  });
  test('owner ID and repository push permission must both match', () async {
    for (final repo in [
      {
        'owner': {'id': 3},
        'permissions': {'push': true},
      },
      {
        'owner': {'id': Publisher.ownerId},
        'permissions': {'push': false},
      },
    ]) {
      final publisher = Publisher(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode(
              request.url.path == '/user'
                  ? {'login': 'blueokanna', 'id': Publisher.ownerId}
                  : repo,
            ),
            200,
          ),
        ),
      );
      await publisher.connect(token);
      expect(publisher.canPublish, false);
      publisher.dispose();
    }
  });
  test(
    'publication pins branch, retains SHA, and never retries conflict',
    () async {
      var writes = 0;
      final publisher = Publisher(
        client: MockClient((request) async {
          expect(request.url.host, 'api.github.com');
          expect(request.headers['Authorization'], 'Bearer $token');
          if (request.url.path == '/user') {
            return http.Response('{"login":"blueokanna","id":56761243}', 200);
          }
          if (request.url.path == '/repos/${Publisher.repository}') {
            return http.Response(
              '{"owner":{"id":56761243},"permissions":{"push":true}}',
              200,
            );
          }
          if (request.method == 'GET') {
            expect(request.url.queryParameters['ref'], 'main');
            return http.Response(
              jsonEncode({
                'sha': 'base-sha',
                'content': base64Encode(utf8.encode(draft.encode())),
              }),
              200,
            );
          }
          writes++;
          final body = jsonDecode(request.body);
          expect(body['sha'], 'base-sha');
          expect(body['branch'], 'main');
          expect(utf8.decode(base64Decode(body['content'])), draft.encode());
          return http.Response('{}', 409);
        }),
      );
      addTearDown(publisher.dispose);
      await publisher.connect(token);
      final remote = await publisher.read('zh-CN', 'test-post');
      await expectLater(
        publisher.publish(remote.draft, sha: remote.sha),
        throwsA(isA<PublishingException>()),
      );
      expect(writes, 1);
      publisher.disconnect();
      expect(publisher.login, isNull);
      await expectLater(
        publisher.publish(draft),
        throwsA(isA<PublishingException>()),
      );
    },
  );
  test('logout invalidates a late identity response', () async {
    final response = Completer<http.Response>();
    final publisher = Publisher(client: MockClient((_) => response.future));
    addTearDown(publisher.dispose);
    final pending = publisher.connect(token);
    publisher.disconnect();
    response.complete(http.Response('{"login":"reader","id":2}', 200));
    await pending;
    expect(publisher.login, isNull);
  });
  test('creating a post returns GitHub SHA and never invents an update base', () async {
    final publisher = Publisher(
      client: MockClient((request) async {
        if (request.url.path == '/user') {
          return http.Response('{"login":"blueokanna","id":56761243}', 200);
        }
        if (request.method == 'GET') {
          return http.Response(
            '{"owner":{"id":56761243},"permissions":{"push":true}}',
            200,
          );
        }
        expect(
          request.url.path,
          '/repos/${Publisher.repository}/contents/content/posts/zh-CN/test-post.md',
        );
        final body = jsonDecode(request.body) as Map;
        expect(body.containsKey('sha'), false);
        expect(body['branch'], 'main');
        expect(
          ArticleDraft.decode(utf8.decode(base64Decode(body['content'])))
              .toJson(),
          draft.toJson(),
        );
        return http.Response('{"content":{"sha":"created-sha"}}', 201);
      }),
    );
    addTearDown(publisher.dispose);
    await publisher.connect(token);
    expect(await publisher.publish(draft), 'created-sha');
  });
}
