import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/graph_paths/domain/graph_path_policy.dart';
import 'package:nodos/domain/models/atributo.dart';
import 'package:nodos/domain/models/conexion.dart';
import 'package:nodos/domain/models/direccion.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/domain/models/nodo.dart';

void main() {
  final graph = Grafo(
    nodos: {
      for (final id in ['A', 'B', 'C'])
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
  const dijkstra = GraphPathPolicy(kruskal: false);
  const kruskal = GraphPathPolicy(kruskal: true);

  for (final policy in [dijkstra, kruskal]) {
    test(
      'cada nodo nuevo recibe un color distinto en ${policy.kruskal ? 'Kruskal' : 'Dijkstra'}',
      () {
        var current = const Grafo();
        for (var i = 0; i < 16; i++) {
          final node = policy.prepareNewNode(current, i * 80.0, 0);
          current = current.copyWith(nodos: {...current.nodos, node.id: node});
        }
        expect(current.nodos.length, 16);
        expect(
          current.nodos.values.map((node) => node.colorValue).toSet().length,
          16,
        );

        final custom = policy.prepareNewNode(
          current,
          0,
          80,
          colorValue: 0xFF123456,
        );
        expect(custom.colorValue, 0xFF123456);
        expect(
          current.nodos.values.any((node) => node.colorValue == 0xFF123456),
          isFalse,
        );
      },
    );
  }

  test('canvas shares one graph but enforces each construction policy', () {
    expect(
      dijkstra
          .canCreateConnection(graph, 'B', 'C', Direccion.unidireccional)
          .allowed,
      isTrue,
    );
    expect(
      dijkstra.canCreateConnection(graph, 'B', 'C', Direccion.ninguna).allowed,
      isTrue,
    );
    expect(
      dijkstra
          .canCreateConnection(graph, 'B', 'C', Direccion.bidireccional)
          .allowed,
      isFalse,
    );
    expect(
      dijkstra
          .canCreateConnection(graph, 'B', 'A', Direccion.unidireccional)
          .allowed,
      isFalse,
    );
    expect(
      kruskal
          .canCreateConnection(graph, 'B', 'C', Direccion.unidireccional)
          .allowed,
      isFalse,
    );
    expect(
      kruskal.canCreateConnection(graph, 'B', 'C', Direccion.ninguna).allowed,
      isTrue,
    );
    expect(
      kruskal.canCreateConnection(graph, 'C', 'C', Direccion.ninguna).allowed,
      isFalse,
    );
  });

  test('Dijkstra treats opposite directed arcs as independent', () {
    final directed = graph.copyWith(
      conexiones: {
        'AB': graph.conexiones['AB']!.copyWith(
          direccion: Direccion.unidireccional,
        ),
      },
    );
    expect(
      dijkstra
          .canCreateConnection(directed, 'B', 'A', Direccion.unidireccional)
          .allowed,
      isTrue,
    );
    expect(
      dijkstra
          .canCreateConnection(directed, 'A', 'B', Direccion.unidireccional)
          .allowed,
      isFalse,
    );
    expect(
      dijkstra.canCreateConnection(directed, 'B', 'A', Direccion.ninguna).allowed,
      isFalse,
    );

    final both = directed.copyWith(conexiones: {
      ...directed.conexiones,
      'BA': const Conexion(
        id: 'BA',
        nodoOrigenId: 'B',
        nodoDestinoId: 'A',
        colorValue: 0xFF7461AE,
        direccion: Direccion.unidireccional,
        atributos: [AtributoValor(atributoId: 'attr_valor', valor: '7')],
      ),
    });
    expect(
      dijkstra
          .canUpdateConnection(
            both,
            both.conexiones['BA']!,
            origenId: 'B',
            destinoId: 'A',
            direccion: Direccion.unidireccional,
            weight: '9',
          )
          .allowed,
      isTrue,
    );
    expect(
      dijkstra
          .canUpdateConnection(
            both,
            both.conexiones['BA']!,
            origenId: 'A',
            destinoId: 'B',
            direccion: Direccion.unidireccional,
            weight: '9',
          )
          .allowed,
      isFalse,
    );
    expect(
      dijkstra
          .canUpdateConnection(
            both,
            both.conexiones['BA']!,
            origenId: 'B',
            destinoId: 'A',
            direccion: Direccion.ninguna,
            weight: '9',
          )
          .allowed,
      isFalse,
    );
    expect(
      kruskal.canCreateConnection(both, 'A', 'B', Direccion.ninguna).allowed,
      isFalse,
    );
  });

  test(
    'shared edit panel policy preserves valid zero and negative weights',
    () {
      final current = graph.conexiones['AB']!;
      expect(
        dijkstra
            .canUpdateConnection(
              graph,
              current,
              origenId: 'A',
              destinoId: 'B',
              direccion: Direccion.ninguna,
              weight: '0',
            )
            .allowed,
        isTrue,
      );
      expect(
        dijkstra
            .canUpdateConnection(
              graph,
              current,
              origenId: 'A',
              destinoId: 'B',
              direccion: Direccion.ninguna,
              weight: '-1',
            )
            .allowed,
        isFalse,
      );
      expect(
        dijkstra
            .canUpdateConnection(
              graph,
              current,
              origenId: 'A',
              destinoId: 'B',
              direccion: Direccion.ninguna,
              weight: '-1',
              allowNegativeForLongestSimple: true,
            )
            .allowed,
        isTrue,
      );
      expect(
        kruskal
            .canUpdateConnection(
              graph,
              current,
              origenId: 'A',
              destinoId: 'B',
              direccion: Direccion.ninguna,
              weight: '-1.25',
            )
            .allowed,
        isTrue,
      );
      expect(
        kruskal
            .canUpdateConnection(
              graph,
              current,
              origenId: 'A',
              destinoId: 'B',
              direccion: Direccion.unidireccional,
              weight: '1',
            )
            .allowed,
        isFalse,
      );
      expect(
        kruskal
            .canUpdateConnection(
              graph,
              current,
              origenId: 'A',
              destinoId: 'B',
              direccion: Direccion.ninguna,
              weight: 'Infinity',
            )
            .allowed,
        isFalse,
      );
    },
  );
}
