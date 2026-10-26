import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/graph_paths/domain/graph_path_solver.dart';
import 'package:nodos/domain/models/atributo.dart';
import 'package:nodos/domain/models/conexion.dart';
import 'package:nodos/domain/models/direccion.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/domain/models/nodo.dart';

Grafo graph(
  List<String> ids,
  List<(String, String, String, String, Direccion)> edgeData,
) => Grafo(
  nodos: {
    for (final id in ids)
      id: Nodo(id: id, nombre: id, colorValue: 0xFF7755AA, x: 0, y: 0),
  },
  conexiones: {
    for (final (id, from, to, weight, direction) in edgeData)
      id: Conexion(
        id: id,
        nodoOrigenId: from,
        nodoDestinoId: to,
        colorValue: 0xFF7755AA,
        direccion: direction,
        atributos: [AtributoValor(atributoId: 'attr_valor', valor: weight)],
      ),
  },
);

void main() {
  final sample = graph(
    ['A', 'B', 'C'],
    [
      ('AB', 'A', 'B', '1', Direccion.ninguna),
      ('BC', 'B', 'C', '2', Direccion.ninguna),
      ('AC', 'A', 'C', '5', Direccion.ninguna),
    ],
  );

  test('example computes shortest, longest simple and both spanning trees', () {
    final shortest = GraphPathSolver.dijkstra(sample, 'A', 'C');
    final longest = GraphPathSolver.longestSimplePath(sample, 'A', 'C');
    final minimum = GraphPathSolver.kruskal(sample, maximum: false);
    final maximum = GraphPathSolver.kruskal(sample, maximum: true);
    expect(shortest.value, 3);
    expect(shortest.pathNodeIds, ['A', 'B', 'C']);
    expect(longest.value, 5);
    expect(longest.pathNodeIds, ['A', 'C']);
    expect(minimum.value, 3);
    expect(minimum.acceptedEdgeIds, ['AB', 'BC']);
    expect(maximum.value, 7);
    expect(maximum.acceptedEdgeIds, ['AC', 'BC']);
    expect(minimum.steps.last.acceptedEdges, {'AB', 'BC'});
    expect(
      minimum.steps.any((step) => step.rejectedEdges.contains('AC')),
      isTrue,
    );
  });

  test('Dijkstra records equal optimal paths and accepts zero weight', () {
    final g = graph(
      ['A', 'B', 'C'],
      [
        ('AB', 'A', 'B', '0', Direccion.unidireccional),
        ('BC', 'B', 'C', '2', Direccion.unidireccional),
        ('AC', 'A', 'C', '2', Direccion.unidireccional),
      ],
    );
    final result = GraphPathSolver.dijkstra(g, 'A', 'C');
    expect(result.value, 2);
    expect(result.alternatives.length, 2);
    expect(result.steps.last.distances['B'], 0);
    expect(GraphPathSolver.dijkstra(g, 'C', 'A').value, isNull);
  });

  test(
    'negative edge and missing weight are rejected with actionable errors',
    () {
      final negative = graph(
        ['A', 'B'],
        [('AB', 'A', 'B', '-1', Direccion.ninguna)],
      );
      expect(
        () => GraphPathSolver.dijkstra(negative, 'A', 'B'),
        throwsA(isA<GraphPathInputError>()),
      );
      expect(GraphPathSolver.kruskal(negative, maximum: false).value, -1);
      final missing = graph(
        ['A', 'B'],
        [('AB', 'A', 'B', '', Direccion.ninguna)],
      );
      expect(
        () => GraphPathSolver.kruskal(missing, maximum: false),
        throwsA(isA<GraphPathInputError>()),
      );
    },
  );

  test('Kruskal rejects directed graphs and reports a disconnected forest', () {
    final directed = graph(
      ['A', 'B'],
      [('AB', 'A', 'B', '1', Direccion.unidireccional)],
    );
    expect(
      () => GraphPathSolver.kruskal(directed, maximum: false),
      throwsA(isA<GraphPathInputError>()),
    );
    final forest = graph(
      ['A', 'B', 'C'],
      [('AB', 'A', 'B', '0', Direccion.ninguna)],
    );
    final result = GraphPathSolver.kruskal(forest, maximum: false);
    expect(result.componentCount, 2);
    expect(result.value, 0);
    expect(result.summary, contains('Bosque'));
  });

  test('longest path uses topological dynamic programming on a DAG', () {
    final dag = graph(
      ['A', 'B', 'C'],
      [
        ('AB', 'A', 'B', '-4', Direccion.unidireccional),
        ('BC', 'B', 'C', '10', Direccion.unidireccional),
        ('AC', 'A', 'C', '5', Direccion.unidireccional),
      ],
    );
    final result = GraphPathSolver.longestSimplePath(dag, 'A', 'C');
    expect(result.exact, isTrue);
    expect(result.value, 6);
    expect(result.pathNodeIds, ['A', 'B', 'C']);
    expect(result.method, contains('DAG'));
  });

  test('empty and single-vertex graphs have explicit outcomes', () {
    expect(
      () => GraphPathSolver.dijkstra(const Grafo(), 'A', 'A'),
      throwsA(isA<GraphPathInputError>()),
    );
    final lone = graph(['A'], []);
    expect(GraphPathSolver.dijkstra(lone, 'A', 'A').value, 0);
    expect(GraphPathSolver.longestSimplePath(lone, 'A', 'A').value, 0);
    final tree = GraphPathSolver.kruskal(lone, maximum: false);
    expect(tree.value, 0);
    expect(tree.componentCount, 1);
    expect(tree.acceptedEdgeIds, isEmpty);
  });

  test('parallel edges, loop and decimal weights keep their identities', () {
    final g = graph(
      ['A', 'B'],
      [
        ('AB1', 'A', 'B', '0.5', Direccion.ninguna),
        ('AB2', 'A', 'B', '2.25', Direccion.ninguna),
        ('AA', 'A', 'A', '0', Direccion.ninguna),
      ],
    );
    expect(GraphPathSolver.dijkstra(g, 'A', 'B').value, 0.5);
    final tree = GraphPathSolver.kruskal(g, maximum: false);
    expect(tree.value, 0.5);
    expect(tree.acceptedEdgeIds, ['AB1']);
    expect(tree.steps.last.rejectedEdges, {'AA', 'AB2'});
    final restored = Grafo.fromJson(g.toJson());
    expect(restored.conexiones.keys.toSet(), g.conexiones.keys.toSet());
    expect(restored.conexiones['AB1']!.atributos.single.valor, '0.5');
  });

  test('large non-DAG reports an incomplete maximum instead of an optimum', () {
    final ids = [for (var i = 0; i < 12; i++) 'N$i'];
    final g = graph(ids, [('edge', 'N0', 'N1', '1', Direccion.ninguna)]);
    final result = GraphPathSolver.longestSimplePath(g, 'N0', 'N1');
    expect(result.exact, isFalse);
    expect(result.summary, contains('No se ha demostrado'));
  });
}
