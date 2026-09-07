import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/application/providers/grafo_provider.dart';
import 'package:nodos/domain/models/atributo.dart';
import 'package:nodos/domain/models/conexion.dart';
import 'package:nodos/domain/models/direccion.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/domain/models/nodo.dart';
import 'package:nodos/domain/services/adjacency_matrix_service.dart';
import 'package:nodos/domain/services/graph_storage_service.dart';
import 'package:nodos/ui/widgets/canvas_controls_fabs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Grafo JSON Serialization & Deserialization', () {
    test('Grafo -> toJson -> fromJson restores exact graph state', () {
      const n1 = Nodo(
        id: 'n1',
        nombre: 'Nodo A',
        colorValue: 0xFF2196F3,
        x: 100,
        y: 150,
      );
      const n2 = Nodo(
        id: 'n2',
        nombre: 'Nodo B',
        colorValue: 0xFFFF9800,
        x: 300,
        y: 350,
      );

      const conn = Conexion(
        id: 'c1',
        nodoOrigenId: 'n1',
        nodoDestinoId: 'n2',
        colorValue: 0xFF4CAF50,
        direccion: Direccion.unidireccional,
        atributos: [AtributoValor(atributoId: 'attr_valor', valor: '10')],
      );

      final originalGraph = Grafo(
        nodos: {'n1': n1, 'n2': n2},
        conexiones: {'c1': conn},
        atributosGlobales: const [Atributo(id: 'attr_valor', nombre: 'Valor')],
      );

      final jsonMap = originalGraph.toJson();
      final restoredGraph = Grafo.fromJson(jsonMap);

      expect(restoredGraph.nodos.length, equals(2));
      expect(restoredGraph.conexiones.length, equals(1));

      final restoredN1 = restoredGraph.nodos['n1'];
      expect(restoredN1?.nombre, equals('Nodo A'));
      expect(restoredN1?.x, equals(100));

      final restoredC1 = restoredGraph.conexiones['c1'];
      expect(restoredC1?.direccion, equals(Direccion.unidireccional));
      expect(restoredC1?.atributos.first.valor, equals('10'));
    });

    test('GraphStorageService exportToJson and importFromJson roundtrip', () {
      const n1 = Nodo(
        id: 'n1',
        nombre: 'Alpha',
        colorValue: 0xFF000000,
        x: 0,
        y: 0,
      );
      final original = Grafo(nodos: {'n1': n1});

      final jsonStr = GraphStorageService.exportToJson(original);
      expect(jsonStr, contains('"nombre": "Alpha"'));

      final imported = GraphStorageService.importFromJson(jsonStr);
      expect(imported.nodos.containsKey('n1'), isTrue);
      expect(imported.nodos['n1']?.nombre, equals('Alpha'));
    });
  });

  group('AdjacencyMatrixService Tests', () {
    test('Empty graph returns empty matrix data', () {
      const emptyGraph = Grafo();
      final data = AdjacencyMatrixService.calculateMatrix(emptyGraph);

      expect(data.isEmpty, isTrue);
      expect(data.toCsv(), equals(''));
    });

    test('Graph with 2 connected nodes produces 2x2 binary and weighted matrix', () {
      const n1 = Nodo(
        id: 'n1',
        nombre: 'A',
        colorValue: 0xFF000000,
        x: 0,
        y: 0,
      );
      const n2 = Nodo(
        id: 'n2',
        nombre: 'B',
        colorValue: 0xFF000000,
        x: 100,
        y: 100,
      );
      const conn = Conexion(
        id: 'c1',
        nodoOrigenId: 'n1',
        nodoDestinoId: 'n2',
        colorValue: 0xFF000000,
        direccion: Direccion.unidireccional,
        atributos: [AtributoValor(atributoId: 'attr_valor', valor: '5')],
      );

      final graph = Grafo(
        nodos: {'n1': n1, 'n2': n2},
        conexiones: {'c1': conn},
      );

      final data = AdjacencyMatrixService.calculateMatrix(graph);
      expect(data.nodes.length, equals(2));
      expect(data.labels, equals(['A', 'B']));

      // A -> B (row 0, col 1) should be connected with value '1' and weight '5'
      final cellAtoB = data.binaryMatrix[0][1];
      expect(cellAtoB.isConnected, isTrue);
      expect(cellAtoB.binaryValue, equals('1'));
      expect(cellAtoB.weightedValue, equals('5'));

      // B -> A (row 1, col 0) should NOT be connected for a unidirection A -> B edge
      final cellBtoA = data.binaryMatrix[1][0];
      expect(cellBtoA.isConnected, isFalse);
      expect(cellBtoA.binaryValue, equals('0'));

      // CSV export
      final csvBinary = data.toCsv(weighted: false);
      expect(csvBinary, contains('Origen/Destino,"A","B"'));
      expect(csvBinary, contains('"A","0","1"'));
      expect(csvBinary, contains('"B","0","0"'));

      final csvWeighted = data.toCsv(weighted: true);
      expect(csvWeighted, contains('"A","0","5"'));
    });
  });

  group('GraphStorageService SharedPreferences Tests', () {
    test('saveGraphSlot & deleteSavedGraph operate cleanly', () async {
      SharedPreferences.setMockInitialValues({});
      const graph = Grafo();

      final initial = await GraphStorageService.getSavedGraphs();
      expect(initial, isEmpty);

      final savedItem = await GraphStorageService.saveGraphSlot(
        'Test Slot',
        graph,
      );

      final afterSave = await GraphStorageService.getSavedGraphs();
      expect(afterSave.length, equals(1));
      expect(afterSave.first.nombre, equals('Test Slot'));

      // Test overrideSavedGraphSlot
      const updatedGraph = Grafo(
        nodos: {'n1': Nodo(id: 'n1', x: 0, y: 0, colorValue: 0xFF123456)},
      );
      await GraphStorageService.overrideSavedGraphSlot(
        savedItem.id,
        'Test Slot Updated',
        updatedGraph,
      );

      final afterOverride = await GraphStorageService.getSavedGraphs();
      expect(afterOverride.length, equals(1));
      expect(afterOverride.first.nombre, equals('Test Slot Updated'));
      expect(afterOverride.first.nodoCount, equals(1));

      await GraphStorageService.deleteSavedGraph(savedItem.id);
      final afterDelete = await GraphStorageService.getSavedGraphs();
      expect(afterDelete, isEmpty);
    });
  });

  group('Control Widgets Tests', () {
    testWidgets('CanvasControlsFabs renders center FAB and responds to click', (
      tester,
    ) async {
      bool resetClicked = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CanvasControlsFabs(onResetView: () => resetClicked = true),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.center_focus_strong_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.center_focus_strong_rounded));
      await tester.pump();
      expect(resetClicked, isTrue);
    });
  });

  group('GrafoNotifier cargarGrafo Test', () {
    test('cargarGrafo updates riverpod state and records undo state', () {
      final container = ProviderContainer();
      final notifier = container.read(grafoProvider.notifier);

      expect(container.read(grafoProvider).nodos, isEmpty);

      const n1 = Nodo(
        id: 'n1',
        nombre: 'Loaded Node',
        colorValue: 0xFF123456,
        x: 10,
        y: 20,
      );
      final newGraph = Grafo(nodos: {'n1': n1});

      notifier.cargarGrafo(newGraph);

      expect(container.read(grafoProvider).nodos.length, equals(1));
      expect(
        container.read(grafoProvider).nodos['n1']?.nombre,
        equals('Loaded Node'),
      );

      // Loading graph starts with clean undo history (no false unsaved changes)
      expect(notifier.puedeDeshacer, isFalse);
    });
  });
}
