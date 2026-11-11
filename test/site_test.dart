import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pulselink_site/app.dart';
import 'package:pulselink_site/content.dart';
import 'package:pulselink_site/motion.dart';
import 'package:pulselink_site/services.dart';

void main() {
  test('only safe HTTPS destinations are accepted', () {
    for (final url in [
      'javascript:alert(1)',
      'http://example.com',
      'https://user:password@example.com',
      '//example.com',
      'not a url'
    ]) {
      expect(safeWebUri(url), isNull);
    }
    for (final friend in friends) {
      expect(safeWebUri(friend.url), isNotNull);
    }
    expect(friends.first.url, 'https://lxns.org/');
    expect(friends[1].avatar, 'https://taoran.weppp.cyou/favicon.svg');
  });
  test('repository data is validated and cached; refresh fetches again',
      () async {
    var requests = 0;
    final service = RepositoryService(client: MockClient((request) async {
      requests++;
      return http.Response(
          jsonEncode([
            {
              'name': 'real',
              'html_url': 'https://github.com/blueokanna/real',
              'stargazers_count': 7
            },
            {'name': 'unsafe', 'html_url': 'javascript:alert(1)'},
            {
              'name': 'fork',
              'html_url': 'https://github.com/x/fork',
              'fork': true
            },
          ]),
          200);
    }));
    addTearDown(service.dispose);
    final result = await service.load();
    expect(result.single.name, 'real');
    expect(result.single.stars, 7);
    await service.load();
    expect(requests, 1);
    await service.load(refresh: true);
    expect(requests, 2);
  });
  test('network and malformed responses never manufacture content', () async {
    for (final response in [
      http.Response('rate limited', 403),
      http.Response('{}', 200)
    ]) {
      final service =
          RepositoryService(client: MockClient((_) async => response));
      await expectLater(service.load(),
          throwsA(anyOf(isA<StateError>(), isA<FormatException>())));
      service.dispose();
    }
  });
  for (final width in [360.0, 768.0, 1440.0]) {
    testWidgets('responsive navigation, reader and language at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const PulseLinkApp());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('代码有逻辑，'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('暂停动效'));
      await tester.pump();
      await tester.tap(find.text('走进笔记'));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text(journal.first.title));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Dialog), findsOneWidget);
      await tester.tap(find.byTooltip('关闭'));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byTooltip('Switch to English'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Built with logic.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 13));
    });
  }
  testWidgets('reduced motion stops the shared clock', (tester) async {
    Animation<double>? clock;
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Aurora(
          paused: false,
          builder: (context, animation) {
            clock = animation;
            return const SizedBox();
          }),
    )));
    final before = clock!.value;
    await tester.pump(const Duration(seconds: 2));
    expect(clock!.value, before);
    expect(tester.binding.transientCallbackCount, 0);
  });
}
