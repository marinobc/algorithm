import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/graph_paths/ui/graph_path_matrix_screen.dart';
import 'package:nodos/application/providers/grafo_provider.dart';
import 'package:nodos/domain/models/atributo.dart';

void main() {
  testWidgets('la matriz mantiene A→B y B→A en celdas separadas', (
    tester,
  ) async {
    final container = ProviderContainer();
    final notifier = container.read(grafoProvider.notifier);
    final a = notifier.agregarNodo(0, 0, nombre: 'A');
    final b = notifier.agregarNodo(200, 0, nombre: 'B');
    final ba = notifier.agregarArcoDirigidoIndependiente(b.id, a.id).single;
    final ab = notifier.agregarArcoDirigidoIndependiente(a.id, b.id).single;
    notifier.actualizarConexion(
      ba.id,
      atributos: const [AtributoValor(atributoId: 'attr_valor', valor: '7')],
    );
    notifier.actualizarConexion(
      ab.id,
      atributos: const [AtributoValor(atributoId: 'attr_valor', valor: '2')],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GraphPathMatrixScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final table = tester.widget<DataTable>(find.byType(DataTable));
    expect((table.rows[0].cells[2].child as Text).data, '2');
    expect((table.rows[1].cells[1].child as Text).data, '7');
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
}
