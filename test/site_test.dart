import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pulselink_site/app.dart';
import 'package:pulselink_site/content.dart';
import 'package:pulselink_site/localization.dart';
import 'package:pulselink_site/preferences.dart';
import 'package:pulselink_site/motion.dart';
import 'package:pulselink_site/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late BlogCatalog catalog;
  setUpAll(() async {
    catalog = await BlogCatalog.load();
  });

  test(
    'all ten languages have complete article and interface translations',
    () {
      final source = catalog.translations['en']!;
      expect(catalog.translations.keys.toSet(), languages.keys.toSet());
      for (final translation in catalog.translations.values) {
        expect(translation.data.keys.toSet(), source.data.keys.toSet());
        expect(
          translation.posts.map((p) => p.id),
          source.posts.map((p) => p.id),
        );
        for (final post in translation.posts) {
          expect(post.title, isNotEmpty);
          expect(post.sections.length, 4);
          for (final section in post.sections) {
            expect(section.heading, isNotEmpty);
            expect(section.body.length, greaterThan(100));
          }
        }
      }
    },
  );

  for (final language in languages.keys) {
    testWidgets('$language deep links support enlarged mobile text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final preferences = BlogPreferences()..paused = true;
      addTearDown(preferences.dispose);
      await tester.pumpWidget(
        PulseLinkApp(
          catalog: catalog,
          preferences: preferences,
          initialLocation: '/$language/posts/segmeris-guide',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(catalog.translations[language]!.posts.first.title),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  test('only safe HTTPS destinations are accepted', () {
    for (final url in [
      'javascript:alert(1)',
      'http://example.com',
      'https://user:password@example.com',
      '//example.com',
      'not a url',
    ]) {
      expect(safeWebUri(url), isNull);
    }
    for (final friend in friends) {
      expect(safeWebUri(friend.url), isNotNull);
    }
    expect(friends.first.url, 'https://lxns.org/');
    expect(friends[1].avatar, 'https://taoran.weppp.cyou/favicon.svg');
  });
  test(
    'repository data is validated and cached; refresh fetches again',
    () async {
      var requests = 0;
      final service = RepositoryService(
        client: MockClient((request) async {
          requests++;
          return http.Response(
            jsonEncode([
              {
                'name': 'real',
                'html_url': 'https://github.com/blueokanna/real',
                'stargazers_count': 7,
              },
              {'name': 'unsafe', 'html_url': 'javascript:alert(1)'},
              {
                'name': 'fork',
                'html_url': 'https://github.com/x/fork',
                'fork': true,
              },
            ]),
            200,
          );
        }),
      );
      addTearDown(service.dispose);
      final result = await service.load();
      expect(result.single.name, 'real');
      expect(result.single.stars, 7);
      await service.load();
      expect(requests, 1);
      await service.load(refresh: true);
      expect(requests, 2);
    },
  );
  test('network and malformed responses never manufacture content', () async {
    for (final response in [
      http.Response('rate limited', 403),
      http.Response('{}', 200),
    ]) {
      final service = RepositoryService(
        client: MockClient((_) async => response),
      );
      await expectLater(
        service.load(),
        throwsA(anyOf(isA<StateError>(), isA<FormatException>())),
      );
      service.dispose();
    }
  });
  for (final width in [320.0, 768.0, 1440.0]) {
    testWidgets('article navigation and reading at $width', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final preferences = BlogPreferences()..paused = true;
      addTearDown(preferences.dispose);
      await tester.pumpWidget(
        PulseLinkApp(
          catalog: catalog,
          preferences: preferences,
          initialLocation: '/zh-CN/posts',
        ),
      );
      await tester.pumpAndSettle();
      final title = catalog.translations['zh-CN']!.posts.first.title;
      await tester.ensureVisible(find.text(title));
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      expect(
        find.text(catalog.translations['zh-CN']!.text('contents')),
        findsOneWidget,
      );
      expect(find.text(title), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('reduced motion stops the shared clock', (tester) async {
    Animation<double>? clock;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Aurora(
            paused: false,
            builder: (context, animation) {
              clock = animation;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    final before = clock!.value;
    await tester.pump(const Duration(seconds: 2));
    expect(clock!.value, before);
    expect(tester.binding.transientCallbackCount, 0);
  });

  test('aurora artwork has no jump at the animation loop boundary', () async {
    Future<List<int>> render(double phase) async {
      final recorder = ui.PictureRecorder();
      AuroraArt(
        AlwaysStoppedAnimation(phase),
        dark: false,
        hero: true,
      ).paint(Canvas(recorder), const Size(320, 320));
      final picture = recorder.endRecording();
      final image = await picture.toImage(320, 320);
      try {
        final pixels = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        return pixels!.buffer.asUint8List().toList();
      } finally {
        image.dispose();
        picture.dispose();
      }
    }

    expect(await render(1), await render(0));
  });

  testWidgets('manual pause and background lifecycle stop and resume motion', (
    tester,
  ) async {
    Animation<double>? clock;
    Widget host(bool paused) => MaterialApp(
      home: Aurora(
        paused: paused,
        builder: (context, animation) {
          clock = animation;
          return const SizedBox();
        },
      ),
    );
    await tester.pumpWidget(host(false));
    await tester.pump(const Duration(seconds: 1));
    final running = clock!.value;
    expect(running, greaterThan(0));
    await tester.pumpWidget(host(true));
    await tester.pump(const Duration(seconds: 1));
    expect(clock!.value, running);
    await tester.pumpWidget(host(false));
    await tester.pump(const Duration(seconds: 1));
    expect(clock!.value, greaterThan(running));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    final background = clock!.value;
    await tester.pump(const Duration(seconds: 1));
    expect(clock!.value, background);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(clock!.value, greaterThan(background));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('clipboard rejection is handled on an article route', (
    tester,
  ) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        throw PlatformException(code: 'NotAllowedError');
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    final preferences = BlogPreferences()..paused = true;
    addTearDown(preferences.dispose);
    await tester.pumpWidget(
      PulseLinkApp(
        catalog: catalog,
        preferences: preferences,
        initialLocation: '/en/posts/segmeris-guide',
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Copy link'));
    await tester.tap(find.text('Copy link'));
    await tester.pump();
    expect(
      find.text(catalog.translations['en']!.text('copyFailed')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
