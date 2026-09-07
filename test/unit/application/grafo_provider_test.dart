import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/application/providers/creacion_provider.dart';
import 'package:nodos/application/providers/grafo_provider.dart';
import 'package:nodos/application/providers/modo_provider.dart';
import 'package:nodos/domain/models/direccion.dart';

void main() {
  group('Application - GrafoNotifier Provider Tests', () {
    test('agregarConexion with Direccion.bidireccional creates 2 distinct lines with independent properties', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(grafoProvider.notifier);
      notifier.agregarNodo(0, 0, nombre: 'A');
      notifier.agregarNodo(200, 0, nombre: 'B');
      final nodeIds = notifier.state.nodos.keys.toList();

      final created = notifier.agregarConexion(
        nodeIds[0],
        nodeIds[1],
        Direccion.bidireccional,
      );

      expect(created.length, equals(2));
      expect(notifier.state.conexiones.length, equals(2));

      final conn1 = created[0];
      final conn2 = created[1];

      // Reverse direction endpoints
      expect(conn1.nodoOrigenId, equals(nodeIds[0]));
      expect(conn1.nodoDestinoId, equals(nodeIds[1]));
      expect(conn2.nodoOrigenId, equals(nodeIds[1]));
      expect(conn2.nodoDestinoId, equals(nodeIds[0]));

      // Distinct colors per direction line
      expect(conn1.colorValue, isNot(equals(conn2.colorValue)));
    });

    test('2D offsetControlX and offsetControlY curve control points remain independent for each line', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(grafoProvider.notifier);
      notifier.agregarNodo(0, 0, nombre: 'A');
      notifier.agregarNodo(200, 0, nombre: 'B');
      final nodeIds = notifier.state.nodos.keys.toList();

      final created = notifier.agregarConexion(
        nodeIds[0],
        nodeIds[1],
        Direccion.bidireccional,
      );

      final c1 = created[0];
      final c2 = created[1];

      // Update c1's curve offset
      notifier.actualizarConexion(
        c1.id,
        offsetControlX: 45.0,
        offsetControlY: -30.0,
      );

      expect(notifier.state.conexiones[c1.id]?.offsetControlX, equals(45.0));
      expect(notifier.state.conexiones[c1.id]?.offsetControlY, equals(-30.0));
      expect(notifier.state.conexiones[c2.id]?.offsetControlX, isNull);
      expect(notifier.state.conexiones[c2.id]?.offsetControlY, isNull);
    });

    test('Deleting one line in a bidirectional pair leaves the remaining line as a single directional connection', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(grafoProvider.notifier);
      notifier.agregarNodo(0, 0, nombre: 'A');
      notifier.agregarNodo(200, 0, nombre: 'B');
      final nodeIds = notifier.state.nodos.keys.toList();

      final created = notifier.agregarConexion(
        nodeIds[0],
        nodeIds[1],
        Direccion.bidireccional,
      );

      final c1 = created[0];
      final c2 = created[1];

      // Delete c1 (A -> B)
      notifier.eliminarConexion(c1.id);

      expect(notifier.state.conexiones.length, equals(1));
      expect(notifier.state.conexiones.containsKey(c1.id), isFalse);
      expect(notifier.state.conexiones.containsKey(c2.id), isTrue);
      expect(
        notifier.state.conexiones[c2.id]?.nodoOrigenId,
        equals(nodeIds[1]),
      );
      expect(
        notifier.state.conexiones[c2.id]?.nodoDestinoId,
        equals(nodeIds[0]),
      );
    });

    test('Connection constraints: max 1 pair between nodes and max 1 self-loop per node', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(grafoProvider.notifier);
      notifier.agregarNodo(0, 0, nombre: 'A');
      notifier.agregarNodo(200, 0, nombre: 'B');
      final nodeIds = notifier.state.nodos.keys.toList();

      // Create bidirectional pair between A and B (2 lines)
      final pair = notifier.agregarConexion(
        nodeIds[0],
        nodeIds[1],
        Direccion.bidireccional,
      );
      expect(pair.length, equals(2));

      // Attempting to add a 3rd connection between A and B is rejected
      final rejected3rd = notifier.agregarConexion(
        nodeIds[0],
        nodeIds[1],
        Direccion.unidireccional,
      );
      expect(rejected3rd, isEmpty);
      expect(notifier.state.conexiones.length, equals(2));

      // Add self-loop on Node A
      final loop1 = notifier.agregarConexion(
        nodeIds[0],
        nodeIds[0],
        Direccion.unidireccional,
      );
      expect(loop1.length, equals(1));

      // Attempting to add a 2nd self-loop on Node A is rejected
      final loop2 = notifier.agregarConexion(
        nodeIds[0],
        nodeIds[0],
        Direccion.unidireccional,
      );
      expect(loop2, isEmpty);
    });

    test('tipoObjetivoProvider defaults to TipoObjetivo.nodo and resets on mode change', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(tipoObjetivoProvider), equals(TipoObjetivo.nodo));

      container
          .read(tipoObjetivoProvider.notifier)
          .seleccionarTipo(TipoObjetivo.conexion);
      expect(
        container.read(tipoObjetivoProvider),
        equals(TipoObjetivo.conexion),
      );

      // Selecting a new mode resets target selection back to nodo
      container
          .read(modoActivoProvider.notifier)
          .seleccionarModo(ModoActivo.modificar);
      expect(container.read(tipoObjetivoProvider), equals(TipoObjetivo.nodo));
    });

    test('Undo and Redo stack history tracking works to clean board', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(grafoProvider.notifier);
      expect(notifier.puedeDeshacer, isFalse);
      expect(notifier.puedeRehacer, isFalse);

      notifier.agregarNodo(0, 0, nombre: 'A');
      expect(notifier.state.nodos.length, equals(1));
      expect(notifier.puedeDeshacer, isTrue);

      notifier.agregarNodo(200, 0, nombre: 'B');
      expect(notifier.state.nodos.length, equals(2));

      // Undo last addition
      notifier.deshacer();
      expect(notifier.state.nodos.length, equals(1));
      expect(notifier.puedeRehacer, isTrue);

      // Undo first addition -> clean board
      notifier.deshacer();
      expect(notifier.state.nodos.length, equals(0));

      // Redo both additions
      notifier.rehacer();
      expect(notifier.state.nodos.length, equals(1));
      notifier.rehacer();
      expect(notifier.state.nodos.length, equals(2));
    });

    test('estadoCreacionProvider tracks source and target node selection correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final creacionNotifier = container.read(estadoCreacionProvider.notifier);
      expect(
        container.read(estadoCreacionProvider).primerNodoSeleccionado,
        isNull,
      );

      creacionNotifier.seleccionarPrimerNodo('n1');
      expect(
        container.read(estadoCreacionProvider).primerNodoSeleccionado,
        equals('n1'),
      );

      creacionNotifier.seleccionarSegundoNodo('n2');
      expect(
        container.read(estadoCreacionProvider).segundoNodoSeleccionado,
        equals('n2'),
      );

      creacionNotifier.reset();
      expect(
        container.read(estadoCreacionProvider).primerNodoSeleccionado,
        isNull,
      );
      expect(
        container.read(estadoCreacionProvider).segundoNodoSeleccionado,
        isNull,
      );
    });

    test(
      'vaciarGrafo clears nodes and connections while preserving undo history',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(grafoProvider.notifier);
        final n1 = notifier.agregarNodo(0, 0, nombre: 'A');
        final n2 = notifier.agregarNodo(100, 100, nombre: 'B');
        notifier.agregarConexion(n1.id, n2.id);

        expect(notifier.state.nodos.length, equals(2));
        expect(notifier.state.conexiones.length, equals(1));

        // Vaciar grafo
        notifier.vaciarGrafo();

        expect(notifier.state.nodos, isEmpty);
        expect(notifier.state.conexiones, isEmpty);
        expect(notifier.puedeDeshacer, isTrue);

        // Undo restores the graph before vaciarGrafo
        notifier.deshacer();
        expect(notifier.state.nodos.length, equals(2));
        expect(notifier.state.conexiones.length, equals(1));
      },
    );
  });
}
