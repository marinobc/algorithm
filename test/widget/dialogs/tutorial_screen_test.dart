import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/ui/dialogs/tutorial_screen.dart';
import 'package:nodos/ui/text/user_guide_text.dart';

void main() {
  group('TutorialScreen Widget Tests', () {
    Widget buildSubject() {
      return const MaterialApp(home: TutorialScreen());
    }

    testWidgets('renders Markdown widget with tutorial content', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      expect(find.byKey(const ValueKey('tutorial_markdown')), findsOneWidget);
      expect(find.textContaining('Guía de Uso'), findsWidgets);
    });

    testWidgets('shows tutorial content text from UserGuideText', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      expect(
        find.textContaining('Guía de Uso', findRichText: true),
        findsWidgets,
      );
    });

    testWidgets('shows section headers from the guide', (tester) async {
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
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => Navigator.of(
                ctx,
              ).push(MaterialPageRoute(builder: (_) => const TutorialScreen())),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(TutorialScreen), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('tutorial_close_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(TutorialScreen), findsNothing);
    });

    testWidgets('UserGuideText.markdownContent is non-empty', (tester) async {
      expect(UserGuideText.markdownContent.trim(), isNotEmpty);
      expect(UserGuideText.markdownContent, contains('# '));
    });
  });
}
