import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/ui/screens/johnson_algo_screen.dart';
import 'package:nodos/ui/screens/widgets/johnson/johnson_hero_section.dart';
import 'package:nodos/ui/screens/widgets/johnson/johnson_workflow_section.dart';

void main() {
  group('JohnsonAlgoScreen Modular Widgets Tests', () {
    testWidgets('JohnsonHeroSection renders title and badge correctly',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: JohnsonHeroSection(),
            ),
          ),
        ),
      );

      expect(find.text('Tiempos de Ida y Regreso'), findsOneWidget);
      expect(find.text('Algoritmo de Johnson'), findsOneWidget);
    });

    testWidgets('JohnsonWorkflowSection renders 2 passes of algorithm',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: JohnsonWorkflowSection(),
            ),
          ),
        ),
      );

      expect(find.text('REGLAS DE CÁLCULO PASO A PASO'), findsOneWidget);
      expect(find.text('Pasada de Ida (De Ida)'), findsOneWidget);
      expect(find.text('Pasada de Regreso (De Regreso)'), findsOneWidget);
    });

    testWidgets('JohnsonAlgoScreen renders full screen cleanly',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: JohnsonAlgoScreen(),
          ),
        ),
      );

      expect(find.byType(JohnsonAlgoScreen), findsOneWidget);
      expect(find.byType(JohnsonHeroSection), findsOneWidget);
      expect(find.byType(JohnsonWorkflowSection), findsOneWidget);
    });
  });
}
