import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pulselink_site/app.dart';
import 'package:pulselink_site/localization.dart';
import 'package:pulselink_site/motion.dart';
import 'package:pulselink_site/preferences.dart';
import 'package:pulselink_site/ui/pages.dart';

// Inspect intermediate paint opacities, not only the final settled layout.
// Transparent route content must never expose two readable pages at once.
double paintOpacity(Element element) {
  var opacity = 1.0;
  element.visitAncestorElements((ancestor) {
    switch (ancestor.widget) {
      case FadeTransition(opacity: final animation):
        opacity *= animation.value;
      case Opacity(opacity: final value):
        opacity *= value;
      case Offstage(offstage: true):
        opacity = 0;
      default:
        break;
    }
    return true;
  });
  return opacity;
}

void expectSinglePaintedPage(WidgetTester tester) {
  final visible = find
      .byType(BlogPage)
      .evaluate()
      .where((element) => paintOpacity(element) > 1 / 255);
  expect(
    visible.length,
    lessThanOrEqualTo(1),
    reason:
        'Old and new page text must not be painted in the same frame: '
        '${visible.map((element) => (element.widget as BlogPage).page)}',
  );
  expect(tester.takeException(), isNull);
}

Future<void> pumpTransition(WidgetTester tester) async {
  await tester.pump();
  expectSinglePaintedPage(tester);
  for (var frame = 0; frame < 40; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    expectSinglePaintedPage(tester);
  }
}

void expectCurrentPage(String path, {String language = 'en', String? slug}) {
  final page = find.byType(BlogPage).evaluate().single;
  final widget = page.widget as BlogPage;
  expect(widget.page, path);
  expect(widget.strings.tag, language);
  expect(widget.slug, slug);
  expect(paintOpacity(page), 1);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late BlogCatalog catalog;
  setUpAll(() async => catalog = await BlogCatalog.load());

  Future<GoRouter> mount(
    WidgetTester tester, {
    double width = 1440,
    ThemeMode mode = ThemeMode.dark,
    bool paused = false,
  }) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final preferences = BlogPreferences()
      ..mode = mode
      ..paused = paused;
    addTearDown(preferences.dispose);
    await tester.pumpWidget(
      PulseLinkApp(
        catalog: catalog,
        preferences: preferences,
        initialLocation: '/en',
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expectSinglePaintedPage(tester);
    return GoRouter.of(tester.element(find.byType(BlogPage)));
  }

  for (final width in [320.0, 768.0, 1440.0]) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'navigation has no double exposure at $width / ${mode.name}',
        (tester) async {
          final router = await mount(tester, width: width, mode: mode);
          await tester.tap(
            find.widgetWithText(
              TextButton,
              catalog.translations['en']!.text('posts'),
            ),
          );
          await pumpTransition(tester);
          expect(router.routeInformationProvider.value.uri.path, '/en/posts');
          expect(find.text('JOURNAL'), findsOneWidget);

          router.go('/en');
          await pumpTransition(tester);
          expect(
            find.text(catalog.translations['en']!.text('heroTitle')),
            findsOneWidget,
          );
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }

  for (final interval in [32, 144, 288]) {
    testWidgets('rapid navigation interrupted every $interval ms stays clean', (
      tester,
    ) async {
      final router = await mount(tester);
      for (final path in [
        '/en/posts',
        '/en/about',
        '/en',
        '/en/posts',
        '/en/posts/segmeris-guide',
        '/en/posts/download-remux-encode',
        '/ja/posts/download-remux-encode',
        '/zh-CN/posts',
      ]) {
        router.go(path);
        await tester.pump();
        expectSinglePaintedPage(tester);
        for (var time = 0; time < interval; time += 16) {
          await tester.pump(const Duration(milliseconds: 16));
          expectSinglePaintedPage(tester);
        }
      }
      await pumpTransition(tester);
      expectCurrentPage('/posts', language: 'zh-CN');
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final delay in [32, 144, 288, 400]) {
    testWidgets('push followed by pop after $delay ms stays clean', (
      tester,
    ) async {
      final router = await mount(tester);
      final pushed = router.push<void>('/en/posts');
      await tester.pump();
      for (var time = 0; time < delay; time += 16) {
        await tester.pump(const Duration(milliseconds: 16));
        expectSinglePaintedPage(tester);
      }
      expect(router.canPop(), isTrue);
      router.pop();
      await pumpTransition(tester);
      await pushed;
      expectCurrentPage('');
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('browser history and language changes animate without overlap', (
    tester,
  ) async {
    final router = await mount(tester);
    router.go('/en/posts/segmeris-guide');
    await pumpTransition(tester);
    for (final location in [
      '/en',
      '/en/posts/segmeris-guide',
      '/de/posts/segmeris-guide',
      '/de/posts/download-remux-encode',
    ]) {
      // This is the same platform route-information callback used by web
      // history updates; it does not simulate a Navigator.push/pop stack.
      await router.routeInformationProvider.didPushRouteInformation(
        RouteInformation(uri: Uri.parse(location)),
      );
      await pumpTransition(tester);
      expect(router.routeInformationProvider.value.uri.path, location);
    }
    expectCurrentPage(
      '/posts/:slug',
      language: 'de',
      slug: 'download-remux-encode',
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('invisible incoming content cannot receive clicks', (
    tester,
  ) async {
    final router = await mount(tester);
    router.go('/en/posts');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 64));
    final title = find
        .text(
          catalog.translations['en']!.posts
              .firstWhere((p) => p.id == 'segmeris-guide')
              .title,
        )
        .last;
    await tester.tap(title, warnIfMissed: false);
    await tester.pump();
    expect(router.routeInformationProvider.value.uri.path, '/en/posts');
    await pumpTransition(tester);
    await tester.tap(title);
    await pumpTransition(tester);
    expectCurrentPage('/posts/:slug', slug: 'segmeris-guide');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('navigation retains a gradual entrance and settles on time', (
    tester,
  ) async {
    final router = await mount(tester);
    router.go('/en/posts');
    await tester.pump();
    await tester.pump(Motion.pageDuration * .6);
    expectSinglePaintedPage(tester);
    final incoming = find
        .byType(BlogPage)
        .evaluate()
        .where((element) => (element.widget as BlogPage).page == '/posts')
        .single;
    expect(paintOpacity(incoming), greaterThan(0));
    expect(paintOpacity(incoming), lessThan(1));
    await tester.pump(Motion.pageDuration * .4);
    // Allow the completion notification to reach the next display frame.
    await tester.pump(const Duration(milliseconds: 16));
    expectCurrentPage('/posts');
    await tester.pumpWidget(const SizedBox());
  });

  for (final system in [false, true]) {
    testWidgets('reduced motion is immediate (system: $system)', (
      tester,
    ) async {
      if (system) {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
      }
      final router = await mount(tester, paused: !system);
      for (final location in ['/en/posts', '/en', '/en/about']) {
        router.go(location);
        await tester.pump();
        await tester.pump();
        expectSinglePaintedPage(tester);
        expectCurrentPage(location.substring('/en'.length));
        final route = ModalRoute.of(tester.element(find.byType(BlogPage)))!;
        expect(route.animation!.isCompleted, isTrue);
        expect(route.secondaryAnimation!.isDismissed, isTrue);
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
