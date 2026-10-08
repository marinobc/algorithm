import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/ui/screens/assignment_algo_screen.dart';
import 'package:nodos/ui/screens/widgets/assignment/hungarian_hero_section.dart';
import 'package:nodos/ui/screens/widgets/assignment/hungarian_steps_section.dart';

void main() {
  group('AssignmentAlgoScreen Modular Widgets Tests', () {
    testWidgets('HungarianHeroSection renders title and badge correctly',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HungarianHeroSection(),
            ),
          ),
        ),
      );

      expect(find.text('Asignación Óptima 1 a 1'), findsOneWidget);
      expect(find.text('Algoritmo de Asignación'), findsOneWidget);
    });

    testWidgets('HungarianStepsSection renders 4 Hungarian algorithm steps',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HungarianStepsSection(),
            ),
          ),
        ),
      );

      expect(find.text('GENERACIÓN Y SELECCIÓN DE CEROS'), findsOneWidget);
      expect(find.text('Paso 1'), findsOneWidget);
      expect(find.text('Reducción por Filas'), findsOneWidget);
      expect(find.text('Paso 2'), findsOneWidget);
      expect(find.text('Reducción por Columnas'), findsOneWidget);
      expect(find.text('Paso 3'), findsOneWidget);
      expect(find.text('Cubrir Ceros con Líneas'), findsOneWidget);
      expect(find.text('Paso 4'), findsOneWidget);
      expect(find.text('Asignar Parejas Óptimas'), findsOneWidget);
    });

    testWidgets('AssignmentAlgoScreen renders full screen cleanly',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AssignmentAlgoScreen(),
          ),
        ),
      );

      expect(find.byType(AssignmentAlgoScreen), findsOneWidget);
      expect(find.byType(HungarianHeroSection), findsOneWidget);
      expect(find.byType(HungarianStepsSection), findsOneWidget);
    });
  });
}
