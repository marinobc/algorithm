import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/domain/models/conexion.dart';
import 'package:nodos/domain/models/direccion.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/domain/models/nodo.dart';
import 'package:nodos/domain/services/graph_validation.dart';

void main() {
  group('Domain - GraphValidation', () {
    test('Single node graph is connected', () {
      const grafo = Grafo(
        nodos: {'n1': Nodo(id: 'n1', colorValue: 0xFF2196F3, x: 0, y: 0)},
      );

      final disconnected = GraphValidation.findDisconnectedNodes(grafo);
      expect(disconnected, isEmpty);
    });

    test('Isolated node in multi-node graph is detected as disconnected', () {
      const grafo = Grafo(
        nodos: {
          'n1': Nodo(id: 'n1', colorValue: 0xFF2196F3, x: 0, y: 0),
          'n2': Nodo(id: 'n2', colorValue: 0xFF2196F3, x: 200, y: 0),
          'n3': Nodo(id: 'n3', colorValue: 0xFF2196F3, x: 400, y: 0),
        },
        conexiones: {
          'c1': Conexion(
            id: 'c1',
            nodoOrigenId: 'n1',
            nodoDestinoId: 'n2',
            colorValue: 0xFF9E9E9E,
            direccion: Direccion.ninguna,
          ),
        },
      );

      final disconnected = GraphValidation.findDisconnectedNodes(grafo);
      expect(disconnected, contains('n3'));
      expect(disconnected.length, equals(1));
    });
  });
}
