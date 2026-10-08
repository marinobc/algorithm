import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/application/providers/edicion_provider.dart';
import 'package:nodos/application/providers/grafo_provider.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/domain/models/nodo.dart';
import 'package:nodos/ui/widgets/edit_panel.dart';
import 'package:nodos/ui/widgets/edit_panel/edit_panel_footer_actions.dart';
import 'package:nodos/ui/widgets/edit_panel/edit_panel_header.dart';

class _TestEdicionNotifier extends EdicionNotifier {
  final EstadoEdicion _initial;
  _TestEdicionNotifier(this._initial);

  @override
  EstadoEdicion build() => _initial;
}

class _TestGrafoNotifier extends GrafoNotifier {
  final Grafo _initial;
  _TestGrafoNotifier(this._initial);

  @override
  Grafo build() => _initial;
}

void main() {
  group('EditPanel Modular Sub-Widgets Tests', () {
    testWidgets('EditPanelHeader renders title and responds to close click',
        (tester) async {
      bool closeClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditPanelHeader(
              title: 'Propiedades del Nodo',
              onClose: () => closeClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Propiedades del Nodo'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      expect(closeClicked, isTrue);
    });

    testWidgets('EditPanelFooterActions renders Delete, Cancel, Save buttons',
        (tester) async {
      bool deleteCalled = false;
      bool cancelCalled = false;
      bool saveCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditPanelFooterActions(
              onDelete: () => deleteCalled = true,
              onCancel: () => cancelCalled = true,
              onSave: () => saveCalled = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      expect(deleteCalled, isTrue);

      await tester.tap(find.text('Cancelar'));
      expect(cancelCalled, isTrue);

      await tester.tap(find.text('Guardar'));
      expect(saveCalled, isTrue);
    });

    testWidgets('EditPanel renders cleanly when node is selected',
        (tester) async {
      const sampleNode = Nodo(
        id: 'n1',
        x: 100,
        y: 100,
        colorValue: 0xFF2196F3,
        nombre: 'Nodo A',
      );
      final sampleGrafo = Grafo(nodos: {'n1': sampleNode});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            estadoEdicionProvider.overrideWith(
              () => _TestEdicionNotifier(
                const EstadoEdicion(itemSeleccionadoId: 'n1', esNodo: true),
              ),
            ),
            grafoProvider.overrideWith(() => _TestGrafoNotifier(sampleGrafo)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: EditPanel(),
            ),
          ),
        ),
      );

      expect(find.byType(EditPanel), findsOneWidget);
      expect(find.byType(EditPanelHeader), findsOneWidget);
      expect(find.byType(EditPanelFooterActions), findsOneWidget);
    });
  });
}
