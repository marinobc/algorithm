import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/domain/services/sorting_registry.dart';
import 'package:nodos/domain/services/sorting_steps.dart';
import 'package:nodos/ui/dialogs/algorithm_selection_dialog.dart';
import 'package:nodos/ui/dialogs/sorting_usage_dialog.dart';
import 'package:nodos/ui/screens/sorting_algo_screen.dart';
import 'package:nodos/ui/screens/sorting_visualizer_screen.dart';
import 'package:nodos/ui/theme/app_theme.dart';
import 'package:nodos/ui/widgets/sorting_pin_visualizer.dart';

Finder input(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

void main() {
  for (final algorithm in SortingRegistry.registeredAlgorithms) {
    testWidgets(
      '${algorithm.name} opens its own usage guide on a narrow screen',
      (tester) async {
        tester.view.physicalSize = const Size(375, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: SortingVisualizerScreen(algorithm: algorithm),
            ),
          ),
        );

        await tester.tap(find.text('Guía de uso'));
        await tester.pumpAndSettle();
        expect(find.byType(SortingUsageDialog), findsOneWidget);
        expect(find.text('1. Prepara los datos'), findsOneWidget);
        expect(find.text('3. Controla la animación'), findsOneWidget);
        expect(
          find.textContaining(
            algorithm.id == 'selection'
                ? 'i es la posición que se ordena'
                : 'KEY se eleva',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        await tester.tap(find.byTooltip('Cerrar guía'));
        await tester.pumpAndSettle();
        expect(find.byType(SortingUsageDialog), findsNothing);
      },
    );
  }

  testWidgets(
    'overflow shows a draggable bar and playback follows the active pin',
    (tester) async {
      tester.view.physicalSize = const Size(400, 320);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final values = List<int>.generate(40, (index) => 40 - index);
      final steps = SortingTimeline.build(
        SortingAlgorithm.selection,
        values,
      ).steps;
      final active = steps.firstWhere((step) => step.comparingId == 35);

      Widget app(SortingStep step, {bool following = false}) => MaterialApp(
        home: Scaffold(
          body: SortingPinVisualizer(
            values: values,
            previous: steps.first,
            current: step,
            progress: const AlwaysStoppedAnimation<double>(1),
            followPlayback: following,
          ),
        ),
      );

      await tester.pumpWidget(app(steps.first));
      final scrollbar = find.descendant(
        of: find.byType(SortingPinVisualizer),
        matching: find.byType(Scrollbar),
      );
      final scrollable = find.descendant(
        of: find.byType(SortingPinVisualizer),
        matching: find.byType(Scrollable),
      );
      expect(tester.widget<Scrollbar>(scrollbar).thumbVisibility, isTrue);
      await tester.drag(
        find.byType(SortingPinVisualizer),
        const Offset(-180, 0),
      );
      await tester.pumpAndSettle();
      final manualOffset = tester
          .state<ScrollableState>(scrollable)
          .position
          .pixels;
      expect(manualOffset, greaterThan(0));

      await tester.pumpWidget(app(active, following: true));
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        greaterThan(manualOffset),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('selector opens Selection Sort and Insertion Sort in order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AlgorithmSelectionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Selection Sort'), findsOneWidget);
    expect(find.text('Insertion Sort'), findsOneWidget);

    await tester.tap(find.text('Selection Sort'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SortingVisualizerScreen>(find.byType(SortingVisualizerScreen))
          .algorithm,
      SortingRegistry.selection,
    );
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Insertion Sort'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SortingVisualizerScreen>(find.byType(SortingVisualizerScreen))
          .algorithm,
      SortingRegistry.insertion,
    );
  });

  testWidgets('sidebar opens explanation before the sorting tool', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SortingAlgoScreen(algorithm: SortingRegistry.selection),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Insertion Sort').first);
    await tester.pumpAndSettle();
    expect(find.byType(SortingAlgoScreen), findsOneWidget);
    expect(find.byType(SortingVisualizerScreen), findsNothing);
    expect(find.text('¿Cómo funciona?'), findsOneWidget);
    await tester.tap(find.text('Probar Insertion Sort').first);
    await tester.pumpAndSettle();
    expect(find.byType(SortingVisualizerScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.byType(SortingAlgoScreen), findsOneWidget);
  });

  testWidgets('manual input validates missing values and advances steps', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SortingVisualizerScreen(
            algorithm: SortingRegistry.selection,
          ),
        ),
      ),
    );
    await tester.enterText(input('Elementos'), '3');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.enterText(input('#1'), '5');
    await tester.enterText(input('#2'), '2');
    await tester.tap(find.text('Visualizar números'));
    await tester.pumpAndSettle();
    expect(find.text('Número inválido'), findsOneWidget);

    await tester.enterText(input('#3'), '4');
    await tester.tap(find.text('Visualizar números'));
    await tester.pumpAndSettle();
    expect(find.text('Conjunto listo para ordenar.'), findsOneWidget);
    expect(find.byType(SortingPinVisualizer), findsOneWidget);
    await tester.tap(find.byTooltip('Siguiente paso'));
    await tester.pumpAndSettle();
    expect(
      find.text('Buscando el menor elemento desde la posición 1.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('random input remains usable in a narrow window', (tester) async {
    tester.view.physicalSize = const Size(700, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SortingVisualizerScreen(
            algorithm: SortingRegistry.insertion,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aleatoria'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generar números'));
    await tester.pumpAndSettle();
    expect(find.text('8 elementos'), findsOneWidget);
    expect(find.text('n² / 4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sixty elements fit without a layout overflow', (tester) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SortingVisualizerScreen(
            algorithm: SortingRegistry.selection,
          ),
        ),
      ),
    );
    await tester.enterText(input('Elementos'), '60');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aleatoria'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generar números'));
    await tester.pumpAndSettle();
    expect(find.text('60 elementos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('playback finishes and keeps the sorted result visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SortingVisualizerScreen(
            algorithm: SortingRegistry.insertion,
          ),
        ),
      ),
    );
    await tester.enterText(input('Elementos'), '1');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.enterText(input('#1'), '1000');
    await tester.tap(find.text('Visualizar números'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Reproducir'));
    await tester.pumpAndSettle();
    expect(find.text('Ordenamiento finalizado.'), findsOneWidget);
    expect(find.text('TERMINADO'), findsOneWidget);
    expect(find.byTooltip('Reproducir'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
