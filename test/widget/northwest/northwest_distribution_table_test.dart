import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/northwest/domain/models/northwest_models.dart';
import 'package:nodos/algorithms/northwest/ui/widgets/northwest_circuit_view.dart';
import 'package:nodos/algorithms/northwest/ui/widgets/northwest_distribution_table.dart';
import 'package:nodos/algorithms/northwest/ui/widgets/northwest_labeled_matrix.dart';
import 'package:nodos/algorithms/northwest/ui/widgets/northwest_potential_table.dart';
import 'package:nodos/algorithms/northwest/ui/widgets/northwest_step_by_step_widget.dart';

void main() {
  group('Northwest Modular Sub-Widgets Tests', () {
    final problem = TransportationInput(
      originIds: ['o1', 'o2'],
      destinationIds: ['d1', 'd2'],
      originNames: ['Origen 1', 'Origen 2'],
      destinationNames: ['Destino 1', 'Destino 2'],
      costs: [
        [5.0, 10.0],
        [15.0, 20.0],
      ],
      supplies: [100.0, 200.0],
      demands: [150.0, 150.0],
      objective: TransportationObjective.minimize,
    );

    const baseCell1 = TransportCell(0, 0);
    const baseCell2 = TransportCell(1, 0);
    const baseCell3 = TransportCell(1, 1);

    final iteration = ModiIteration(
      number: 1,
      allocations: [
        [100.0, 0.0],
        [50.0, 150.0],
      ],
      basis: {baseCell1, baseCell2, baseCell3},
      rowPotentials: [0.0, 10.0],
      columnPotentials: [5.0, 10.0],
      opportunityMatrix: [
        [5.0, 10.0],
        [15.0, 20.0],
      ],
      deltas: [
        [0.0, 0.0],
        [0.0, 0.0],
      ],
      enteringCell: TransportCell(0, 1),
      circuit: [TransportCell(0, 1), TransportCell(0, 0), TransportCell(1, 0)],
      alpha: 25.0,
      objectiveValue: 3750.0,
    );

    final result = NorthwestResult(
      initialAllocations: [
        [100.0, 0.0],
        [50.0, 150.0],
      ],
      initialBasis: {baseCell1, baseCell2, baseCell3},
      initialObjectiveValue: 3750.0,
      allocations: [
        [100.0, 0.0],
        [50.0, 150.0],
      ],
      basis: {baseCell1, baseCell2, baseCell3},
      objectiveValue: 3750.0,
      iterations: [iteration],
    );

    testWidgets(
      'NorthwestDistributionTable renders origin and destination headers correctly',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NorthwestDistributionTable.fromResult(
                problem: problem,
                result: result,
              ),
            ),
          ),
        );

        expect(find.text('Origen'), findsOneWidget);
        expect(find.text('Origen 1'), findsOneWidget);
        expect(find.text('Origen 2'), findsOneWidget);
        expect(find.text('Destino 1'), findsOneWidget);
        expect(find.text('Destino 2'), findsOneWidget);
        expect(find.text('Oferta'), findsOneWidget);
        expect(find.text('Demanda'), findsOneWidget);
      },
    );

    testWidgets(
      'NorthwestPotentialTable renders row and column potentials correctly',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NorthwestPotentialTable(
                problem: problem,
                iteration: iteration,
              ),
            ),
          ),
        );

        expect(find.text('Potenciales MODI'), findsOneWidget);
      },
    );

    testWidgets(
      'NorthwestLabeledMatrix renders title and matrix cell values',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NorthwestLabeledMatrix(
                title: 'Matriz de Costos Relativos',
                problem: problem,
                values: iteration.opportunityMatrix,
              ),
            ),
          ),
        );

        expect(find.text('Matriz de Costos Relativos'), findsOneWidget);
      },
    );

    testWidgets(
      'NorthwestCircuitView renders circuit alpha value and step sequence',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NorthwestCircuitView(
                problem: problem,
                iteration: iteration,
              ),
            ),
          ),
        );

        expect(find.text('Circuito cerrado · α = 25'), findsOneWidget);
      },
    );

    testWidgets(
      'NorthwestStepByStepWidget renders step carousel and choice chips',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: NorthwestStepByStepWidget(
                  problem: problem,
                  result: result,
                ),
              ),
            ),
          ),
        );

        expect(find.text('Resolución paso a paso'), findsOneWidget);
        expect(find.text('1. Solución Inicial'), findsOneWidget);
      },
    );
  });
}
