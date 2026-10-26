import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/graph_paths/providers/graph_path_run_provider.dart';
import 'package:nodos/algorithms/core/algorithm_registry.dart';
import 'package:nodos/application/providers/grafo_provider.dart';
import 'package:nodos/domain/models/atributo.dart';
import 'package:nodos/domain/models/conexion.dart';
import 'package:nodos/domain/models/direccion.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/domain/models/nodo.dart';

void main() {
  test(
    'ejecuta Dijkstra con extremos propuestos y conserva elecciones manuales',
    () {
      final container = ProviderContainer();
      final graph = Grafo(
        nodos: {
          for (final id in ['C', 'A', 'B'])
            id: Nodo(id: id, nombre: id, colorValue: 0xFF6754B2, x: 0, y: 0),
        },
        conexiones: {
          'AB': const Conexion(
            id: 'AB',
            nodoOrigenId: 'A',
            nodoDestinoId: 'B',
            colorValue: 0xFF6754B2,
            direccion: Direccion.unidireccional,
            atributos: [AtributoValor(atributoId: 'attr_valor', valor: '0')],
          ),
          'BC': const Conexion(
            id: 'BC',
            nodoOrigenId: 'B',
            nodoDestinoId: 'C',
            colorValue: 0xFF6754B2,
            direccion: Direccion.unidireccional,
            atributos: [AtributoValor(atributoId: 'attr_valor', valor: '2')],
          ),
        },
      );
      container.read(grafoProvider.notifier).cargarGrafo(graph);
      container
          .read(activeAlgorithmProvider.notifier)
          .selectById(AlgorithmRegistry.dijkstraId);
      final runner = container.read(graphPathRunProvider.notifier);
      expect(container.read(graphPathRunProvider).sourceId, 'A');
      expect(container.read(graphPathRunProvider).targetId, 'C');
      expect(container.read(graphPathRunProvider).inferredFromTopology, isTrue);
      runner.run(container.read(grafoProvider));
      expect(container.read(graphPathRunProvider).computation?.value, 2);
      expect(
        container.read(graphPathRunProvider).currentStep?.title,
        contains('mínimo'),
      );

      runner.setSource('B');
      expect(container.read(graphPathRunProvider).sourceIsManual, isTrue);
      container
          .read(grafoProvider.notifier)
          .actualizarNodo('A', nombre: 'Inicio');
      expect(container.read(graphPathRunProvider).sourceId, 'B');
      expect(container.read(graphPathRunProvider).targetId, 'C');
      expect(container.read(graphPathRunProvider).computation, isNull);

      container.read(grafoProvider.notifier).eliminarNodo('B');
      expect(container.read(graphPathRunProvider).sourceIsManual, isFalse);
      expect(container.read(graphPathRunProvider).sourceId, 'C');
      container.dispose();
    },
  );

  test('al cargar otro grafo se revalidan incluso ids coincidentes', () {
    final container = ProviderContainer();
    container
        .read(grafoProvider.notifier)
        .cargarGrafo(
          Grafo(
            nodos: {
              for (final id in ['A', 'B'])
                id: Nodo(
                  id: id,
                  nombre: id,
                  colorValue: 0xFF6754B2,
                  x: 0,
                  y: 0,
                ),
            },
          ),
        );
    container
        .read(activeAlgorithmProvider.notifier)
        .selectById(AlgorithmRegistry.dijkstraId);
    container.read(graphPathRunProvider.notifier).setSource('B');
    container
        .read(grafoProvider.notifier)
        .cargarGrafo(
          Grafo(
            nodos: {
              for (final id in ['B', 'A'])
                id: Nodo(
                  id: id,
                  nombre: id,
                  colorValue: 0xFF6754B2,
                  x: 0,
                  y: 0,
                ),
            },
          ),
        );
    container
        .read(activeAlgorithmProvider.notifier)
        .selectById(AlgorithmRegistry.dijkstraId);
    expect(container.read(graphPathRunProvider).sourceId, 'B');
    expect(container.read(graphPathRunProvider).sourceIsManual, isFalse);
    container.dispose();
  });

  test('editar el grafo invalida los pasos, pero conserva la selección', () {
    final container = ProviderContainer();
    final g = Grafo(
      nodos: {
        for (final id in ['A', 'B'])
          id: Nodo(id: id, nombre: id, colorValue: 0xFF7461AE, x: 0, y: 0),
      },
      conexiones: {
        'AB': const Conexion(
          id: 'AB',
          nodoOrigenId: 'A',
          nodoDestinoId: 'B',
          colorValue: 0xFF7461AE,
          atributos: [AtributoValor(atributoId: 'attr_valor', valor: '1')],
        ),
      },
    );
    container.read(grafoProvider.notifier).cargarGrafo(g);
    final runner = container.read(graphPathRunProvider.notifier);
    runner.setSource('A');
    runner.setTarget('B');
    runner.run(container.read(grafoProvider));
    expect(container.read(graphPathRunProvider).computation?.value, 1);
    runner.seek(1);
    container
        .read(grafoProvider.notifier)
        .actualizarConexion(
          'AB',
          atributos: [
            const AtributoValor(atributoId: 'attr_valor', valor: '2'),
          ],
          recordUndo: true,
        );
    final state = container.read(graphPathRunProvider);
    expect(state.computation, isNull);
    expect(state.stepIndex, 0);
    expect(state.sourceId, 'A');
    expect(state.targetId, 'B');
    runner.run(container.read(grafoProvider));
    expect(container.read(graphPathRunProvider).computation?.value, 2);
    container.dispose();
  });
}
