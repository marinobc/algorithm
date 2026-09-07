import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/assignment/domain/models/assignment_models.dart';
import 'package:nodos/algorithms/assignment/domain/services/assignment_validator.dart';
import 'package:nodos/algorithms/assignment/domain/solvers/hungarian_solver.dart';
import 'package:nodos/domain/highlights/algorithm_highlight.dart';
import 'package:nodos/domain/models/conexion.dart';
import 'package:nodos/domain/models/direccion.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/domain/models/nodo.dart';

void main() {
  group('Transportation & Assignation Validator Tests', () {
    test(
      'Detects origin and destination nodes correctly in valid bipartite graph',
      () {
        final o1 = const Nodo(
          id: 'O1',
          nombre: 'Origen 1',
          colorValue: 0,
          x: 0,
          y: 0,
        );
        final o2 = const Nodo(
          id: 'O2',
          nombre: 'Origen 2',
          colorValue: 0,
          x: 0,
          y: 0,
        );
        final d1 = const Nodo(
          id: 'D1',
          nombre: 'Destino 1',
          colorValue: 0,
          x: 100,
          y: 100,
        );
        final d2 = const Nodo(
          id: 'D2',
          nombre: 'Destino 2',
          colorValue: 0,
          x: 100,
          y: 100,
        );

        final c1 = const Conexion(
          id: 'c1',
          nodoOrigenId: 'O1',
          nodoDestinoId: 'D1',
          colorValue: 0,
          direccion: Direccion.unidireccional,
        );
        final c2 = const Conexion(
          id: 'c2',
          nodoOrigenId: 'O2',
          nodoDestinoId: 'D2',
          colorValue: 0,
          direccion: Direccion.unidireccional,
        );

        final grafo = Grafo(
          nodos: {'O1': o1, 'O2': o2, 'D1': d1, 'D2': d2},
          conexiones: {'c1': c1, 'c2': c2},
        );

        final result = TransportationValidator.validate(grafo);
        expect(result.isValid, isTrue);
        expect(result.origins.map((n) => n.id), containsAll(['O1', 'O2']));
        expect(result.destinations.map((n) => n.id), containsAll(['D1', 'D2']));
      },
    );

    test('Fails validation and returns error message when origin has incoming connection', () {
      final o1 = const Nodo(
        id: 'O1',
        nombre: 'Planta A',
        colorValue: 0,
        x: 0,
        y: 0,
      );
      final o2 = const Nodo(
        id: 'O2',
        nombre: 'Planta B',
        colorValue: 0,
        x: 0,
        y: 0,
      );
      final d1 = const Nodo(
        id: 'D1',
        nombre: 'Destino 1',
        colorValue: 0,
        x: 100,
        y: 100,
      );

      // Connection from O1 to O2, and O2 to D1 (making O2 an intermediate node with incoming & outgoing connections)
      final c1 = const Conexion(
        id: 'c1',
        nodoOrigenId: 'O1',
        nodoDestinoId: 'O2',
        colorValue: 0,
        direccion: Direccion.unidireccional,
      );
      final c2 = const Conexion(
        id: 'c2',
        nodoOrigenId: 'O2',
        nodoDestinoId: 'D1',
        colorValue: 0,
        direccion: Direccion.unidireccional,
      );

      final grafo = Grafo(
        nodos: {'O1': o1, 'O2': o2, 'D1': d1},
        conexiones: {'c1': c1, 'c2': c2},
      );

      final result = TransportationValidator.validate(grafo);
      expect(result.isValid, isFalse);
      expect(
        result.errorMessage,
        startsWith('No se puede aplicar el algoritmo, modifique'),
      );
    });

    test('Fails validation when graph has bidirectional connections', () {
      final o1 = const Nodo(
        id: 'O1',
        nombre: 'Origen A',
        colorValue: 0,
        x: 0,
        y: 0,
      );
      final d1 = const Nodo(
        id: 'D1',
        nombre: 'Destino A',
        colorValue: 0,
        x: 100,
        y: 100,
      );

      final c1 = const Conexion(
        id: 'c1',
        nodoOrigenId: 'O1',
        nodoDestinoId: 'D1',
        colorValue: 0,
        direccion: Direccion.bidireccional,
      );

      final grafo = Grafo(nodos: {'O1': o1, 'D1': d1}, conexiones: {'c1': c1});

      final result = TransportationValidator.validate(grafo);
      expect(result.isValid, isFalse);
      expect(
        result.errorMessage,
        contains('No se puede aplicar el algoritmo, modifique'),
      );
    });
  });

  group('Hungarian Assignment Solver Tests', () {
    test('Hungarian Assignment Solver finds optimal cost (2x2)', () {
      final o1 = const Nodo(id: 'O1', nombre: 'A', colorValue: 0, x: 0, y: 0);
      final o2 = const Nodo(id: 'O2', nombre: 'B', colorValue: 0, x: 0, y: 0);
      final d1 = const Nodo(
        id: 'D1',
        nombre: 'X',
        colorValue: 0,
        x: 100,
        y: 100,
      );
      final d2 = const Nodo(
        id: 'D2',
        nombre: 'Y',
        colorValue: 0,
        x: 100,
        y: 100,
      );

      final problem = TransportationProblemData(
        origins: [o1, o2],
        destinations: [d1, d2],
        supplies: [1, 1],
        demands: [1, 1],
        costMatrix: [
          [9.0, 2.0],
          [4.0, 6.0],
        ],
        isBalanced: true,
        totalSupply: 2,
        totalDemand: 2,
      );

      final solver = HungarianAssignmentSolver();
      final result = solver.solve(
        problem: problem,
        method: TransportationMethod.hungarian,
        goal: OptimizationGoal.minimize,
      );

      // Optimal min assignment: O1 -> Y (cost 2) and O2 -> X (cost 4) => total 6
      expect(result.totalCost, equals(6.0));
    });

    test(
      'Pads rectangular matrix (2x1) to square size with 0-cost dummy entries',
      () {
        final o1 = const Nodo(
          id: 'O1',
          nombre: 'O1',
          colorValue: 0,
          x: 0,
          y: 0,
        );
        final o2 = const Nodo(
          id: 'O2',
          nombre: 'O2',
          colorValue: 0,
          x: 0,
          y: 0,
        );
        final d1 = const Nodo(
          id: 'D1',
          nombre: 'D1',
          colorValue: 0,
          x: 100,
          y: 100,
        );

        // 2 origins, 1 destination (rectangular 2x1 matrix)
        final problem = TransportationProblemData(
          origins: [o1, o2],
          destinations: [d1],
          supplies: [1.0, 1.0],
          demands: [1.0],
          costMatrix: [
            [5.0],
            [3.0],
          ],
          isBalanced: false,
          totalSupply: 2,
          totalDemand: 1,
        );

        final solver = HungarianAssignmentSolver();
        final result = solver.solve(
          problem: problem,
          method: TransportationMethod.hungarian,
          goal: OptimizationGoal.minimize,
        );

        expect(result.wasBalancedWithDummy, isTrue);
        expect(
          result.destinationLabels.length,
          equals(2),
        ); // Padded with dummy destination
      },
    );

    test(
      'AlgorithmHighlight captures highlighted nodes and connections correctly',
      () {
        final highlight = AlgorithmHighlight(
          algorithmName: 'Algoritmo de Asignación',
          nodeIds: {'O1', 'D1'},
          connectionIds: {'c1'},
        );

        expect(highlight.isNotEmpty, isTrue);
        expect(highlight.isNodeHighlighted('O1'), isTrue);
        expect(highlight.isConnectionHighlighted('c1'), isTrue);
        expect(highlight.isNodeHighlighted('O2'), isFalse);
      },
    );

    test('Hungarian Assignment Solver handles Maximization on incomplete bipartite matrix correctly', () {
      final o1 = const Nodo(
        id: 'O1',
        nombre: 'Nodo 1',
        colorValue: 0,
        x: 0,
        y: 0,
      );
      final o2 = const Nodo(
        id: 'O2',
        nombre: 'Nodo 2',
        colorValue: 0,
        x: 0,
        y: 0,
      );
      final o3 = const Nodo(
        id: 'O3',
        nombre: 'Nodo 4',
        colorValue: 0,
        x: 0,
        y: 0,
      );
      final d1 = const Nodo(
        id: 'D1',
        nombre: 'Nodo 3',
        colorValue: 0,
        x: 100,
        y: 100,
      );
      final d2 = const Nodo(
        id: 'D2',
        nombre: 'Nodo 5',
        colorValue: 0,
        x: 100,
        y: 100,
      );

      // Graph: 3 origins, 2 destinations with missing connections (double.infinity)
      final problem = TransportationProblemData(
        origins: [o1, o2, o3],
        destinations: [d1, d2],
        supplies: [1, 1, 1],
        demands: [1, 1],
        costMatrix: [
          [1.0, double.infinity],
          [1.0, 1.0],
          [double.infinity, 1.0],
        ],
        isBalanced: false,
        totalSupply: 3,
        totalDemand: 2,
      );

      final solver = HungarianAssignmentSolver();
      final result = solver.solve(
        problem: problem,
        method: TransportationMethod.hungarian,
        goal: OptimizationGoal.maximize,
      );

      // Max cost for real valid assignments should be 2.0 (not 1,000,000+)
      expect(result.totalCost, equals(2.0));
    });
  });
}
