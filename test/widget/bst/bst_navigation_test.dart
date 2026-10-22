import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/ui/dialogs/algorithm_selection_dialog.dart';

void main() {
  testWidgets('selector principal abre teoría y después laboratorio BST', (
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
    expect(find.text('Árboles binarios de búsqueda'), findsOneWidget);
    await tester.tap(find.text('Probar árboles BST'));
    await tester.pumpAndSettle();
    expect(find.text('Pizarra BST'), findsOneWidget);
    expect(find.text('Guía de uso'), findsOneWidget);
  });
}
