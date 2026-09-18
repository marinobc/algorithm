import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/core/algorithm_registry.dart';
import 'package:nodos/ui/dialogs/algorithm_selection_dialog.dart';
import 'package:nodos/ui/theme/app_theme.dart';

void main() {
  group('AlgorithmSelectionDialog Widget Tests', () {
    testWidgets(
      'renders Modo Libre at the top without any preselected checkmark',
      (tester) async {
        final container = ProviderContainer();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) =>
                      AlgorithmSelectionDialog(ref: ref),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check title and content
        expect(find.text('Selecciona un algoritmo'), findsOneWidget);
        expect(find.text('Modo Libre'), findsOneWidget);
        expect(find.text('Algoritmo de Asignación'), findsOneWidget);
        expect(find.text('Algoritmo de Johnson / CPM'), findsOneWidget);
        expect(find.text('Próximamente'), findsNWidgets(2));

        // Verify no checkmark icons are preselected
        expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

        // Clean up widget tree before disposing container
        await tester.pumpWidget(const SizedBox());
        container.dispose();
      },
    );

    testWidgets('tapping Modo Libre clears active algorithm', (tester) async {
      final container = ProviderContainer();
      container.read(activeAlgorithmProvider.notifier).selectById('johnson');
      expect(container.read(activeAlgorithmProvider)?.id, equals('johnson'));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) =>
                    AlgorithmSelectionDialog(ref: ref),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Modo Libre
      await tester.tap(find.text('Modo Libre'));
      await tester.pump();

      // Active algorithm should be cleared to null
      expect(container.read(activeAlgorithmProvider), isNull);

      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });

    testWidgets('Próximamente does not change the active algorithm', (
      tester,
    ) async {
      final container = ProviderContainer();
      container.read(activeAlgorithmProvider.notifier).selectById('johnson');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) =>
                    AlgorithmSelectionDialog(ref: ref),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final card = tester.widget<InkWell>(
        find
            .ancestor(
              of: find.text('Próximamente').first,
              matching: find.byType(InkWell),
            )
            .first,
      );

      expect(card.onTap, isNull);
      expect(container.read(activeAlgorithmProvider)?.id, equals('johnson'));

      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });
  });
}
