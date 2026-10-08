import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/application/providers/grafo_provider.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/domain/models/nodo.dart';
import 'package:nodos/ui/canvas/graph_canvas.dart';
import 'package:nodos/ui/dialogs/delete_confirmation_dialog.dart';

void main() {
  testWidgets('secondary mouse click deletes only the targeted node', (
    tester,
  ) async {
    final container = ProviderContainer();
    container
        .read(grafoProvider.notifier)
        .cargarGrafo(
          const Grafo(nodos: {'n1': Nodo(id: 'n1', x: 0, y: 0, colorValue: 0)}),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: GraphCanvas())),
      ),
    );
    await tester.pumpAndSettle();

    final nodePosition = tester.getCenter(find.byType(GraphCanvas));
    final nodeClick = await tester.startGesture(
      nodePosition,
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await nodeClick.up();
    await tester.pumpAndSettle();

    expect(find.byType(DeleteConfirmationDialog), findsOneWidget);
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(container.read(grafoProvider).nodos, isEmpty);

    final backgroundClick = await tester.startGesture(
      nodePosition,
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await backgroundClick.up();
    await tester.pumpAndSettle();
    expect(find.byType(DeleteConfirmationDialog), findsNothing);

    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
}
