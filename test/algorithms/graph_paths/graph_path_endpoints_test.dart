import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/graph_paths/domain/graph_path_endpoints.dart';
import 'package:nodos/domain/models/conexion.dart';
import 'package:nodos/domain/models/direccion.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/domain/models/nodo.dart';

void main() {
  Grafo graph(List<String> ids, List<Conexion> edges) => Grafo(
    nodos: {
      for (final id in ids)
        id: Nodo(id: id, nombre: id, colorValue: 0xFF6754B2, x: 0, y: 0),
    },
    conexiones: {for (final edge in edges) edge.id: edge},
  );

  Conexion edge(String id, String from, String to, {bool directed = true}) =>
      Conexion(
        id: id,
        nodoOrigenId: from,
        nodoDestinoId: to,
        colorValue: 0xFF6754B2,
        direccion: directed ? Direccion.unidireccional : Direccion.ninguna,
      );

  test('grafo dirigido con entrada y salida únicas se detecta por grado', () {
    final proposed = GraphPathEndpoints.suggest(
      graph(['B', 'A', 'C'], [edge('AB', 'A', 'B'), edge('BC', 'B', 'C')]),
    );
    expect(proposed.sourceId, 'A');
    expect(proposed.targetId, 'C');
    expect(proposed.inferredFromTopology, isTrue);
  });

  test('ambiguo o no dirigido propone primer y último vértice creados', () {
    final ambiguous = GraphPathEndpoints.suggest(
      graph(['B', 'A', 'C'], [edge('BC', 'B', 'C')]),
    );
    expect(ambiguous.sourceId, 'B');
    expect(ambiguous.targetId, 'C');
    expect(ambiguous.inferredFromTopology, isFalse);

    final undirected = GraphPathEndpoints.suggest(
      graph(['C', 'A', 'B'], [edge('CA', 'C', 'A', directed: false)]),
    );
    expect(undirected.sourceId, 'C');
    expect(undirected.targetId, 'B');
    expect(undirected.inferredFromTopology, isFalse);
  });

  test('un único vértice puede ser origen y destino', () {
    final proposed = GraphPathEndpoints.suggest(graph(['A'], []));
    expect(proposed.sourceId, 'A');
    expect(proposed.targetId, 'A');
  });
}
