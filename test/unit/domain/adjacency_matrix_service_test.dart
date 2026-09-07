import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/domain/models/conexion.dart';
import 'package:nodos/domain/models/direccion.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/domain/models/nodo.dart';
import 'package:nodos/domain/services/adjacency_matrix_service.dart';

void main() {
  group('Domain - AdjacencyMatrixService', () {
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
        y: 0,
      );

      const conn = Conexion(
        id: 'c1',
        nodoOrigenId: 'n1',
        nodoDestinoId: 'n2',
        colorValue: 0xFF000000,
        direccion: Direccion.unidireccional,
      );

      final graph = Grafo(
        nodos: {'n1': n1, 'n2': n2},
        conexiones: {'c1': conn},
      );

      final data = AdjacencyMatrixService.calculateMatrix(graph);
      expect(data.labels, equals(['A', 'B']));
      expect(data.matrix[0][1].isConnected, isTrue);
      expect(data.matrix[1][0].isConnected, isFalse);
      expect(data.rowDegrees[0], equals(1));
      expect(data.colDegrees[1], equals(1));
    });
  });
}
