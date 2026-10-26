import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/core/algorithm_registry.dart';
import 'package:nodos/algorithms/graph_paths/providers/graph_path_run_provider.dart';
import 'package:nodos/algorithms/graph_paths/ui/graph_path_theory_screen.dart';
import 'package:nodos/application/providers/grafo_provider.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/domain/models/nodo.dart';
import 'package:nodos/domain/models/conexion.dart';
import 'package:nodos/domain/models/direccion.dart';
import 'package:nodos/domain/models/atributo.dart';
import 'package:nodos/ui/dialogs/algorithm_selection_dialog.dart';
import 'package:nodos/ui/screens/graph_editor_screen.dart';
import 'package:nodos/ui/canvas/graph_canvas.dart';

void main() {
  testWidgets('catálogo abre teoría de Dijkstra y luego el laboratorio', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AlgorithmSelectionScreen()),
      ),
    );
    await tester.enterText(find.byType(TextField).first, 'Dijkstra');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dijkstra').last);
    await tester.pumpAndSettle();
    expect(find.byType(GraphPathTheoryScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.text('Abrir laboratorio de Dijkstra').first, findsOneWidget);
    await tester.tap(find.text('Abrir laboratorio de Dijkstra').first);
    await tester.pumpAndSettle();
    expect(
      container.read(activeAlgorithmProvider)?.id,
      AlgorithmRegistry.dijkstraId,
    );
    expect(find.byType(GraphCanvas), findsOneWidget);
    expect(find.text('Laboratorio de Dijkstra'), findsNothing);
    expect(find.text('Calcular ruta'), findsOneWidget);
    expect(find.textContaining('Haz clic para crear vértices'), findsOneWidget);
    expect(find.text('Kruskal'), findsNothing);
    expect(find.text('Agregar vértice'), findsNothing);
    expect(find.text('Agregar arista'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });

  testWidgets('catálogo abre teoría y laboratorio exclusivos de Kruskal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AlgorithmSelectionScreen()),
      ),
    );
    await tester.enterText(find.byType(TextField).first, 'Kruskal');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kruskal').last);
    await tester.pumpAndSettle();
    expect(find.byType(GraphPathTheoryScreen), findsOneWidget);
    await tester.tap(find.text('Abrir laboratorio de Kruskal').first);
    await tester.pumpAndSettle();
    expect(
      container.read(activeAlgorithmProvider)?.id,
      AlgorithmRegistry.kruskalId,
    );
    expect(find.byType(GraphCanvas), findsOneWidget);
    expect(find.text('Calcular árbol'), findsOneWidget);
    expect(find.text('Dijkstra'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });

  test('abrir otro algoritmo descarta resultado y método anteriores', () {
    final container = ProviderContainer();
    final graph = Grafo(
      nodos: {
        'A': const Nodo(
          id: 'A',
          nombre: 'A',
          colorValue: 0xFF7755AA,
          x: 0,
          y: 0,
        ),
      },
    );
    container.read(grafoProvider.notifier).cargarGrafo(graph);
    container
        .read(activeAlgorithmProvider.notifier)
        .selectById(AlgorithmRegistry.dijkstraId);
    container.read(graphPathRunProvider.notifier).setSource('A');
    container
        .read(graphPathRunProvider.notifier)
        .setMode(GraphPathMode.longestSimple);
    container
        .read(activeAlgorithmProvider.notifier)
        .selectById(AlgorithmRegistry.kruskalId);
    expect(container.read(grafoProvider).nodos.keys, ['A']);
    expect(
      container.read(graphPathRunProvider).mode,
      GraphPathMode.kruskalMinimum,
    );
    expect(container.read(graphPathRunProvider).sourceIsManual, isFalse);
    expect(container.read(graphPathRunProvider).computation, isNull);
    container.dispose();
  });

  testWidgets('Kruskal informa una arista incompatible sin panel ni selector', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1366, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    container
        .read(grafoProvider.notifier)
        .cargarGrafo(
          Grafo(
            nodos: {
              'A': const Nodo(
                id: 'A',
                nombre: 'A',
                colorValue: 0xFF7461AE,
                x: -80,
                y: 0,
              ),
              'B': const Nodo(
                id: 'B',
                nombre: 'B',
                colorValue: 0xFF7461AE,
                x: 80,
                y: 0,
              ),
            },
            conexiones: {
              'AB': const Conexion(
                id: 'AB',
                nodoOrigenId: 'A',
                nodoDestinoId: 'B',
                colorValue: 0xFF7461AE,
                direccion: Direccion.unidireccional,
                atributos: [
                  AtributoValor(atributoId: 'attr_valor', valor: '2'),
                ],
              ),
            },
          ),
        );
    container
        .read(activeAlgorithmProvider.notifier)
        .selectById(AlgorithmRegistry.kruskalId);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GraphEditorScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      container.read(activeAlgorithmProvider)?.id,
      AlgorithmRegistry.kruskalId,
    );
    expect(
      container.read(grafoProvider).conexiones['AB']?.direccion,
      Direccion.unidireccional,
    );
    expect(find.textContaining('Hay aristas dirigidas'), findsOneWidget);
    expect(find.text('Laboratorio de Kruskal'), findsNothing);
    expect(find.text('Dijkstra'), findsNothing);
    expect(find.text('Calcular árbol'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });

  testWidgets('Dijkstra usa el botón principal y extremos automáticos', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1366, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    container
        .read(grafoProvider.notifier)
        .cargarGrafo(
          const Grafo(
            nodos: {
              'B': Nodo(
                id: 'B',
                nombre: 'B',
                colorValue: 0xFF6754B2,
                x: 120,
                y: 0,
              ),
              'A': Nodo(
                id: 'A',
                nombre: 'A',
                colorValue: 0xFF6754B2,
                x: -120,
                y: 0,
              ),
            },
            conexiones: {
              'AB': Conexion(
                id: 'AB',
                nodoOrigenId: 'A',
                nodoDestinoId: 'B',
                colorValue: 0xFF6754B2,
                direccion: Direccion.unidireccional,
                atributos: [
                  AtributoValor(atributoId: 'attr_valor', valor: '0'),
                ],
              ),
            },
          ),
        );
    container
        .read(activeAlgorithmProvider.notifier)
        .selectById(AlgorithmRegistry.dijkstraId);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GraphEditorScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Origen: A → Destino: B'), findsOneWidget);
    expect(find.textContaining('detectados por grado'), findsOneWidget);
    await tester.tap(find.text('Calcular ruta'));
    await tester.pump();
    expect(container.read(graphPathRunProvider).computation?.value, 0);
    expect(find.textContaining('Costo mínimo: 0'), findsWidgets);
    expect(find.byType(GraphCanvas), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });

  testWidgets('menú contextual de Dijkstra permite corregir origen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    container
        .read(grafoProvider.notifier)
        .cargarGrafo(
          const Grafo(
            nodos: {
              'A': Nodo(
                id: 'A',
                nombre: 'A',
                colorValue: 0xFF6754B2,
                x: -100,
                y: 0,
              ),
              'B': Nodo(
                id: 'B',
                nombre: 'B',
                colorValue: 0xFF6754B2,
                x: 100,
                y: 0,
              ),
            },
          ),
        );
    container
        .read(activeAlgorithmProvider.notifier)
        .selectById(AlgorithmRegistry.dijkstraId);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GraphEditorScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final canvasCenter = tester.getCenter(find.byType(GraphCanvas));
    final click = await tester.startGesture(
      canvasCenter + const Offset(100, 0),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await click.up();
    await tester.pumpAndSettle();
    expect(find.text('Fijar como origen'), findsOneWidget);
    await tester.tap(find.text('Fijar como origen'));
    await tester.pumpAndSettle();
    expect(container.read(graphPathRunProvider).sourceId, 'B');
    expect(container.read(graphPathRunProvider).sourceIsManual, isTrue);
    expect(find.textContaining('selección personalizada'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });

  testWidgets('Kruskal ofrece mínimo y máximo sin origen ni destino', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1366, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    container
        .read(grafoProvider.notifier)
        .cargarGrafo(
          const Grafo(
            nodos: {
              'A': Nodo(
                id: 'A',
                nombre: 'A',
                colorValue: 0xFF8357AD,
                x: -100,
                y: 0,
              ),
              'B': Nodo(
                id: 'B',
                nombre: 'B',
                colorValue: 0xFF8357AD,
                x: 100,
                y: 0,
              ),
            },
          ),
        );
    container
        .read(activeAlgorithmProvider.notifier)
        .selectById(AlgorithmRegistry.kruskalId);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GraphEditorScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('2 componentes · bosque'), findsOneWidget);
    expect(find.textContaining('Origen:'), findsNothing);
    await tester.tap(find.text('Árbol mínimo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Árbol máximo').last);
    await tester.pumpAndSettle();
    expect(
      container.read(graphPathRunProvider).mode,
      GraphPathMode.kruskalMaximum,
    );
    await tester.tap(find.text('Calcular árbol'));
    await tester.pump();
    expect(container.read(graphPathRunProvider).computation?.componentCount, 2);
    expect(container.read(graphPathRunProvider).sourceId, isNull);
    expect(container.read(graphPathRunProvider).targetId, isNull);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });

  for (final width in [390.0, 768.0]) {
    testWidgets(
      'resultado de Kruskal cabe y se expande a ${width.toInt()} px',
      (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = ProviderContainer();
        container
            .read(grafoProvider.notifier)
            .cargarGrafo(
              const Grafo(
                nodos: {
                  'A': Nodo(
                    id: 'A',
                    nombre: 'A',
                    colorValue: 0xFF8357AD,
                    x: -80,
                    y: 0,
                  ),
                  'B': Nodo(
                    id: 'B',
                    nombre: 'B',
                    colorValue: 0xFF8357AD,
                    x: 80,
                    y: 0,
                  ),
                },
                conexiones: {
                  'AB': Conexion(
                    id: 'AB',
                    nodoOrigenId: 'A',
                    nodoDestinoId: 'B',
                    colorValue: 0xFF8357AD,
                    atributos: [
                      AtributoValor(atributoId: 'attr_valor', valor: '-2'),
                    ],
                  ),
                },
              ),
            );
        container
            .read(activeAlgorithmProvider.notifier)
            .selectById(AlgorithmRegistry.kruskalId);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: GraphEditorScreen()),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Calcular árbol'));
        await tester.pump();
        expect(container.read(graphPathRunProvider).computation?.value, -2);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Mostrar más detalles'));
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpWidget(const SizedBox());
        container.dispose();
      },
    );
  }

  testWidgets('Dijkstra acepta el mismo vértice como origen y destino', (
    tester,
  ) async {
    final container = ProviderContainer();
    container
        .read(grafoProvider.notifier)
        .cargarGrafo(
          const Grafo(
            nodos: {
              'A': Nodo(
                id: 'A',
                nombre: 'A',
                colorValue: 0xFF6754B2,
                x: 0,
                y: 0,
              ),
            },
          ),
        );
    container
        .read(activeAlgorithmProvider.notifier)
        .selectById(AlgorithmRegistry.dijkstraId);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GraphEditorScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Origen: A → Destino: A'), findsOneWidget);
    await tester.tap(find.text('Calcular ruta'));
    await tester.pump();
    expect(container.read(graphPathRunProvider).computation?.value, 0);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });

  for (final width in [390.0, 768.0, 1366.0]) {
    testWidgets('laboratorio cabe a ${width.toInt()} px', (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer();
      container
          .read(activeAlgorithmProvider.notifier)
          .selectById(AlgorithmRegistry.kruskalId);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: GraphEditorScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });
  }

  for (final width in [390.0, 768.0, 1366.0]) {
    testWidgets('teoría de Dijkstra cabe a ${width.toInt()} px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: GraphPathTheoryScreen.dijkstra()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
