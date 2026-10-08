import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/core/algorithm_registry.dart';
import 'package:nodos/application/providers/grafo_provider.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/domain/models/nodo.dart';
import 'package:nodos/ui/screens/graph_editor_screen.dart';
import 'package:nodos/ui/theme/app_theme.dart';

void main() {
  group('GraphEditorScreen Navigation & Clear Tests', () {
    testWidgets(
      'Vaciar from drawer menu clears canvas and preserves active algorithm mode',
      (tester) async {
        final container = ProviderContainer();

        // Pre-fill graph with a node and select Johnson algorithm
        container
            .read(grafoProvider.notifier)
            .cargarGrafo(
              const Grafo(
                nodos: {'n1': Nodo(id: 'n1', colorValue: 0, x: 10, y: 10)},
              ),
            );
        container.read(activeAlgorithmProvider.notifier).selectById('johnson');

        expect(container.read(grafoProvider).nodos.length, equals(1));
        expect(container.read(activeAlgorithmProvider)?.id, equals('johnson'));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const GraphEditorScreen(),
            ),
          ),
        );
        await tester.pump();

        // Open end drawer via menu button
        final menuBtn = find.byIcon(Icons.menu_rounded);
        expect(menuBtn, findsOneWidget);
        await tester.tap(menuBtn);
        await tester.pumpAndSettle();

        // Tap Vaciar
        final vaciarItem = find.text('Vaciar');
        expect(vaciarItem, findsOneWidget);
        await tester.tap(vaciarItem);
        await tester.pump();

        // Graph should be empty and active algorithm mode preserved (Johnson)
        expect(container.read(grafoProvider).nodos.isEmpty, isTrue);
        expect(container.read(activeAlgorithmProvider)?.id, equals('johnson'));

        // Clean up widget tree before disposing container
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpWidget(const SizedBox());
        container.dispose();
      },
    );

    testWidgets('home button cleans canvas and unloads all state', (
      tester,
    ) async {
      final container = ProviderContainer();

      // Pre-fill graph with a node and select Johnson algorithm
      container
          .read(grafoProvider.notifier)
          .cargarGrafo(
            const Grafo(
              nodos: {'n1': Nodo(id: 'n1', colorValue: 0, x: 10, y: 10)},
            ),
          );
      container.read(activeAlgorithmProvider.notifier).selectById('johnson');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const GraphEditorScreen(),
          ),
        ),
      );
      await tester.pump();

      // Tap Ir a la página principal (home icon).
      final homeButton = find.byIcon(Icons.home_outlined);
      expect(homeButton, findsOneWidget);
      await tester.tap(homeButton);
      await tester.pump();

      // State should be completely cleaned
      expect(container.read(grafoProvider).nodos.isEmpty, isTrue);
      expect(container.read(activeAlgorithmProvider), isNull);

      // Clean up widget tree before disposing container
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });
  });
}
