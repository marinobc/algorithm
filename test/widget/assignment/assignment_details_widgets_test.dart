import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/assignment/domain/models/assignment_models.dart';
import 'package:nodos/algorithms/assignment/ui/widgets/assignment_allocation_matrix_table.dart';
import 'package:nodos/algorithms/assignment/ui/widgets/assignment_step_by_step_widget.dart';
import 'package:nodos/domain/models/nodo.dart';

void main() {
  group('Assignment Modular Widgets Tests', () {
    const orig1 = Nodo(
      id: 'o1',
      x: 0,
      y: 0,
      colorValue: 0xFF2196F3,
      nombre: 'Origen A',
    );
    const orig2 = Nodo(
      id: 'o2',
      x: 0,
      y: 100,
      colorValue: 0xFF2196F3,
      nombre: 'Origen B',
    );
    const dest1 = Nodo(
      id: 'd1',
      x: 200,
      y: 0,
      colorValue: 0xFF4CAF50,
      nombre: 'Destino X',
    );
    const dest2 = Nodo(
      id: 'd2',
      x: 200,
      y: 100,
      colorValue: 0xFF4CAF50,
      nombre: 'Destino Y',
    );

    const problem = TransportationProblemData(
      origins: [orig1, orig2],
      destinations: [dest1, dest2],
      supplies: [1.0, 1.0],
      demands: [1.0, 1.0],
      costMatrix: [
        [10.0, 20.0],
        [15.0, 5.0],
      ],
      isBalanced: true,
      totalSupply: 2.0,
      totalDemand: 2.0,
    );

    const step1 = StepExplanation(
      stepNumber: 1,
      title: 'Reducción por filas',
      description: 'Se resta el menor de cada fila',
      rowVectorAlpha: [10.0, 5.0],
    );

    const step2 = StepExplanation(
      stepNumber: 2,
      title: 'Asignación Óptima',
      description: 'Se realiza la asignación final de costo mínimo',
    );

    final result = TransportationResult(
      allocationMatrix: [
        [1.0, 0.0],
        [0.0, 1.0],
      ],
      totalCost: 15.0,
      method: TransportationMethod.hungarian,
      goal: OptimizationGoal.minimize,
      wasBalancedWithDummy: false,
      originLabels: ['Origen A', 'Origen B'],
      destinationLabels: ['Destino X', 'Destino Y'],
      supplies: [1.0, 1.0],
      demands: [1.0, 1.0],
      costMatrix: [
        [10.0, 20.0],
        [15.0, 5.0],
      ],
      steps: [step1, step2],
    );

    testWidgets(
      'AssignmentAllocationMatrixTable renders matrix and assignment pair chips',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AssignmentAllocationMatrixTable(
                  result: result,
                  problem: problem,
                ),
              ),
            ),
          ),
        );

        expect(
          find.text('Matriz Final de Asignaciones Óptimas'),
          findsOneWidget,
        );
        expect(find.text('Desglose de Pares Asignados'), findsOneWidget);
        expect(find.text('Origen A'), findsWidgets);
        expect(find.text('Destino X'), findsWidgets);
        expect(find.text('Origen B ➔ Destino Y (Costo: 5)'), findsOneWidget);
      },
    );

    testWidgets(
      'AssignmentStepByStepWidget renders steps and tabs correctly',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AssignmentStepByStepWidget(result: result),
              ),
            ),
          ),
        );

        expect(
          find.text('Resolución Paso a Paso — Método Húngaro'),
          findsOneWidget,
        );
        expect(find.text('• Reducción por filas'), findsOneWidget);
      },
    );
  });
}
