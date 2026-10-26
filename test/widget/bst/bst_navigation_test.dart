import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/bst/ui/bst_theory_screen.dart';
import 'package:nodos/ui/dialogs/algorithm_selection_dialog.dart';

void main() {
  testWidgets('selector principal abre directamente el laboratorio BST', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AlgorithmSelectionScreen())),
    );
    await tester.scrollUntilVisible(
      find.text('Árboles BST'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Árboles BST'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Árboles BST'));
    await tester.pumpAndSettle();
    expect(find.text('Pizarra BST'), findsOneWidget);
    expect(find.text('Guía de uso'), findsOneWidget);
  });

  testWidgets('la página teórica conserva su acceso al laboratorio', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: BstTheoryScreen())),
    );
    await tester.scrollUntilVisible(
      find.text('Explorar el laboratorio BST'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Explorar el laboratorio BST'));
    await tester.tap(find.text('Explorar el laboratorio BST'));
    await tester.pumpAndSettle();
    expect(find.text('Pizarra BST'), findsOneWidget);
  });
}
