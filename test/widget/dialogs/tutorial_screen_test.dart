import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/assignment/assignment_algorithm.dart';
import 'package:nodos/algorithms/core/algorithm_registry.dart';
import 'package:nodos/algorithms/johnson/johnson_algorithm.dart';
import 'package:nodos/algorithms/northwest/northwest_algorithm.dart';
import 'package:nodos/ui/dialogs/tutorial_screen.dart';
import 'package:nodos/ui/text/user_guide_text.dart';

void main() {
  group('TutorialScreen Widget Tests', () {
    Widget buildSubject() {
      return const ProviderScope(child: MaterialApp(home: TutorialScreen()));
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
      expect(content, contains('Modos de Asignación de Roles'));
      expect(content, contains('Algoritmos Disponibles'));
      expect(content, contains('Navegación Web Educativa'));
      expect(content, contains('Matrices Interactivas'));
      expect(content, contains('Historial, Guardado y Asistente IA'));
    });

    testWidgets('shows the close button', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      expect(find.byKey(const ValueKey('tutorial_close_btn')), findsOneWidget);
      expect(find.text('Entendido, volver al lienzo'), findsOneWidget);
    });

    for (final algorithm in [
      const AssignmentAlgorithm(),
      const JohnsonAlgorithm(),
      const NorthwestAlgorithm(),
    ]) {
      testWidgets('shows the structured guide for ${algorithm.name}', (
        tester,
      ) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container
            .read(activeAlgorithmProvider.notifier)
            .selectAlgorithm(algorithm);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: TutorialScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(algorithm.name), findsWidgets);
        expect(find.text('01'), findsOneWidget);
        expect(find.byKey(const ValueKey('tutorial_markdown')), findsOneWidget);
      });
    }

    testWidgets('close button pops the route', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => Navigator.of(ctx).push(
                  MaterialPageRoute(builder: (_) => const TutorialScreen()),
                ),
                child: const Text('Open'),
              ),
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
