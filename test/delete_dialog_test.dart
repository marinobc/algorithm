import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/application/providers/edicion_provider.dart';
import 'package:nodos/application/providers/grafo_provider.dart';
import 'package:nodos/domain/models/conexion.dart';
import 'package:nodos/domain/models/direccion.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/domain/models/nodo.dart';
import 'package:nodos/ui/dialogs/delete_confirmation_dialog.dart';
import 'package:nodos/ui/theme/app_theme.dart';
import 'package:nodos/ui/widgets/edit_panel.dart';

void main() {
  group('DeleteConfirmationDialog Unit & Widget Tests', () {
    testWidgets('renders node deletion title and connection warning list', (tester) async {
      const conn = Conexion(
        id: 'c1',
        nodoOrigenId: 'n1',
        nodoDestinoId: 'n2',
        direccion: Direccion.unidireccional,
        colorValue: 0xFF2196F3,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: DeleteConfirmationDialog(
              isNode: true,
              nodeName: 'Nodo Alfa',
              connectionsToDelete: const [conn],
              nodeNames: const {'n1': 'Nodo Alfa', 'n2': 'Nodo Beta'},
            ),
          ),
        ),
      );

      // Verify title & confirmation prompt
      expect(find.text('Eliminar Nodo'), findsOneWidget);
      expect(find.text('¿Está seguro de que desea eliminar el nodo Nodo Alfa?'), findsOneWidget);

      // Verify connection warning text
      expect(find.text('También se eliminarán 1 conexiones:'), findsOneWidget);
      expect(find.text('• Nodo Alfa → Nodo Beta (Sin valores)'), findsOneWidget);
    });

    testWidgets('tapping cancel pops false', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<bool>(
                    context: context,
                    builder: (_) => const DeleteConfirmationDialog(
                      isNode: true,
                      nodeName: 'Nodo X',
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(DeleteConfirmationDialog), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.byType(DeleteConfirmationDialog), findsNothing);
      expect(result, isFalse);
    });

    testWidgets('tapping delete pops true', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<bool>(
                    context: context,
                    builder: (_) => const DeleteConfirmationDialog(
                      isNode: true,
                      nodeName: 'Nodo Y',
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(DeleteConfirmationDialog), findsOneWidget);

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(find.byType(DeleteConfirmationDialog), findsNothing);
      expect(result, isTrue);
    });
  });

  group('EditPanel Node Deletion Integration Tests', () {
    testWidgets('confirming node deletion removes node & connections from graph', (tester) async {
      final initialGraph = Grafo(
        nodos: {
          'n1': const Nodo(id: 'n1', x: 0, y: 0, nombre: 'Nodo 1', colorValue: 0xFF2196F3),
          'n2': const Nodo(id: 'n2', x: 100, y: 0, nombre: 'Nodo 2', colorValue: 0xFF4CAF50),
        },
        conexiones: {
          'c1': const Conexion(
            id: 'c1',
            nodoOrigenId: 'n1',
            nodoDestinoId: 'n2',
            direccion: Direccion.unidireccional,
            colorValue: 0xFF2196F3,
          ),
        },
      );

      final container = ProviderContainer(
        overrides: [
          grafoProvider.overrideWith(() => _TestGrafoNotifier(initialGraph)),
        ],
      );

      // Select node n1 for editing
      container.read(estadoEdicionProvider.notifier).seleccionarNodo('n1');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: EditPanel(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify EditPanel is showing node properties for n1
      expect(find.byType(EditPanel), findsOneWidget);
      expect(find.text('Propiedades del Nodo'), findsOneWidget);

      // Tap trash / delete button
      final trashButton = find.byIcon(Icons.delete_outline_rounded);
      expect(trashButton, findsOneWidget);
      await tester.tap(trashButton);
      await tester.pumpAndSettle();

      // Verify DeleteConfirmationDialog is visible with connection warning
      expect(find.byType(DeleteConfirmationDialog), findsOneWidget);
      expect(find.text('También se eliminarán 1 conexiones:'), findsOneWidget);

      // Tap Eliminar in confirmation dialog
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();

      // Verify node n1 and connection c1 are removed from graph state
      final updatedGraph = container.read(grafoProvider);
      expect(updatedGraph.nodos.containsKey('n1'), isFalse);
      expect(updatedGraph.nodos.containsKey('n2'), isTrue);
      expect(updatedGraph.conexiones.containsKey('c1'), isFalse);

      // Verify selection is cleared and EditPanel closes
      expect(container.read(estadoEdicionProvider).itemSeleccionadoId, isNull);
    });

    testWidgets('canceling node deletion retains node and connections', (tester) async {
      final initialGraph = Grafo(
        nodos: {
          'n1': const Nodo(id: 'n1', x: 0, y: 0, nombre: 'Nodo 1', colorValue: 0xFF2196F3),
          'n2': const Nodo(id: 'n2', x: 100, y: 0, nombre: 'Nodo 2', colorValue: 0xFF4CAF50),
        },
        conexiones: {
          'c1': const Conexion(
            id: 'c1',
            nodoOrigenId: 'n1',
            nodoDestinoId: 'n2',
            direccion: Direccion.unidireccional,
            colorValue: 0xFF2196F3,
          ),
        },
      );

      final container = ProviderContainer(
        overrides: [
          grafoProvider.overrideWith(() => _TestGrafoNotifier(initialGraph)),
        ],
      );

      container.read(estadoEdicionProvider.notifier).seleccionarNodo('n1');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: EditPanel(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap trash button
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      // Tap Cancel in confirmation dialog (target the text inside DeleteConfirmationDialog)
      await tester.tap(
        find.descendant(
          of: find.byType(DeleteConfirmationDialog),
          matching: find.text('Cancelar'),
        ),
      );
      await tester.pumpAndSettle();

      // Verify graph state is untouched
      final currentGraph = container.read(grafoProvider);
      expect(currentGraph.nodos.containsKey('n1'), isTrue);
      expect(currentGraph.conexiones.containsKey('c1'), isTrue);
      expect(container.read(estadoEdicionProvider).itemSeleccionadoId, equals('n1'));
    });
  });
}

class _TestGrafoNotifier extends GrafoNotifier {
  final Grafo _initial;
  _TestGrafoNotifier(this._initial);

  @override
  Grafo build() => _initial;
}
