import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/assignment/domain/models/assignment_models.dart';
import 'package:nodos/algorithms/assignment/domain/solvers/hungarian_solver.dart';
import 'package:nodos/domain/highlights/algorithm_highlight.dart';
import 'package:nodos/domain/models/nodo.dart';

void main() {
  group('Domain - Hungarian Assignment Solver', () {
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

      // Max cost for real valid assignments should be 2.0
      expect(result.totalCost, equals(2.0));
    });
  });
}
