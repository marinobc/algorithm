import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/domain/services/sorting_registry.dart';
import 'package:nodos/domain/services/sorting_steps.dart';
import 'package:nodos/ui/dialogs/algorithm_selection_dialog.dart';
import 'package:nodos/ui/dialogs/sorting_usage_dialog.dart';
import 'package:nodos/ui/screens/sorting_algo_screen.dart';
import 'package:nodos/ui/screens/sorting_visualizer_screen.dart';
import 'package:nodos/ui/widgets/merge_sort_visualizer.dart';
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
          find.textContaining(switch (algorithm.id) {
            'selection' => 'i es la posición que se ordena',
            'insertion' => 'KEY se eleva',
            'shell' => 'gap de cada pasada',
            _ => 'dos mitades activas',
          }),
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

  testWidgets('Merge camera follows comparison and the pin moving to output', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final values = List<int>.generate(30, (index) => 30 - index);
    final steps = SortingTimeline.build(SortingAlgorithm.merge, values).steps;
    final writingIndex = steps.indexWhere(
      (step) =>
          step.mergeState?.stage == SortingMergeStage.fusion &&
          step.phase == SortingPhase.mergeWriting &&
          step.mergeState?.outputIds.length == 1 &&
          step.mergeState!.rightIds.contains(step.mergeState!.selectedId),
    );
    expect(writingIndex, greaterThan(0));
    final comparison = steps[writingIndex - 1];
    final progress = AnimationController(vsync: tester, value: 0);
    addTearDown(progress.dispose);

    Widget app(SortingStep step, {bool following = false}) => MaterialApp(
      home: Scaffold(
        body: MergeSortVisualizer(
          values: values,
          previous: steps[writingIndex - 1],
          current: step,
          progress: progress,
          followPlayback: following,
        ),
      ),
    );

    await tester.pumpWidget(app(steps.first));
    final scrollable = find.descendant(
      of: find.byType(MergeSortVisualizer),
      matching: find.byType(Scrollable),
    );
    double offset() =>
        tester.state<ScrollableState>(scrollable).position.pixels;
    expect(offset(), 0);

    await tester.pumpWidget(app(comparison, following: true));
    await tester.pumpAndSettle();
    expect(offset(), greaterThan(400));
    final pausedOffset = offset();

    await tester.pumpWidget(app(steps.first));
    await tester.pumpAndSettle();
    expect(offset(), pausedOffset);

    await tester.pumpWidget(app(steps[writingIndex], following: true));
    await tester.pumpAndSettle();
    expect(offset(), greaterThan(400));
    progress.value = 1;
    await tester.pump();
    expect(offset(), lessThan(100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('selector opens all four sorting algorithms', (tester) async {
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
    expect(find.text('Shell Sort'), findsOneWidget);
    expect(find.text('Merge Sort'), findsOneWidget);

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
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shell Sort'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SortingVisualizerScreen>(find.byType(SortingVisualizerScreen))
          .algorithm,
      SortingRegistry.shell,
    );
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Merge Sort'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SortingVisualizerScreen>(find.byType(SortingVisualizerScreen))
          .algorithm,
      SortingRegistry.merge,
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

  testWidgets('sidebar opens Shell and Merge explanation pages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SortingAlgoScreen(algorithm: SortingRegistry.selection),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shell Sort').first);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Ordena elementos distantes entre sí; reduce el gap hasta llegar a una inserción final con gap 1.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Merge Sort').first);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Divide el conjunto en dos mitades, ordena cada mitad y fusiónalas comparando sus elementos.',
      ),
      findsOneWidget,
    );
    expect(find.byType(SortingVisualizerScreen), findsNothing);
    expect(tester.takeException(), isNull);
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

  for (final (width, height, count) in [
    (1440.0, 900.0, 5),
    (1366.0, 768.0, 8),
    (820.0, 900.0, 15),
    (390.0, 844.0, 30),
  ]) {
    testWidgets('Selection Sort fits $count pins at ${width.toInt()}px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, height);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SortingVisualizerScreen(
              algorithm: SortingRegistry.selection,
            ),
          ),
        ),
      );
      await tester.enterText(input('Elementos'), '$count');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aleatoria'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Generar números'));
      await tester.pumpAndSettle();

      final pins = tester.widget<SortingPinVisualizer>(
        find.byType(SortingPinVisualizer),
      );
      expect(pins.values, hasLength(count));
      expect(pins.selectionStyle, isTrue);
      expect(find.text('$count elementos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Selection Sort keeps equal manual values and player controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
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
    await tester.enterText(input('Elementos'), '5');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    for (var index = 1; index <= 5; index++) {
      await tester.enterText(input('#$index'), '7');
    }
    await tester.tap(find.text('Visualizar números'));
    await tester.pumpAndSettle();

    final pins = tester.widget<SortingPinVisualizer>(
      find.byType(SortingPinVisualizer),
    );
    expect(pins.values, everyElement(7));
    expect(find.byTooltip('Reiniciar'), findsOneWidget);
    expect(find.byTooltip('Paso anterior'), findsOneWidget);
    expect(find.byTooltip('Reproducir'), findsOneWidget);
    expect(find.byTooltip('Siguiente paso'), findsOneWidget);
    await tester.tap(find.byTooltip('Siguiente paso'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        '2 / ${SortingTimeline.build(SortingAlgorithm.selection, List.filled(5, 7)).steps.length}',
      ),
      findsOneWidget,
    );
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

  testWidgets(
    'switching during playback keeps original values and stops the old run',
    (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SortingVisualizerScreen(
              algorithm: SortingRegistry.selection,
            ),
          ),
        ),
      );
      await tester.enterText(input('Elementos'), '4');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      for (final (index, value) in [(1, '4'), (2, '1'), (3, '3'), (4, '2')]) {
        await tester.enterText(input('#$index'), value);
      }
      await tester.tap(find.text('Visualizar números'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Reproducir'));
      await tester.pump(const Duration(milliseconds: 70));
      expect(find.byTooltip('Pausar'), findsOneWidget);
      await tester.tap(find.byKey(const Key('sorting-shell')));
      await tester.pump();
      expect(find.byTooltip('Pausar'), findsNothing);
      expect(find.text('Conjunto listo para ordenar.'), findsOneWidget);
      expect(
        tester
            .widget<SortingPinVisualizer>(find.byType(SortingPinVisualizer))
            .values,
        [4, 1, 3, 2],
      );
      expect(input('#1'), findsOneWidget);
      expect(tester.widget<TextField>(input('#1')).controller!.text, '4');
      await tester.tap(find.byKey(const Key('sorting-merge')));
      await tester.pump();
      expect(find.text('Conjunto listo para ordenar.'), findsOneWidget);
      expect(
        tester
            .widget<MergeSortVisualizer>(find.byType(MergeSortVisualizer))
            .values,
        [4, 1, 3, 2],
      );
      await tester.tap(find.byTooltip('Siguiente paso'));
      await tester.pumpAndSettle();
      expect(find.text('Mitad izquierda'), findsOneWidget);
      expect(find.text('Mitad derecha'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'editing a manual draft invalidates the run but keeps draft when switching',
    (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SortingVisualizerScreen(
              algorithm: SortingRegistry.insertion,
            ),
          ),
        ),
      );
      await tester.enterText(input('Elementos'), '2');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.enterText(input('#1'), '8');
      await tester.enterText(input('#2'), '3');
      await tester.tap(find.text('Visualizar números'));
      await tester.pumpAndSettle();
      await tester.enterText(input('#2'), '7');
      await tester.pump();
      expect(find.byTooltip('Reproducir'), findsNothing);
      await tester.tap(find.byKey(const Key('sorting-shell')));
      await tester.pump();
      expect(tester.widget<TextField>(input('#2')).controller!.text, '7');
      expect(find.byTooltip('Reproducir'), findsNothing);
      await tester.tap(find.text('Visualizar números'));
      await tester.pump();
      expect(
        tester
            .widget<SortingPinVisualizer>(find.byType(SortingPinVisualizer))
            .values,
        [8, 7],
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final algorithm in [SortingRegistry.shell, SortingRegistry.merge]) {
    for (final (width, count) in [(1366.0, 8), (390.0, 30)]) {
      testWidgets(
        '${algorithm.name} displays $count values at ${width.toInt()}px',
        (tester) async {
          tester.view.physicalSize = Size(width, 844);
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
          await tester.enterText(input('Elementos'), '$count');
          await tester.tap(find.text('Continuar'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Aleatoria'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Generar números'));
          await tester.pumpAndSettle();
          expect(find.text('$count elementos'), findsOneWidget);
          await tester.ensureVisible(find.byTooltip('Siguiente paso'));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Siguiente paso'));
          await tester.pumpAndSettle();
          if (algorithm.id == 'merge') {
            expect(find.text('Mitad izquierda'), findsOneWidget);
            expect(find.text('Mitad derecha'), findsOneWidget);
          } else {
            expect(find.textContaining('gap'), findsWidgets);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('random values survive a change of sorting algorithm', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SortingVisualizerScreen(algorithm: SortingRegistry.insertion),
        ),
      ),
    );
    await tester.enterText(input('Elementos'), '8');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aleatoria'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generar números'));
    await tester.pumpAndSettle();
    final original = List<int>.of(
      tester
          .widget<SortingPinVisualizer>(find.byType(SortingPinVisualizer))
          .values,
    );
    await tester.tap(find.byKey(const Key('sorting-shell')));
    await tester.pump();
    expect(
      tester
          .widget<SortingPinVisualizer>(find.byType(SortingPinVisualizer))
          .values,
      original,
    );
    await tester.tap(find.byKey(const Key('sorting-insertion')));
    await tester.pump();
    expect(
      tester
          .widget<SortingPinVisualizer>(find.byType(SortingPinVisualizer))
          .values,
      original,
    );
    expect(tester.takeException(), isNull);
  });

  for (final (width, count) in [
    (1440.0, 5),
    (1366.0, 8),
    (820.0, 15),
    (390.0, 30),
  ]) {
    testWidgets(
      'all four algorithms share $count values at ${width.toInt()}px',
      (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: SortingVisualizerScreen(
                algorithm: SortingRegistry.selection,
              ),
            ),
          ),
        );
        await tester.enterText(input('Elementos'), '$count');
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Aleatoria'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Generar números'));
        await tester.pumpAndSettle();
        final original = List<int>.of(
          tester
              .widget<SortingPinVisualizer>(find.byType(SortingPinVisualizer))
              .values,
        );
        for (final algorithm in SortingRegistry.registeredAlgorithms) {
          final chip = find.byKey(Key('sorting-${algorithm.id}'));
          await tester.ensureVisible(chip);
          await tester.pumpAndSettle();
          await tester.tap(chip);
          await tester.pumpAndSettle();
          final current = algorithm.id == 'merge'
              ? tester
                    .widget<MergeSortVisualizer>(
                      find.byType(MergeSortVisualizer),
                    )
                    .values
              : tester
                    .widget<SortingPinVisualizer>(
                      find.byType(SortingPinVisualizer),
                    )
                    .values;
          expect(current, original);
          expect(tester.takeException(), isNull);
        }
      },
    );
  }

  testWidgets('extreme and duplicate values remain intact in all four views', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const values = [1000000000, -1000000000, 0, 7, 7];
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SortingVisualizerScreen(algorithm: SortingRegistry.selection),
        ),
      ),
    );
    await tester.enterText(input('Elementos'), '${values.length}');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    for (var i = 0; i < values.length; i++) {
      await tester.enterText(input('#${i + 1}'), '${values[i]}');
    }
    await tester.tap(find.text('Visualizar números'));
    await tester.pumpAndSettle();
    for (final algorithm in SortingRegistry.registeredAlgorithms) {
      await tester.tap(find.byKey(Key('sorting-${algorithm.id}')));
      await tester.pumpAndSettle();
      final current = algorithm.id == 'merge'
          ? tester
                .widget<MergeSortVisualizer>(find.byType(MergeSortVisualizer))
                .values
          : tester
                .widget<SortingPinVisualizer>(find.byType(SortingPinVisualizer))
                .values;
      expect(current, values);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('narrow selector brings the active algorithm into view', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SortingVisualizerScreen(algorithm: SortingRegistry.merge),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final selected = find.byKey(const Key('sorting-merge'));
    expect(tester.getTopLeft(selected).dx, greaterThanOrEqualTo(0));
    expect(tester.getBottomRight(selected).dx, lessThanOrEqualTo(390));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Merge seek, previous, next and restart stay on the same event', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const values = [4, 1, 3, 2];
    final timeline = SortingTimeline.build(SortingAlgorithm.merge, values);
    final target = timeline.steps.indexWhere(
      (s) =>
          s.mergeState?.stage == SortingMergeStage.fusion &&
          s.phase == SortingPhase.mergeWriting &&
          s.mergeState?.outputIds.length == 2,
    );
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SortingVisualizerScreen(algorithm: SortingRegistry.merge),
        ),
      ),
    );
    await tester.enterText(input('Elementos'), '4');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    for (var i = 0; i < values.length; i++) {
      await tester.enterText(input('#${i + 1}'), '${values[i]}');
    }
    await tester.tap(find.text('Visualizar números'));
    await tester.pumpAndSettle();
    tester.widget<Slider>(find.byType(Slider)).onChanged!(target.toDouble());
    await tester.pump();
    MergeSortVisualizer visualizer() =>
        tester.widget<MergeSortVisualizer>(find.byType(MergeSortVisualizer));
    expect(visualizer().current.message, timeline.steps[target].message);
    expect(visualizer().current.mergeState!.stage, SortingMergeStage.fusion);
    expect(visualizer().current.mergeState!.outputIds, hasLength(2));
    expect(find.text('Fusión'), findsOneWidget);
    await tester.tap(find.byTooltip('Paso anterior'));
    await tester.pump();
    expect(visualizer().current.phase, SortingPhase.mergeComparing);
    expect(visualizer().current.mergeState!.outputIds, hasLength(1));
    await tester.tap(find.byTooltip('Siguiente paso'));
    await tester.pumpAndSettle();
    expect(visualizer().current.phase, SortingPhase.mergeWriting);
    expect(visualizer().current.mergeState!.outputIds, hasLength(2));
    await tester.tap(find.byTooltip('Reiniciar'));
    await tester.pump();
    expect(visualizer().current.mergeState!.stage, SortingMergeStage.ready);
    await tester.tap(find.byTooltip('Reproducir'));
    await tester.pump(const Duration(milliseconds: 90));
    expect(find.byTooltip('Pausar'), findsOneWidget);
    await tester.tap(find.byTooltip('Pausar'));
    await tester.pump();
    expect(find.byTooltip('Reproducir'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
