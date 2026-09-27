import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/ui/screens/welcome_explanation_screen.dart';
import 'package:nodos/ui/screens/widgets/welcome/welcome_basics_section.dart';
import 'package:nodos/ui/screens/widgets/welcome/welcome_examples_grid.dart';
import 'package:nodos/ui/screens/widgets/welcome/welcome_footer_section.dart';
import 'package:nodos/ui/screens/widgets/welcome/welcome_hero_section.dart';

void main() {
  group('WelcomeExplanationScreen Modular Widgets Tests', () {
    testWidgets('WelcomeHeroSection renders titles and buttons correctly',
        (tester) async {
      bool openEditorCalled = false;
      bool scrollToExamplesCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WelcomeHeroSection(
              onOpenEditor: () => openEditorCalled = true,
              onScrollToExamples: () => scrollToExamplesCalled = true,
            ),
          ),
        ),
      );

      expect(
        find.text('¿Qué son los Algoritmos y para qué sirven?'),
        findsOneWidget,
      );
      expect(find.text('Abrir Editor de Grafos'), findsOneWidget);
      expect(find.text('Ver 3 Ejemplos Prácticos'), findsOneWidget);

      await tester.tap(find.text('Abrir Editor de Grafos'));
      expect(openEditorCalled, isTrue);

      await tester.tap(find.text('Ver 3 Ejemplos Prácticos'));
      expect(scrollToExamplesCalled, isTrue);
    });

    testWidgets('WelcomeBasicsSection renders input, process, output cards',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WelcomeBasicsSection(),
            ),
          ),
        ),
      );

      expect(find.text('CONCEPTO CLAVE'), findsOneWidget);
      expect(find.text('Entrada'), findsOneWidget);
      expect(find.text('Proceso'), findsOneWidget);
      expect(find.text('Salida'), findsOneWidget);
      expect(find.text('Preciso'), findsOneWidget);
      expect(find.text('Finito'), findsOneWidget);
    });

    testWidgets('WelcomeExamplesGrid renders 3 practical example cards',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WelcomeExamplesGrid(),
            ),
          ),
        ),
      );

      expect(find.text('Navegación y Rutas GPS'), findsOneWidget);
      expect(find.text('Búsqueda y Recomendaciones'), findsOneWidget);
      expect(find.text('Organización y Clasificación'), findsOneWidget);
    });

    testWidgets('WelcomeFooterSection renders copyright and editor link',
        (tester) async {
      bool openEditorCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WelcomeFooterSection(
              onOpenEditor: () => openEditorCalled = true,
            ),
          ),
        ),
      );

      expect(
        find.text('Editor de Nodos y Algoritmos de Grafos'),
        findsOneWidget,
      );
      expect(find.text('Editor de Grafos'), findsOneWidget);

      await tester.tap(find.text('Editor de Grafos'));
      expect(openEditorCalled, isTrue);
    });

    testWidgets('WelcomeExplanationScreen renders full screen cleanly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeExplanationScreen(),
        ),
      );

      expect(find.byType(WelcomeExplanationScreen), findsOneWidget);
      expect(find.byType(WelcomeHeroSection), findsOneWidget);
      expect(find.byType(WelcomeBasicsSection), findsOneWidget);
    });
  });
}
