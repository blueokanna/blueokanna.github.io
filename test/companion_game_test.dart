import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink_site/companion.dart';
import 'package:pulselink_site/ui/companion_play.dart';

void main() {
  testWidgets('memory game checks the shown sequence and can restart', (
    tester,
  ) async {
    final actor = CompanionController(now: () => DateTime.utc(2026, 11, 13, 6));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanionPlay(actor: actor, language: 'zh-CN'),
        ),
      ),
    );
    await tester.tap(find.text('开始'));
    await tester.pump(const Duration(milliseconds: 500));
    final lit = tester.widget<Text>(find.textContaining(' ●')).data!;
    final choice = int.parse(lit.split(' ').first);
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('$choice'));
    await tester.pump();
    expect(find.textContaining('第 2 轮'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    final next = int.parse(
      tester.widget<Text>(find.textContaining(' ●')).data!.split(' ').first,
    );
    for (var i = 0; i < 2; i++) {
      await tester.pump(const Duration(milliseconds: 550));
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.tap(find.text('${next % 4 + 1}'));
    await tester.pump();
    expect(find.textContaining('这次记住了 1 步'), findsOneWidget);
    await tester.tap(find.text('重新开始'));
    await tester.pump();
    expect(find.textContaining('第 1 轮'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    actor.dispose();
    expect(tester.takeException(), isNull);
  });
}
