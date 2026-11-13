import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulselink_site/app.dart';
import 'package:pulselink_site/companion.dart';
import 'package:pulselink_site/localization.dart';
import 'package:pulselink_site/preferences.dart';
import 'package:pulselink_site/publishing.dart';
import 'package:pulselink_site/ui/clock_scope.dart';
import 'package:pulselink_site/ui/mascot.dart';
import 'package:pulselink_site/ui/companion_scene.dart';
import 'package:pulselink_site/ui/studio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late BlogCatalog catalog;
  setUpAll(() async => catalog = await BlogCatalog.load());
  testWidgets(
    'companion supports touch actions and reduced motion on small screens',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final now = DateTime.utc(2026, 11, 13, 6);
      final actor = CompanionController(now: () => now);
      addTearDown(actor.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              disableAnimations: true,
              textScaler: TextScaler.linear(1.4),
            ),
            child: Scaffold(
              body: MotionClock(
                clock: AlwaysStoppedAnimation(0),
                child: CompanionScope(
                  controller: actor,
                  child: const CompanionStage(language: 'zh-CN'),
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        find.text(CompanionRoutine.activity(now).message('zh-CN')),
        findsOneWidget,
      );
      expect(find.byType(CompanionScene), findsOneWidget);
      expect(
        tester.widget<CompanionScene>(find.byType(CompanionScene)).mood,
        CompanionRoutine.activity(now),
      );
      expect(find.byType(ActionChip), findsNothing);
      tester.widget<CompanionScene>(find.byType(CompanionScene)).onAction!(
        'pet',
      );
      await tester.pump();
      expect(
        tester.widget<CompanionScene>(find.byType(CompanionScene)).mood,
        CompanionMood.happy,
      );
      expect(find.text(CompanionMood.happy.message('zh-CN')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      actor.setForeground(false);
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
