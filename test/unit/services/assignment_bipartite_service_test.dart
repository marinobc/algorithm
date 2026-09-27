import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/assignment/domain/services/assignment_bipartite_service.dart';
import 'package:nodos/domain/models/atributo.dart';
import 'package:nodos/domain/models/conexion.dart';
import 'package:nodos/domain/models/direccion.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/domain/models/nodo.dart';

void main() {
  group('AssignmentBipartiteService Unit Tests', () {
    test('getConnectionWeight retrieves correct numeric value from connection',
        () {
      const origNode = Nodo(
        id: 'o1',
        x: 0,
        y: 0,
        colorValue: 0xFF2196F3,
        nombre: 'Origen 1',
      );
      const destNode = Nodo(
        id: 'd1',
        x: 100,
        y: 100,
        colorValue: 0xFF2196F3,
        nombre: 'Destino 1',
      );

      const connection = Conexion(
        id: 'c1',
        nodoOrigenId: 'o1',
        nodoDestinoId: 'd1',
        colorValue: 0xFF2196F3,
        direccion: Direccion.unidireccional,
        atributos: [AtributoValor(atributoId: 'attr_valor', valor: '42.5')],
      );

      final grafo = Grafo(
        nodos: {'o1': origNode, 'd1': destNode},
        conexiones: {'c1': connection},
      );

      final weight = AssignmentBipartiteService.getConnectionWeight(
        grafo,
        'o1',
        'd1',
      );

      expect(weight, equals(42.5));
    });

    test('getConnectionWeight returns null when connection does not exist',
        () {
      const origNode = Nodo(
        id: 'o1',
        x: 0,
        y: 0,
        colorValue: 0xFF2196F3,
        nombre: 'Origen 1',
      );
      const destNode = Nodo(
        id: 'd1',
        x: 100,
        y: 100,
        colorValue: 0xFF2196F3,
        nombre: 'Destino 1',
      );

      final grafo = Grafo(
        nodos: {'o1': origNode, 'd1': destNode},
        conexiones: const {},
      );

      final weight = AssignmentBipartiteService.getConnectionWeight(
        grafo,
        'o1',
        'd1',
      );

      expect(weight, isNull);
    });

    test('buildCostMatrix generates 2D matrix matching origins and destinations',
        () {
      const o1 = Nodo(id: 'o1', x: 0, y: 0, colorValue: 0xFF2196F3, nombre: 'O1');
      const o2 = Nodo(id: 'o2', x: 0, y: 50, colorValue: 0xFF2196F3, nombre: 'O2');
      const d1 = Nodo(id: 'd1', x: 100, y: 0, colorValue: 0xFF2196F3, nombre: 'D1');
      const d2 = Nodo(id: 'd2', x: 100, y: 50, colorValue: 0xFF2196F3, nombre: 'D2');

      const c11 = Conexion(
        id: 'c11',
        nodoOrigenId: 'o1',
        nodoDestinoId: 'd1',
        colorValue: 0xFF2196F3,
        atributos: [AtributoValor(atributoId: 'attr_valor', valor: '10')],
      );
      const c22 = Conexion(
        id: 'c22',
        nodoOrigenId: 'o2',
        nodoDestinoId: 'd2',
        colorValue: 0xFF2196F3,
        atributos: [AtributoValor(atributoId: 'attr_valor', valor: '20')],
      );

      final grafo = Grafo(
        nodos: {'o1': o1, 'o2': o2, 'd1': d1, 'd2': d2},
        conexiones: {'c11': c11, 'c22': c22},
      );

      final matrix = AssignmentBipartiteService.buildCostMatrix(
        grafo,
        [o1, o2],
        [d1, d2],
      );

      expect(matrix.length, equals(2));
      expect(matrix[0].length, equals(2));
      expect(matrix[0][0], equals(10.0));
      expect(matrix[0][1], isNull);
      expect(matrix[1][0], isNull);
      expect(matrix[1][1], equals(20.0));
    });

    test('formatCellText formats integer and decimal values appropriately',
        () {
      expect(AssignmentBipartiteService.formatCellText(null), equals('-'));
      expect(AssignmentBipartiteService.formatCellText(10.0), equals('10'));
      expect(AssignmentBipartiteService.formatCellText(10.5), equals('10.5'));
    });
  });
}
