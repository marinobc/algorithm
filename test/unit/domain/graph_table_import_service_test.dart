import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/domain/models/direccion.dart';
import 'package:nodos/domain/services/graph_table_import_service.dart';

void main() {
  group('GraphTableImportService', () {
    const matrix = ',A,B,C\nA,0,5,2\nB,5,0,3\nC,2,3,0';

    test('creates one undirected connection per node pair', () {
      final graph = GraphTableImportService.fromAdjacencyMatrix(
        matrix,
        directed: false,
      );

      expect(graph.nodos.length, 3);
      expect(graph.conexiones.length, 3);
      expect(graph.nodos.values.map((node) => node.nombre), ['A', 'B', 'C']);
      expect(
        graph.conexiones.values.every(
          (connection) => connection.direccion == Direccion.ninguna,
        ),
        isTrue,
      );
      expect(
        graph.conexiones.values
            .expand((connection) => connection.atributos)
            .map((attribute) => attribute.valor),
        containsAll(['5', '2', '3']),
      );
    });

    test('preserves both directions in a directed matrix', () {
      final graph = GraphTableImportService.fromAdjacencyMatrix(
        ',A,B\nA,0,4\nB,7,0',
        directed: true,
      );

      expect(graph.conexiones.length, 2);
      expect(
        graph.conexiones.values.every(
          (connection) => connection.direccion == Direccion.unidireccional,
        ),
        isTrue,
      );
    });

    test('accepts a tab-separated matrix pasted from a spreadsheet', () {
      final graph = GraphTableImportService.fromAdjacencyMatrix(
        '\tA\tB\nA\t0\t4\nB\t4\t0',
        directed: false,
      );

      expect(graph.nodos.length, 2);
      expect(graph.conexiones.length, 1);
      expect(graph.nodos.values.map((node) => node.nombre), ['A', 'B']);
    });

    test('rejects matrices whose dimensions do not match', () {
      expect(
        () => GraphTableImportService.fromAdjacencyMatrix(
          ',A,B\nA,0,1',
          directed: false,
        ),
        throwsA(isA<GraphTableImportException>()),
      );
    });

    test('creates an ordered bipartite graph from a rectangular table', () {
      final graph = GraphTableImportService.fromCostMatrix(
        rowNames: ['Origen 1', 'Origen 2'],
        columnNames: ['Destino 1', 'Destino 2', 'Destino 3'],
        values: const [
          [4, 2, 7],
          [3, null, 5],
        ],
      );

      expect(graph.nodos.length, 5);
      expect(graph.conexiones.length, 5);
      expect(
        graph.nodos.values
            .where((node) => node.id.startsWith('fila_'))
            .every((node) => node.x < 0),
        isTrue,
      );
      expect(
        graph.nodos.values
            .where((node) => node.id.startsWith('columna_'))
            .every((node) => node.x > 0),
        isTrue,
      );
    });
  });
}
