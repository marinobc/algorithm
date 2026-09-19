import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/core/algorithm_registry.dart';
import 'package:nodos/ui/dialogs/algorithm_selection_dialog.dart';
import 'package:nodos/ui/theme/app_theme.dart';

void main() {
  group('AlgorithmSelectionDialog Widget Tests', () {
    testWidgets('renders the algorithm selector as a full screen page', (
      tester,
    ) async {
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AlgorithmSelectionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Selecciona un algoritmo'), findsOneWidget);
      expect(find.text('Modo Libre'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });

    testWidgets(
      'renders Modo Libre at the top without any preselected checkmark',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final container = ProviderContainer();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: Dialog(
                child: Consumer(
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
        expect(find.text('Asignación'), findsOneWidget);
        expect(find.text('Johnson'), findsOneWidget);

        // Verify no checkmark icons are preselected
        expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

        // Clean up widget tree before disposing container
        await tester.pumpWidget(const SizedBox());
        container.dispose();
      },
    );

    testWidgets('tapping Modo Libre clears active algorithm', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      container.read(activeAlgorithmProvider.notifier).selectById('johnson');
      expect(container.read(activeAlgorithmProvider)?.id, equals('johnson'));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Dialog(
              child: Consumer(
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
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      container.read(activeAlgorithmProvider.notifier).selectById('johnson');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Dialog(
              child: Consumer(
                builder: (context, ref, _) =>
                    AlgorithmSelectionDialog(ref: ref),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final proximamenteText = find.text('Próximamente').first;
      final card = tester.widget<InkWell>(
        find
            .ancestor(of: proximamenteText, matching: find.byType(InkWell))
            .first,
      );

      expect(card.onTap, isNull);
      expect(container.read(activeAlgorithmProvider)?.id, equals('johnson'));

      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });

    testWidgets('selects Northwest from the shared catalog', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Dialog(
              child: Consumer(
                builder: (context, ref, _) =>
                    AlgorithmSelectionDialog(ref: ref),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final northwest = find.text('Northwest');
      await tester.tap(northwest);
      await tester.pump();

      expect(
        container.read(activeAlgorithmProvider)?.id,
        AlgorithmRegistry.northwestId,
      );

      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });
  });
}
