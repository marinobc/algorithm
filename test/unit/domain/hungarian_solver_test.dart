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

    test('Hungarian Assignment Solver correctly solves heavily unbalanced graph (2 origins x 9 destinations)', () {
      final origins = List.generate(
        2,
        (i) => Nodo(
          id: 'O${i + 1}',
          nombre: 'Origen ${i + 1}',
          colorValue: 0,
          x: 0,
          y: 0,
        ),
      );
      final destinations = List.generate(
        9,
        (j) => Nodo(
          id: 'D${j + 1}',
          nombre: 'Destino ${j + 1}',
          colorValue: 0,
          x: 100,
          y: 100,
        ),
      );

      // 2x9 cost matrix
      final costMatrix = [
        [10.0, 2.0, 8.0, 4.0, 6.0, 5.0, 9.0, 3.0, 7.0],
        [5.0, 9.0, 3.0, 7.0, 1.0, 8.0, 4.0, 6.0, 2.0],
      ];

      final problem = TransportationProblemData(
        origins: origins,
        destinations: destinations,
        supplies: List.filled(2, 1.0),
        demands: List.filled(9, 1.0),
        costMatrix: costMatrix,
        isBalanced: false,
        totalSupply: 2,
        totalDemand: 9,
      );

      final solver = HungarianAssignmentSolver();
      final result = solver.solve(
        problem: problem,
        method: TransportationMethod.hungarian,
        goal: OptimizationGoal.minimize,
      );

      expect(result.wasBalancedWithDummy, isTrue);
      expect(result.originLabels.length, equals(9));
      expect(result.destinationLabels.length, equals(9));
      // Optimal assignment for O1 -> D2 (cost 2) and O2 -> D5 (cost 1) => total 3.0
      expect(result.totalCost, equals(3.0));
      expect(result.allocationMatrix.length, equals(9));
      for (int i = 0; i < 9; i++) {
        expect(result.allocationMatrix[i].length, equals(9));
      }
    });

    test('Hungarian Assignment Solver correctly solves heavily unbalanced graph (9 origins x 2 destinations)', () {
      final origins = List.generate(
        9,
        (i) => Nodo(
          id: 'O${i + 1}',
          nombre: 'Origen ${i + 1}',
          colorValue: 0,
          x: 0,
          y: 0,
        ),
      );
      final destinations = List.generate(
        2,
        (j) => Nodo(
          id: 'D${j + 1}',
          nombre: 'Destino ${j + 1}',
          colorValue: 0,
          x: 100,
          y: 100,
        ),
      );

      final costMatrix = List.generate(
        9,
        (i) => [(i + 1) * 1.0, (10 - i) * 1.0],
      );

      final problem = TransportationProblemData(
        origins: origins,
        destinations: destinations,
        supplies: List.filled(9, 1.0),
        demands: List.filled(2, 1.0),
        costMatrix: costMatrix,
        isBalanced: false,
        totalSupply: 9,
        totalDemand: 2,
      );

      final solver = HungarianAssignmentSolver();
      final result = solver.solve(
        problem: problem,
        method: TransportationMethod.hungarian,
        goal: OptimizationGoal.minimize,
      );

      expect(result.wasBalancedWithDummy, isTrue);
      expect(result.originLabels.length, equals(9));
      expect(result.destinationLabels.length, equals(9));
      // Optimal min cost: O1 -> D1 (cost 1.0) and O9 -> D2 (cost 2.0) => total 3.0
      expect(result.totalCost, equals(3.0));
    });
  });
}
