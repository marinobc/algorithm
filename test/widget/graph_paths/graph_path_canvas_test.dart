import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/core/algorithm_registry.dart';
import 'package:nodos/application/providers/grafo_provider.dart';
import 'package:nodos/domain/models/direccion.dart';
import 'package:nodos/ui/screens/graph_editor_screen.dart';

void main() {
  testWidgets('Kruskal construye el grafo en el canvas compartido', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1366, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    container
        .read(activeAlgorithmProvider.notifier)
        .selectById(AlgorithmRegistry.kruskalId);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GraphEditorScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(220, 420));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(510, 510));
    await tester.pumpAndSettle();
    expect(container.read(grafoProvider).nodos.length, 2);
    expect(
      container
          .read(grafoProvider)
          .nodos
          .values
          .map((node) => node.colorValue)
          .toSet()
          .length,
      2,
    );
    await tester.dragFrom(const Offset(220, 420), const Offset(290, 90));
    await tester.pumpAndSettle();
    expect(container.read(grafoProvider).conexiones.length, 1);
    expect(
      container.read(grafoProvider).conexiones.values.single.direccion,
      Direccion.ninguna,
    );
    expect(find.text('Peso de la arista'), findsOneWidget);
    final input = find.byType(TextField).last;
    await tester.enterText(input, '-3');
    await tester.tap(find.text('Confirmar peso'));
    await tester.pumpAndSettle();
    expect(
      container
          .read(grafoProvider)
          .conexiones
          .values
          .single
          .atributos
          .where((a) => a.atributoId == 'attr_valor')
          .single
          .valor,
      '-3',
    );
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
}
