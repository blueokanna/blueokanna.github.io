// Optional native Flutter layout capture; not a browser or performance benchmark.
// Run: flutter test tool/render_preview_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pulselink_site/app.dart';
import 'package:pulselink_site/localization.dart';
import 'package:pulselink_site/preferences.dart';
import 'package:pulselink_site/ui/pages.dart';

class _PreviewBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get disableShadows => false;
}

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/qa/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  _PreviewBinding();
  late BlogCatalog catalog;
  setUpAll(() async {
    catalog = await BlogCatalog.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    for (final entry in {
      'Google Sans': 'googlesans',
      'Noto Sans SC': 'notosanssc',
      'Noto Sans TC': 'notosanstc',
      'Noto Sans JP': 'notosansjp',
    }.entries) {
      final loader = FontLoader(entry.key)
        ..addFont(rootBundle.load('assets/fonts/${entry.value}.ttf'));
      await loader.load();
    }
  });
  for (final sample in [
    ('desktop', 1440.0, '/zh-CN'),
    ('mobile', 390.0, '/zh-CN/posts/segmeris-guide'),
    ('projects-desktop', 1440.0, '/zh-CN/projects'),
    ('projects-mobile', 390.0, '/zh-CN/projects'),
    ('project-detail', 1440.0, '/zh-CN/projects/courierust'),
  ]) {
    testWidgets('capture ${sample.$1}', (tester) async {
      tester.view.physicalSize = Size(sample.$2, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final preferences = BlogPreferences()
        ..paused = true
        ..mode = ThemeMode.light;
      addTearDown(preferences.dispose);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: PulseLinkApp(
            catalog: catalog,
            preferences: preferences,
            initialLocation: sample.$3,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture(tester, key, sample.$1);
      await tester.pumpWidget(const SizedBox());
    });
  }
  for (final sample in [
    ('desktop-dark', 1440.0, ThemeMode.dark),
    ('mobile-light', 390.0, ThemeMode.light),
  ]) {
    testWidgets('capture ${sample.$1} transition frames', (tester) async {
      tester.view.physicalSize = Size(sample.$2, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final preferences = BlogPreferences()..mode = sample.$3;
      addTearDown(preferences.dispose);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: PulseLinkApp(
            catalog: catalog,
            preferences: preferences,
            initialLocation: '/zh-CN',
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      final router = GoRouter.of(tester.element(find.byType(BlogPage)));
      for (final destination in [
        ('posts', '/zh-CN/posts'),
        ('home', '/zh-CN'),
      ]) {
        router.go(destination.$2);
        await tester.pump();
        var elapsed = 0;
        for (final time in [64, 192, 336]) {
          await tester.pump(Duration(milliseconds: time - elapsed));
          elapsed = time;
          expect(tester.takeException(), isNull);
          await capture(tester, key, '${sample.$1}-${destination.$1}-$time');
        }
        await tester.pump();
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
