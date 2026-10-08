import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/northwest/domain/models/northwest_models.dart';
import 'package:nodos/algorithms/northwest/domain/services/northwest_graph_matrix_service.dart';
import 'package:nodos/domain/models/grafo.dart';

void main() {
  group('NorthwestGraphMatrixService Unit Tests', () {
    test('buildGraphFromInput converts TransportationInput to Grafo correctly',
        () {
      const emptyGraph = Grafo();
      final input = TransportationInput(
        originIds: ['o1', 'o2'],
        destinationIds: ['d1', 'd2'],
        originNames: ['Origen A', 'Origen B'],
        destinationNames: ['Destino X', 'Destino Y'],
        costs: [
          [10.0, 20.0],
          [30.0, 40.0],
        ],
        supplies: [100.0, 200.0],
        demands: [150.0, 150.0],
        objective: TransportationObjective.minimize,
      );

      final result = NorthwestGraphMatrixService.buildGraphFromInput(
        emptyGraph,
        input,
      );

      expect(result.nodos.length, equals(4));
      expect(result.nodos['o1']?.nombre, equals('Origen A'));
      expect(result.nodos['o1']?.cantidad, equals(100.0));
      expect(result.nodos['d1']?.nombre, equals('Destino X'));
      expect(result.nodos['d1']?.cantidad, equals(150.0));

      expect(result.conexiones.length, equals(4));
      expect(result.tipoAlgoritmo, equals('northwest'));
    });

    test(
        'buildGraphFromInput ignores dummy fictitious nodes when building graph',
        () {
      const emptyGraph = Grafo();
      final input = TransportationInput(
        originIds: ['o1', 'nw_dummy_origin'],
        destinationIds: ['d1', 'd2'],
        originNames: ['Origen A', 'Ficticio'],
        destinationNames: ['Destino X', 'Destino Y'],
        costs: [
          [10.0, 20.0],
          [0.0, 0.0],
        ],
        supplies: [100.0, 50.0],
        demands: [75.0, 75.0],
        objective: TransportationObjective.minimize,
      );

      final result = NorthwestGraphMatrixService.buildGraphFromInput(
        emptyGraph,
        input,
      );

      expect(result.nodos.containsKey('nw_dummy_origin'), isFalse);
      expect(result.nodos.length, equals(3));
    });
  });
}
