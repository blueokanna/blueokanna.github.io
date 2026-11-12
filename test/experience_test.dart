import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulselink_site/app.dart';
import 'package:pulselink_site/localization.dart';
import 'package:pulselink_site/preferences.dart';
import 'package:pulselink_site/publishing.dart';
import 'package:pulselink_site/ui/clock_scope.dart';
import 'package:pulselink_site/ui/mascot.dart';
import 'package:pulselink_site/ui/studio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late BlogCatalog catalog;
  setUpAll(() async => catalog = await BlogCatalog.load());
  test('all character poses are detailed transparent image assets', () async {
    for (final name in [
      'blue-fat-fish',
      'blue-fat-fish-wave',
      'blue-fat-fish-read',
    ]) {
      final data = await rootBundle.load('assets/mascot/$name.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      expect(frame.image.width, greaterThanOrEqualTo(1000));
      expect(frame.image.height, greaterThanOrEqualTo(1400));
      final rgba = (await frame.image.toByteData())!.buffer.asUint8List();
      expect(rgba[3], 0, reason: 'Outer background must be transparent');
      final center =
          ((frame.image.height ~/ 2) * frame.image.width +
              frame.image.width ~/ 2) *
          4;
      expect(rgba[center + 3], greaterThan(240));
      frame.image.dispose();
      codec.dispose();
    }
  });
  testWidgets(
    'companion supports touch actions and reduced motion on small screens',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              disableAnimations: true,
              textScaler: TextScaler.linear(1.4),
            ),
            child: Scaffold(
              body: MotionClock(
                clock: AlwaysStoppedAnimation(0),
                child: CompanionStage(language: 'zh-CN'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('我是蓝色大肥鱼。戳戳我？'), findsOneWidget);
      expect(find.byType(CompanionArtwork), findsOneWidget);
      expect(
        tester.widget<CompanionArtwork>(find.byType(CompanionArtwork)).asset,
        'assets/mascot/blue-fat-fish.png',
      );
      await tester.tap(find.text('打招呼'));
      await tester.pump();
      expect(find.text('收到！今天也一起探索吧。'), findsOneWidget);
      expect(
        tester.widget<CompanionArtwork>(find.byType(CompanionArtwork)).asset,
        'assets/mascot/blue-fat-fish-wave.png',
      );
      await tester.tap(find.text('陪我读'));
      await tester.pump();
      expect(find.text('安静模式。陪你读完这一篇。'), findsOneWidget);
      expect(
        tester.widget<CompanionArtwork>(find.byType(CompanionArtwork)).asset,
        'assets/mascot/blue-fat-fish-read.png',
      );
      await tester.pump(const Duration(seconds: 6));
      expect(find.text('安静模式。陪你读完这一篇。'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'studio restores Markdown draft and does not persist credentials',
    (tester) async {
      const draft = ArticleDraft(
        id: 'saved-post',
        language: 'zh-CN',
        title: '恢复标题',
        summary: '恢复摘要',
        category: '工程',
        body: '## 保存的正文\n\n内容',
      );
      SharedPreferences.setMockInitialValues({
        'pulselink.writing.draft.v1': jsonEncode({'draft': draft.toJson()}),
      });
      final publisher = Publisher();
      addTearDown(publisher.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WritingStudio(publisher: publisher, language: 'zh-CN'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('恢复标题'), findsOneWidget);
      final tokenField = find.byWidgetPredicate(
        (w) => w is TextField && w.obscureText,
      );
      await tester.enterText(tokenField, 'github_pat_never_store_this_token');
      await tester.pump(const Duration(seconds: 1));
      final storage = await SharedPreferences.getInstance();
      expect(
        storage.getString('pulselink.writing.draft.v1'),
        isNot(contains('github_pat_')),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('home and studio fit 320px with enlarged text', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final route in ['/zh-CN', '/zh-CN/studio']) {
      final preferences = BlogPreferences()..paused = true;
      await tester.pumpWidget(
        PulseLinkApp(
          catalog: catalog,
          preferences: preferences,
          initialLocation: route,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      preferences.dispose();
    }
  });
}
