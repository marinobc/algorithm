import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/domain/services/algorithms/sorting_algorithms.dart';
import 'package:nodos/ui/dialogs/sorting_usage_dialog.dart';

void main() {
  for (final algorithm in [
    const SelectionSortAlgorithm(),
    const InsertionSortAlgorithm(),
  ]) {
    testWidgets(
      'shows numbered guide for ${algorithm.name} on narrow screens',
      (tester) async {
        tester.view.physicalSize = const Size(390, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: SortingUsageDialog(algorithm: algorithm)),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(algorithm.name), findsOneWidget);
        expect(find.text('1. Prepara los datos'), findsOneWidget);
        expect(find.text('4. Lee el resultado'), findsOneWidget);
      },
    );
  }
}
