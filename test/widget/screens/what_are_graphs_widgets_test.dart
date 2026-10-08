import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/ui/screens/what_are_graphs_screen.dart';
import 'package:nodos/ui/screens/widgets/theory/graph_anatomy_section.dart';
import 'package:nodos/ui/screens/widgets/theory/graph_applications_section.dart';
import 'package:nodos/ui/screens/widgets/theory/graph_theory_hero_section.dart';
import 'package:nodos/ui/screens/widgets/theory/graph_types_section.dart';

void main() {
  group('WhatAreGraphsScreen Modular Sub-Widgets Tests', () {
    testWidgets('GraphTheoryHeroSection renders title and button correctly',
        (tester) async {
      bool openEditorCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GraphTheoryHeroSection(
              onOpenEditor: () => openEditorCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('¿Qué son los Grafos?'), findsOneWidget);
      expect(find.text('Abrir Editor de Grafos'), findsOneWidget);

      await tester.tap(find.text('Abrir Editor de Grafos'));
      expect(openEditorCalled, isTrue);
    });

    testWidgets('GraphAnatomySection renders anatomy cards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GraphAnatomySection(),
            ),
          ),
        ),
      );

      expect(find.text('Anatomía Básica de un Grafo'), findsOneWidget);
      expect(find.text('1. Nodos o Vértices'), findsOneWidget);
      expect(find.text('2. Aristas o Enlaces'), findsOneWidget);
      expect(find.text('3. Pesos o Costos'), findsOneWidget);
    });

    testWidgets('GraphTypesSection renders directed and undirected descriptions',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GraphTypesSection(),
            ),
          ),
        ),
      );

      expect(find.text('Grafos Dirigidos (Digrafos)'), findsOneWidget);
      expect(find.text('Grafos No Dirigidos'), findsOneWidget);
    });

    testWidgets('GraphApplicationsSection renders practical use cases',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GraphApplicationsSection(),
            ),
          ),
        ),
      );

      expect(find.text('Mapas y transporte'), findsOneWidget);
      expect(find.text('Internet'), findsOneWidget);
      expect(find.text('Recomendaciones'), findsOneWidget);
    });

    testWidgets('WhatAreGraphsScreen renders full screen cleanly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WhatAreGraphsScreen(),
        ),
      );

      expect(find.byType(WhatAreGraphsScreen), findsOneWidget);
      expect(find.byType(GraphTheoryHeroSection), findsOneWidget);
      expect(find.byType(GraphAnatomySection), findsOneWidget);
    });
  });
}
