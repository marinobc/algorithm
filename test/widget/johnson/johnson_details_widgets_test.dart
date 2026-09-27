import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/johnson/domain/models/johnson_models.dart';
import 'package:nodos/algorithms/johnson/ui/widgets/johnson_schedule_table.dart';
import 'package:nodos/algorithms/johnson/ui/widgets/johnson_step_by_step_widget.dart';

void main() {
  group('Johnson Modular Sub-Widgets Tests', () {
    const nodeA = JohnsonNodeResult(
      nodeId: 'n1',
      nodeName: 'Nodo A',
      earlyTime: 0.0,
      lateTime: 0.0,
      slack: 0.0,
      isCritical: true,
    );
    const nodeB = JohnsonNodeResult(
      nodeId: 'n2',
      nodeName: 'Nodo B',
      earlyTime: 5.0,
      lateTime: 5.0,
      slack: 0.0,
      isCritical: true,
    );

    const edge1 = JohnsonEdgeResult(
      connectionId: 'c1',
      sourceId: 'n1',
      targetId: 'n2',
      duration: 5.0,
      totalSlack: 0.0,
      freeSlack: 0.0,
      isCritical: true,
    );

    const result = JohnsonResult(
      nodeResults: [nodeA, nodeB],
      edgeResults: [edge1],
      totalDuration: 5.0,
      criticalNodeIds: {'n1', 'n2'},
      criticalConnectionIds: {'c1'},
      criticalPathSequence: ['Nodo A', 'Nodo B'],
    );

    testWidgets(
      'JohnsonScheduleTable renders node early/late times and edge data table',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: JohnsonScheduleTable(result: result),
              ),
            ),
          ),
        );

        expect(
          find.text('Tabla de Tiempos y Holguras por Nodo'),
          findsOneWidget,
        );
        expect(
          find.text('Desglose de Conexiones / Actividades'),
          findsOneWidget,
        );
        expect(find.text('Nodo A'), findsOneWidget);
        expect(find.text('Nodo B'), findsOneWidget);
        expect(find.text('Crítico'), findsWidgets);
        expect(find.text('Ruta Crítica'), findsOneWidget);
      },
    );

    testWidgets(
      'JohnsonStepByStepWidget renders step-by-step cards and chips',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: JohnsonStepByStepWidget(result: result),
              ),
            ),
          ),
        );

        expect(
          find.text('Resolución Paso a Paso — Algoritmo de Johnson / CPM'),
          findsOneWidget,
        );
        expect(find.text('1. Pasada Adelante (ES/EF)'), findsWidgets);
      },
    );
  });
}
