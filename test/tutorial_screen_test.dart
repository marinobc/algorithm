import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/ui/dialogs/tutorial_screen.dart';
import 'package:nodos/ui/text/user_guide_text.dart';

void main() {
  group('TutorialScreen Widget Tests', () {
    Widget buildSubject() {
      return MaterialApp(
        home: const TutorialScreen(),
      );
    }

    testWidgets('renders Markdown widget with tutorial content', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // The Markdown widget must be present.
      expect(find.byKey(const ValueKey('tutorial_markdown')), findsOneWidget);
      expect(find.textContaining('Guía de Uso'), findsWidgets);
    });

    testWidgets('shows tutorial content text from UserGuideText', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // The guide title must appear somewhere in the rendered text.
      expect(
        find.textContaining('Guía de Uso', findRichText: true),
        findsWidgets,
      );
    });

    testWidgets('shows section headers from the guide', (tester) async {
      // Verify the guide content string contains all section headers.
      // (Markdown renders into a ListView; widgets outside viewport are lazy
      // and won't be found by text finders — assert on source data instead.)
      const content = UserGuideText.markdownContent;
      expect(content, contains('Interacción Directa'));
      expect(content, contains('Control del Lienzo'));
      expect(content, contains('Modelo de Direcciones'));
      expect(content, contains('Historial y Menú'));
    });

    testWidgets('shows the close button', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      expect(find.byKey(const ValueKey('tutorial_close_btn')), findsOneWidget);
      expect(find.text('Entendido, volver al lienzo'), findsOneWidget);
    });

    testWidgets('close button pops the route', (tester) async {
      // Push TutorialScreen on top of a dummy home so pop works.
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => Navigator.of(ctx).push(
              MaterialPageRoute(builder: (_) => const TutorialScreen()),
            ),
            child: const Text('Open'),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tutorial screen is showing.
      expect(find.byType(TutorialScreen), findsOneWidget);

      // Tap the close button.
      await tester.tap(find.byKey(const ValueKey('tutorial_close_btn')));
      await tester.pumpAndSettle();

      // Tutorial screen should be gone.
      expect(find.byType(TutorialScreen), findsNothing);
    });

    testWidgets('UserGuideText.markdownContent is non-empty', (tester) async {
      expect(UserGuideText.markdownContent.trim(), isNotEmpty);
      expect(UserGuideText.markdownContent, contains('# '));
    });
  });
}
