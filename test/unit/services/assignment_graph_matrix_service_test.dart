import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/assignment/domain/services/assignment_graph_matrix_service.dart';
import 'package:nodos/domain/models/atributo.dart';
import 'package:nodos/domain/models/conexion.dart';
import 'package:nodos/domain/models/direccion.dart';
import 'package:nodos/domain/models/grafo.dart';

void main() {
  group('AssignmentGraphMatrixService Unit Tests', () {
    test('format formats integer and decimal values correctly', () {
      expect(AssignmentGraphMatrixService.format(10.0), equals('10'));
      expect(AssignmentGraphMatrixService.format(15.5), equals('15.50'));
    });

    test('findConnectionCost finds cost attribute on existing connection', () {
      const graph = Grafo(
        conexiones: {
          'c1': Conexion(
            id: 'c1',
            nodoOrigenId: 'o1',
            nodoDestinoId: 'd1',
            colorValue: 0xFF2196F3,
            direccion: Direccion.unidireccional,
            atributos: [
              AtributoValor(atributoId: 'attr_valor', valor: '25'),
            ],
          ),
        },
      );

      final cost = AssignmentGraphMatrixService.findConnectionCost(
        graph,
        'o1',
        'd1',
        'attr_valor',
      );

      expect(cost, equals('25'));
    });

    test('buildGraphFromInput converts AssignmentMatrixInput to Grafo correctly',
        () {
      const emptyGraph = Grafo();
      const input = AssignmentMatrixInput(
        originIds: ['o1', 'o2'],
        destinationIds: ['d1', 'd2'],
        originNames: ['Origen A', 'Origen B'],
        destinationNames: ['Destino X', 'Destino Y'],
        costs: [
          [10.0, 20.0],
          [30.0, 40.0],
        ],
        originRole: 'origen',
        destinationRole: 'destino',
        defaultOriginColor: 0xFF2196F3,
        defaultDestinationColor: 0xFF4CAF50,
        costAttributeId: 'attr_valor',
        defaultTypeAlgorithm: 'assignment',
        idPrefix: 'asg',
      );

      final result = AssignmentGraphMatrixService.buildGraphFromInput(
        emptyGraph,
        input,
      );

      expect(result.nodos.length, equals(4));
      expect(result.nodos['o1']?.nombre, equals('Origen A'));
      expect(result.nodos['d1']?.nombre, equals('Destino X'));
      expect(result.conexiones.length, equals(4));
      expect(result.tipoAlgoritmo, equals('assignment'));
    });

    test('buildGraphFromInput ignores dummy fictitious nodes and connections',
        () {
      const emptyGraph = Grafo();
      const input = AssignmentMatrixInput(
        originIds: ['o1', 'asg_dummy_origin'],
        destinationIds: ['d1', 'd2'],
        originNames: ['Origen A', 'Ficticio'],
        destinationNames: ['Destino X', 'Destino Y'],
        costs: [
          [10.0, 20.0],
          [0.0, 0.0],
        ],
        originRole: 'origen',
        destinationRole: 'destino',
        defaultOriginColor: 0xFF2196F3,
        defaultDestinationColor: 0xFF4CAF50,
        costAttributeId: 'attr_valor',
        defaultTypeAlgorithm: 'assignment',
        idPrefix: 'asg',
      );

      final result = AssignmentGraphMatrixService.buildGraphFromInput(
        emptyGraph,
        input,
      );

      expect(result.nodos.containsKey('asg_dummy_origin'), isFalse);
      expect(result.nodos.length, equals(3));
      expect(result.conexiones.length, equals(2));
    });
  });
}
