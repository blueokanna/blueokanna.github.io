import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink_site/app.dart';
import 'package:pulselink_site/localization.dart';
import 'package:pulselink_site/preferences.dart';
import 'package:pulselink_site/services.dart';
import 'package:pulselink_site/ui/rich_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late BlogCatalog catalog;
  setUpAll(() async => catalog = await BlogCatalog.load());

  test('every curated project has translated analysis and source evidence', () {
    expect(catalog.projects.map((p) => p.id).toSet(), {
      'segmeris',
      'arcadiaplus',
      'recursex',
      'corduit',
      'courierust',
      'pulselink',
    });
    for (final project in catalog.projects) {
      expect(project.descriptions.keys.toSet(), languages.keys.toSet());
      expect(project.sections.keys.toSet(), languages.keys.toSet());
      expect(safeWebUri(project.repository), isNotNull);
      expect(project.sources.length, greaterThanOrEqualTo(2));
      for (final source in project.sources) {
        expect(safeWebUri(source.url), isNotNull);
      }
      for (final lang in languages.keys) {
        expect(project.descriptions[lang], isNotEmpty);
        expect(project.sections[lang]!.length, 3);
        for (final section in project.sections[lang]!) {
          expect(section.heading, isNotEmpty);
          expect(section.body.length, greaterThan(80));
        }
      }
    }
  });

  test('all referenced diagrams have source and both theme assets', () async {
    for (final strings in catalog.translations.values) {
      for (final post in strings.posts) {
        for (final source in post.sources) {
          expect(safeWebUri(source.url), isNotNull);
        }
        for (final section in post.sections) {
          if (section.diagram case final String id) {
            final path = 'assets/diagrams/$id-${strings.tag}';
            expect(
              await rootBundle.loadString('$path.mmd'),
              contains('flowchart'),
            );
            // Do not retain a Future created in this non-widget test's zone
            // for a later widget test running under FakeAsync.
            rootBundle.evict('$path.mmd');
            for (final mode in ['dark', 'light']) {
              final bytes = await rootBundle.load('$path-$mode.png');
              expect(bytes.lengthInBytes, greaterThan(1000));
              expect(bytes.buffer.asUint8List().take(8), [
                137,
                80,
                78,
                71,
                13,
                10,
                26,
                10,
              ]);
            }
          }
        }
      }
    }
  });

  for (final lang in languages.keys) {
    testWidgets(
      '$lang project collection and detail fit enlarged mobile text',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final preferences = BlogPreferences()..paused = true;
        addTearDown(preferences.dispose);
        await tester.pumpWidget(
          PulseLinkApp(
            catalog: catalog,
            preferences: preferences,
            initialLocation: '/$lang/projects',
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('ArcadiaPlus'));
        await tester.tap(find.text('ArcadiaPlus'));
        await tester.pumpAndSettle();
        expect(
          find.text(catalog.projects[1].sections[lang]!.first.heading),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('diagram opens a zoomable view and exposes its Mermaid source', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DiagramFigure(
              id: 'hls-assembly',
              language: 'en',
              caption: 'HLS',
              expandLabel: 'Expand diagram',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byIcon(Icons.fullscreen));
    await tester.tap(find.byIcon(Icons.fullscreen));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Mermaid'));
    await tester.tap(find.text('Mermaid'));
    await tester.pumpAndSettle();
    expect(find.textContaining('flowchart TD'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
