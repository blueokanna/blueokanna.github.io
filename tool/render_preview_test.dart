// Optional native Flutter layout capture; not a browser or performance benchmark.
// Run: flutter test tool/render_preview_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink_site/app.dart';
import 'package:pulselink_site/localization.dart';
import 'package:pulselink_site/preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/qa/${sample.$1}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox());
    });
  }
}
