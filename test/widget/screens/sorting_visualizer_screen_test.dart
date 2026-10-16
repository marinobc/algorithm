import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nodos/domain/services/sorting_registry.dart';
import 'package:nodos/domain/services/sorting_set_storage_service.dart';
import 'package:nodos/domain/services/sorting_steps.dart';
import 'package:nodos/ui/dialogs/algorithm_selection_dialog.dart';
import 'package:nodos/ui/dialogs/sorting_usage_dialog.dart';
import 'package:nodos/ui/screens/sorting_algo_screen.dart';
import 'package:nodos/ui/screens/sorting_visualizer_screen.dart';
import 'package:nodos/ui/widgets/merge_sort_visualizer.dart';
import 'package:nodos/ui/widgets/web_explanation_navbar.dart';
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

        await tester.tap(find.byTooltip('Guía de uso'));
        await tester.pumpAndSettle();
        expect(find.byType(SortingUsageDialog), findsOneWidget);
        expect(find.text('1. Prepara los datos'), findsOneWidget);
        expect(find.text('3. Controla la animación'), findsOneWidget);
        expect(
          find.textContaining(switch (algorithm.id) {
            'selection' => 'i es la posición que se ordena',
            'insertion' => 'KEY se eleva',
            'shell' => 'h en cada pasada',
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
    expect(offset(), greaterThan(200));
    final pausedOffset = offset();

    await tester.pumpWidget(app(steps.first));
    await tester.pumpAndSettle();
    expect(offset(), pausedOffset);

    await tester.pumpWidget(app(steps[writingIndex], following: true));
    await tester.pumpAndSettle();
    expect(offset(), greaterThan(200));
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
    expect(find.text('Ordenamiento'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Ordenamiento')).dy,
      greaterThan(tester.getTopLeft(find.text('Northwest')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Ordenamiento')).dy,
      lessThan(tester.getTopLeft(find.text('Selection Sort')).dy),
    );
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
    expect(find.text('Ordenamiento'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Ordenamiento')).dy,
      greaterThan(tester.getTopLeft(find.text('Northwest')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Ordenamiento')).dy,
      lessThan(tester.getTopLeft(find.text('Selection Sort').first).dy),
    );
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

  testWidgets('sorting group remains reachable in the mobile menu', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: WebExplanationShell(
            activePage: ExplanationWebPage.selectionSort,
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Abrir Menú Principal'));
    await tester.pumpAndSettle();
    final sortingHeading = find.descendant(
      of: find.byType(Drawer),
      matching: find.text('Ordenamiento'),
    );
    final mergeLink = find.descendant(
      of: find.byType(Drawer),
      matching: find.text('Merge Sort'),
    );
    expect(sortingHeading, findsOneWidget);
    await tester.ensureVisible(mergeLink);
    expect(mergeLink, findsOneWidget);
    expect(tester.getTopLeft(mergeLink).dy, greaterThan(0));
    expect(tester.takeException(), isNull);
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
        'Compara e intercambia elementos distantes; reduce h hasta completar la pasada final con h=1.',
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

  testWidgets(
    'saved pins can be loaded after starting a new set and switching sort',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SortingVisualizerScreen(algorithm: SortingRegistry.selection),
          ),
        ),
      );
      expect(find.text('Guardar'), findsOneWidget);
      await tester.enterText(input('Elementos'), '3');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      for (final (index, value) in [(1, '9'), (2, '2'), (3, '5')]) {
        await tester.enterText(input('#$index'), value);
      }
      await tester.tap(find.text('Visualizar números'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      await tester.enterText(input('Nombre del conjunto'), 'Mi práctica');
      await tester.pump();
      expect(
        tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Guardar'),
        ).onPressed,
        isNotNull,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Guardar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(
        (await SortingSetStorageService.getSavedSets()).single.name,
        'Mi práctica',
      );

      await tester.tap(find.byKey(const Key('sorting-merge')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nuevo'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Nuevo'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MergeSortVisualizer), findsNothing);

      await tester.tap(find.text('Cargar'));
      await tester.pumpAndSettle();
      expect(find.text('Mi práctica'), findsOneWidget);
      await tester.tap(find.text('Mi práctica'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MergeSortVisualizer>(find.byType(MergeSortVisualizer))
            .values,
        [9, 2, 5],
      );
      expect(tester.widget<TextField>(input('#1')).controller!.text, '9');
      expect(tester.widget<TextField>(input('#2')).controller!.text, '2');
      expect(tester.widget<TextField>(input('#3')).controller!.text, '5');
      expect(find.text('Conjunto listo para ordenar.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

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

  testWidgets('more than sixty elements fit without a layout overflow', (
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
    await tester.enterText(input('Elementos'), '61');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aleatoria'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generar números'));
    await tester.pumpAndSettle();
    expect(find.text('61 elementos'), findsOneWidget);
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
            expect(find.textContaining('h='), findsWidgets);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('Shell swap can be sought, reversed and replayed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const values = [8, 7, 6, 5, 4, 3, 2, 1];
    final timeline = SortingTimeline.build(SortingAlgorithm.shell, values);
    final swapIndex = timeline.steps.indexWhere(
      (step) => step.phase == SortingPhase.swapping,
    );
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SortingVisualizerScreen(algorithm: SortingRegistry.shell),
        ),
      ),
    );
    await tester.enterText(input('Elementos'), '${values.length}');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    for (var i = 0; i < values.length; i++) {
      await tester.enterText(input('#${i + 1}'), '${values[i]}');
    }
    await tester.ensureVisible(find.text('Visualizar números'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Visualizar números'));
    await tester.pumpAndSettle();
    tester.widget<Slider>(find.byType(Slider)).onChanged!(swapIndex.toDouble());
    await tester.pump();
    SortingStep shown() => tester
        .widget<SortingPinVisualizer>(find.byType(SortingPinVisualizer))
        .current;
    expect(shown().phase, SortingPhase.swapping);
    expect(shown().slots, timeline.steps[swapIndex].slots);
    expect(shown().keyRaised, isFalse);
    expect(find.textContaining('Intercambio'), findsWidgets);
    expect(find.text('j · pos. 5 · 4'), findsOneWidget);
    expect(find.text('j-h · pos. 1 · 8'), findsOneWidget);
    expect(find.text('Intercambios'), findsOneWidget);
    await tester.tap(find.byTooltip('Paso anterior'));
    await tester.pump();
    expect(shown().phase, SortingPhase.comparing);
    expect(shown().slots, timeline.steps[swapIndex - 1].slots);
    await tester.tap(find.byTooltip('Siguiente paso'));
    await tester.pumpAndSettle();
    expect(shown().phase, SortingPhase.swapping);
    expect(shown().slots, timeline.steps[swapIndex].slots);
    await tester.tap(find.byTooltip('Reiniciar'));
    await tester.pump();
    expect(shown().phase, SortingPhase.ready);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shell guide shows interleaved groups and distinct operations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(840, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const values = [8, 3, 7, 2, 6, 1, 5, 4];
    final steps = SortingTimeline.build(SortingAlgorithm.shell, values).steps;
    final start = steps.firstWhere(
      (step) => step.gap == 4 && step.phase == SortingPhase.gap,
    );
    final comparison = steps.firstWhere(
      (step) => step.gap == 4 && step.phase == SortingPhase.comparing,
    );
    final swap = steps.firstWhere(
      (step) => step.gap == 4 && step.phase == SortingPhase.swapping,
    );
    final unchanged = steps.firstWhere(
      (step) => step.gap == 4 && step.phase == SortingPhase.current,
    );
    final complete = steps.firstWhere(
      (step) => step.gap == 4 && step.phase == SortingPhase.sorted,
    );

    Widget app(SortingStep step) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 840,
          height: 420,
          child: SortingPinVisualizer(
            values: values,
            previous: step,
            current: step,
            progress: const AlwaysStoppedAnimation<double>(1),
            shellStyle: true,
          ),
        ),
      ),
    );

    await tester.pumpWidget(app(start));
    expect(find.text('PASADA  h = 4'), findsOneWidget);
    expect(
      find.text('4 subsecuencias intercaladas: 4 pares y 0 individuales.'),
      findsOneWidget,
    );
    await tester.pumpWidget(app(comparison));
    expect(find.text('Subsecuencia 1 de 4'), findsOneWidget);
    expect(find.text('Comparando'), findsOneWidget);
    expect(find.text('j · pos. 5 · 6'), findsOneWidget);
    expect(find.text('j-h · pos. 1 · 8'), findsOneWidget);
    await tester.pumpWidget(app(swap));
    expect(find.text('Intercambio real'), findsOneWidget);
    expect(find.text('j · pos. 5 · 6'), findsOneWidget);
    expect(find.text('j-h · pos. 1 · 8'), findsOneWidget);
    await tester.pumpWidget(app(unchanged));
    expect(find.textContaining('Sin intercambio'), findsOneWidget);
    await tester.pumpWidget(app(complete));
    expect(find.text('Pasada completa'), findsOneWidget);
    expect(
      find.text(
        'Las 4 subsecuencias están h-ordenadas; el arreglo completo aún no.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('aún no'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shell h=13 focus identifies three pairs and ten singletons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 460);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const values = [
      54,
      32,
      44,
      68,
      12,
      71,
      19,
      83,
      20,
      41,
      59,
      77,
      86,
      98,
      33,
      65,
    ];
    final steps = SortingTimeline.build(SortingAlgorithm.shell, values).steps;
    final start = steps.firstWhere(
      (step) => step.gap == 13 && step.phase == SortingPhase.gap,
    );
    final comparison = steps.firstWhere(
      (step) => step.gap == 13 && step.phase == SortingPhase.comparing,
    );
    final noSwap = steps.firstWhere(
      (step) => step.gap == 13 && step.phase == SortingPhase.current,
    );
    Widget app(SortingStep step) => MaterialApp(
      home: Scaffold(
        body: SortingPinVisualizer(
          values: values,
          previous: step,
          current: step,
          progress: const AlwaysStoppedAnimation<double>(1),
          shellStyle: true,
        ),
      ),
    );
    await tester.pumpWidget(app(start));
    expect(
      find.text('13 subsecuencias intercaladas: 3 pares y 10 individuales.'),
      findsOneWidget,
    );
    await tester.pumpWidget(app(comparison));
    expect(find.text('Subsecuencia 1 de 13'), findsOneWidget);
    expect(find.text('j-h · pos. 1 · 54'), findsOneWidget);
    expect(find.text('j · pos. 14 · 98'), findsOneWidget);
    expect(find.text('distancia 13'), findsOneWidget);
    expect(
      find.textContaining('aún no se conoce el resultado'),
      findsOneWidget,
    );
    await tester.pumpWidget(app(noSwap));
    expect(find.text('Sin intercambio'), findsOneWidget);
    expect(find.textContaining('Permanecen en sus posiciones'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final (count, gap) in [(30, 13), (80, 40)]) {
    testWidgets('Shell overview remains usable with $count pins', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(830, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final values = List<int>.generate(count, (index) => count - index);
      final steps = SortingTimeline.build(SortingAlgorithm.shell, values).steps;
      final start = steps.firstWhere(
        (step) => step.gap == gap && step.phase == SortingPhase.gap,
      );
      final comparison = steps.lastWhere(
        (step) => step.gap == gap && step.phase == SortingPhase.comparing,
      );
      final complete = steps.firstWhere(
        (step) => step.gap == gap && step.phase == SortingPhase.sorted,
      );

      Widget app(SortingStep step) => MaterialApp(
        home: Scaffold(
          body: SortingPinVisualizer(
            values: values,
            previous: step,
            current: step,
            progress: const AlwaysStoppedAnimation<double>(1),
            followPlayback: true,
            shellStyle: true,
          ),
        ),
      );

      await tester.pumpWidget(app(start));
      expect(find.text('PASADA  h = $gap'), findsOneWidget);
      final scrollbar = find.descendant(
        of: find.byType(SortingPinVisualizer),
        matching: find.byType(Scrollbar),
      );
      expect(tester.widget<Scrollbar>(scrollbar).thumbVisibility, isTrue);
      await tester.pumpWidget(app(comparison));
      await tester.pumpAndSettle();
      expect(find.text('Comparando'), findsOneWidget);
      await tester.pumpWidget(app(complete));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Las $gap subsecuencias están h-ordenadas; el arreglo completo aún no.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
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
    (1366.0, 24),
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
          if (count == 24) {
            final visualizer = algorithm.id == 'merge'
                ? find.byType(MergeSortVisualizer)
                : find.byType(SortingPinVisualizer);
            final scrollbar = find.descendant(
              of: visualizer,
              matching: find.byType(Scrollbar),
            );
            expect(
              tester.widget<Scrollbar>(scrollbar).thumbVisibility,
              isFalse,
            );
          }
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

  testWidgets(
    'Merge explains positions 5–8 without anticipating the next write',
    (tester) async {
      tester.view.physicalSize = const Size(900, 560);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const values = [9, 8, 7, 6, 70, 26, 29, 25];
      final steps = SortingTimeline.build(SortingAlgorithm.merge, values).steps;
      final comparison = steps.firstWhere((step) {
        final state = step.mergeState!;
        return step.phase == SortingPhase.mergeComparing &&
            state.start == 4 &&
            state.end == 8 &&
            state.k == 6;
      });
      final state = comparison.mergeState!;
      expect(state.auxIds.sublist(4, 8).map((id) => values[id!]), [
        26,
        70,
        25,
        29,
      ]);
      expect((state.i, state.j, state.k), (5, 7, 6));
      expect(values[comparison.currentId!], 70);
      expect(values[comparison.comparingId!], 29);
      expect(state.outputIds.map((id) => values[id]), [25, 26]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MergeSortVisualizer(
              values: values,
              previous: comparison,
              current: comparison,
              progress: const AlwaysStoppedAnimation<double>(1),
            ),
          ),
        ),
      );
      expect(find.text('Comparando 70 con 29'), findsOneWidget);
      expect(find.text('lo 5 · mid 6 · hi 8'), findsOneWidget);
      expect(find.text('i 6 · izquierda'), findsOneWidget);
      expect(find.text('j 8 · derecha'), findsOneWidget);
      expect(find.text('k 7 · destino'), findsOneWidget);
      expect(
        find.textContaining('pendientes conservan su valor anterior'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [390.0, 900.0]) {
    testWidgets('Merge canvas stays still across fusion phases at $width px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 560);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const values = [9, 8, 7, 6, 70, 26, 29, 25];
      final steps = SortingTimeline.build(SortingAlgorithm.merge, values).steps;
      final phases = [
        SortingPhase.mergeCopying,
        SortingPhase.mergeComparing,
        SortingPhase.mergeWriting,
        SortingPhase.merged,
      ];
      final positions = <Offset>[];
      final sizes = <Size>[];
      for (final phase in phases) {
        final step = steps.firstWhere(
          (step) =>
              step.phase == phase &&
              step.mergeState?.stage == SortingMergeStage.fusion &&
              step.mergeState?.start == 0 &&
              step.mergeState?.end == 8,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MergeSortVisualizer(
                values: values,
                previous: step,
                current: step,
                progress: const AlwaysStoppedAnimation<double>(1),
              ),
            ),
          ),
        );
        final canvas = find.descendant(
          of: find.byType(MergeSortVisualizer),
          matching: find.byType(CustomPaint),
        );
        positions.add(tester.getTopLeft(canvas.first));
        sizes.add(tester.getSize(canvas.first));
        expect(tester.takeException(), isNull);
      }
      expect(positions, everyElement(positions.first));
      expect(sizes, everyElement(sizes.first));
    });
  }

  for (final (count, width) in [
    (1, 390.0),
    (5, 390.0),
    (12, 900.0),
    (16, 900.0),
    (80, 900.0),
  ]) {
    testWidgets(
      'Merge visualizer renders $count values at ${width.toInt()}px',
      (tester) async {
        tester.view.physicalSize = Size(width, 560);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final values = List<int>.generate(count, (index) => count - index);
        final timeline = SortingTimeline.build(SortingAlgorithm.merge, values);
        final step = timeline.steps.firstWhere(
          (step) => step.phase == SortingPhase.mergeComparing,
          orElse: () => timeline.steps.last,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MergeSortVisualizer(
                values: values,
                previous: step,
                current: step,
                progress: const AlwaysStoppedAnimation<double>(1),
              ),
            ),
          ),
        );
        expect(find.byType(MergeSortVisualizer), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

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
    expect(
      visualizer().current.mergeState!.arrayIds[visualizer()
          .current
          .mergeState!
          .k!],
      visualizer().current.mergeState!.selectedId,
    );
    expect(find.text('Copias a aux[]'), findsOneWidget);
    expect(find.text('Escrituras en a[]'), findsOneWidget);
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
    final pausedAt = visualizer().progress.value;
    await tester.pump(const Duration(milliseconds: 300));
    expect(visualizer().progress.value, pausedAt);
    await tester.tap(find.byTooltip('Reproducir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(visualizer().progress.value, greaterThan(pausedAt));
    expect(tester.takeException(), isNull);
  });
}
