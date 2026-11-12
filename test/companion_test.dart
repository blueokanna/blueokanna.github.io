import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulselink_site/app.dart';
import 'package:pulselink_site/companion.dart';
import 'package:pulselink_site/localization.dart';
import 'package:pulselink_site/preferences.dart';
import 'package:pulselink_site/publishing.dart';
import 'package:pulselink_site/ui/clock_scope.dart';
import 'package:pulselink_site/ui/mascot.dart';
import 'package:pulselink_site/ui/pages.dart';
import 'package:pulselink_site/ui/studio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late BlogCatalog catalog;
  setUpAll(() async => catalog = await BlogCatalog.load());

  testWidgets('scenes restore after reactions and routes cancel old timers', (
    tester,
  ) async {
    final actor = CompanionController();
    addTearDown(actor.dispose);
    actor.setRoute('/zh-CN/posts/segmeris-guide');
    expect(actor.mood, CompanionMood.read);
    actor.select(CompanionMood.dance);
    await tester.pump(const Duration(seconds: 8));
    expect(actor.mood, CompanionMood.read);
    actor.react(CompanionMood.finished, priority: 2);
    actor.setRoute('/en/projects');
    expect(actor.mood, CompanionMood.explore);
    await tester.pump(const Duration(seconds: 8));
    expect(actor.mood, CompanionMood.explore);
    actor.setRoute('/zh-CN/studio');
    expect(actor.mood, CompanionMood.write);
  });

  testWidgets(
    'inactivity sleeps, activity wakes, manual rest stays until reset',
    (tester) async {
      final actor = CompanionController(idleAfter: const Duration(seconds: 10));
      addTearDown(actor.dispose);
      actor.setRoute('/zh-CN');
      await tester.pump(const Duration(seconds: 9));
      actor.activity();
      await tester.pump(const Duration(seconds: 9));
      expect(actor.mood, CompanionMood.idle);
      await tester.pump(const Duration(seconds: 2));
      expect(actor.mood, CompanionMood.sleep);
      actor.activity();
      expect(actor.mood, CompanionMood.idle);
      actor.select(CompanionMood.sleep);
      actor.activity();
      expect(actor.mood, CompanionMood.sleep);
      actor.reset();
      expect(actor.mood, CompanionMood.idle);
      actor.setRoute('/zh-CN/posts/example');
      await tester.pump(const Duration(minutes: 2));
      expect(actor.mood, CompanionMood.read);
    },
  );

  testWidgets(
    'busy work wins over gestures and old responses cannot overwrite it',
    (tester) async {
      final actor = CompanionController();
      addTearDown(actor.dispose);
      actor.setRoute('/zh-CN/studio');
      final old = actor.beginWork();
      final current = actor.beginWork();
      actor.select(CompanionMood.dance);
      actor.react(CompanionMood.saved);
      actor.react(CompanionMood.error, priority: 3);
      actor.reset();
      actor.completeWork(old, CompanionMood.error);
      expect(actor.mood, CompanionMood.loading);
      actor.completeWork(current, CompanionMood.celebrate);
      expect(actor.mood, CompanionMood.celebrate);
      actor.completeWork(current, CompanionMood.error);
      expect(
        actor.mood,
        CompanionMood.celebrate,
        reason: 'A request can complete only once',
      );
      await tester.pump(const Duration(seconds: 6));
      expect(actor.mood, CompanionMood.write);
      final leaving = actor.beginWork();
      actor.setRoute('/en/projects');
      actor.completeWork(leaving, CompanionMood.error);
      expect(actor.mood, CompanionMood.explore);
    },
  );

  testWidgets(
    'background completion and terminal reactions release busy state',
    (tester) async {
      final actor = CompanionController();
      addTearDown(actor.dispose);
      actor.setRoute('/zh-CN/studio');
      final pending = actor.beginWork();
      actor.setForeground(false);
      await tester.pump(const Duration(minutes: 1));
      actor.setForeground(true);
      expect(actor.mood, CompanionMood.loading);
      actor.completeWork(pending, CompanionMood.error);
      actor.setForeground(false);
      actor.setForeground(true);
      expect(
        actor.mood,
        CompanionMood.write,
        reason: 'Error is not a permanent busy lock',
      );
      final hidden = actor.beginWork();
      actor.setForeground(false);
      actor.completeWork(hidden, CompanionMood.celebrate);
      actor.setForeground(true);
      actor.select(CompanionMood.happy);
      expect(actor.mood, CompanionMood.happy);
      actor.setForeground(false);
    },
  );

  testWidgets('disposed controllers ignore delayed work without notifying', (
    tester,
  ) async {
    final actor = CompanionController();
    final ticket = actor.beginWork();
    actor.dispose();
    actor.completeWork(ticket, CompanionMood.error);
    actor.activity();
    actor.setRoute('/en/projects');
    await tester.pump(const Duration(minutes: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'all expressions are reachable on a narrow screen with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final actor = CompanionController();
      addTearDown(actor.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              disableAnimations: true,
              textScaler: TextScaler.linear(1.4),
            ),
            child: Scaffold(
              body: CompanionScope(
                controller: actor,
                child: const SingleChildScrollView(
                  child: MotionClock(
                    clock: AlwaysStoppedAnimation(0),
                    child: CompanionStage(language: 'zh-CN'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.ensureVisible(find.text('更多表情 · 12'));
      await tester.tap(find.text('更多表情 · 12'));
      await tester.pump();
      expect(find.byType(ActionChip), findsNWidgets(12));
      for (final mood in CompanionMood.actions) {
        final chip = find.widgetWithText(ActionChip, mood.label('zh-CN'));
        await tester.ensureVisible(chip);
        await tester.tap(chip);
        await tester.pump();
        expect(actor.mood, mood);
        expect(
          tester.widget<CompanionArtwork>(find.byType(CompanionArtwork)).asset,
          mood.asset,
        );
        expect(tester.takeException(), isNull);
      }
      await tester.ensureVisible(find.text('跟随页面'));
      await tester.tap(find.text('跟随页面'));
      await tester.pump();
      expect(actor.mood, CompanionMood.idle);
      await tester.pumpWidget(const SizedBox());
      actor.setForeground(false);
    },
  );

  testWidgets(
    'search, empty results, reading and completion reach the shared dock',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
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
      final context = tester.element(find.byType(BlogPage));
      final actor = CompanionScope.read(context)!;
      final router = GoRouter.of(context);
      final search = find.descendant(
        of: find.byType(SearchBar),
        matching: find.byType(TextField),
      );
      await tester.enterText(search, 'no-such-article-94829');
      await tester.pump();
      expect(actor.mood, CompanionMood.empty);
      await tester.enterText(search, 'Segmeris');
      await tester.pump();
      expect(actor.mood, CompanionMood.search);
      await tester.enterText(search, '');
      await tester.pump();
      expect(actor.mood, CompanionMood.think);
      router.go('/zh-CN/posts/segmeris-guide');
      await tester.pumpAndSettle();
      expect(actor.mood, CompanionMood.read);
      expect(
        tester.getRect(find.byType(CompanionDock)).top,
        greaterThanOrEqualTo(tester.getRect(find.byType(BlogPage)).bottom),
        reason:
            'Mobile companion reserves space instead of covering the article',
      );
      final scroll = tester
          .widget<SingleChildScrollView>(
            find
                .descendant(
                  of: find.byType(BlogPage),
                  matching: find.byType(SingleChildScrollView),
                )
                .first,
          )
          .controller!;
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pump();
      expect(actor.mood, CompanionMood.finished);
      expect(
        find.descendant(
          of: find.byType(CompanionDock),
          matching: find.text('读到末尾'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byType(CompanionDock));
      await tester.pumpAndSettle();
      expect(find.byType(CompanionStage), findsOneWidget);
      expect(
        find.text(CompanionMood.finished.message('zh-CN')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('editing and successful local save produce truthful states', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final actor = CompanionController()..setRoute('/zh-CN/studio');
    final publisher = Publisher();
    addTearDown(actor.dispose);
    addTearDown(publisher.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanionScope(
            controller: actor,
            child: WritingStudio(publisher: publisher, language: 'zh-CN'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final field = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == '文章 ID（URL）',
    );
    await tester.ensureVisible(field);
    await tester.enterText(field, 'writing-a-real-draft');
    await tester.pump();
    expect(actor.mood, CompanionMood.write);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    expect(actor.mood, CompanionMood.saved);
    final storage = await SharedPreferences.getInstance();
    expect(
      storage.getString('pulselink.writing.draft.v1'),
      contains('writing-a-real-draft'),
    );
    await tester.pumpWidget(const SizedBox());
    actor.setForeground(false);
  });
}
