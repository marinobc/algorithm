import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/northwest/domain/policy/northwest_graph_policy.dart';
import 'package:nodos/algorithms/northwest/domain/services/northwest_problem_extractor.dart';
import 'package:nodos/domain/models/conexion.dart';
import 'package:nodos/domain/models/direccion.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/domain/models/nodo.dart';

void main() {
  const policy = NorthwestGraphPolicy();

  test('crea origenes y destinos con cantidad editable', () {
    final origin = policy.prepareNewNode(
      const Grafo(),
      100,
      120,
      params: const {'role': NorthwestRoles.origin},
    );
    final destination = policy.prepareNewNode(
      Grafo(nodos: {origin.id: origin}),
      500,
      120,
      params: const {'role': NorthwestRoles.destination},
    );

    expect(origin.rol, NorthwestRoles.origin);
    expect(origin.nombre, 'A');
    expect(origin.cantidad, 0);
    expect(destination.rol, NorthwestRoles.destination);
    expect(destination.nombre, 'D1');
    expect(destination.cantidad, 0);
    expect(destination.colorValue, isNot(origin.colorValue));
  });

  test('solo permite conexiones nuevas de origen a destino', () {
    const origin = Nodo(
      id: 'o1',
      nombre: 'A',
      colorValue: 0xFF7C3AED,
      x: 100,
      y: 100,
      rol: NorthwestRoles.origin,
      cantidad: 10,
    );
    const destination = Nodo(
      id: 'd1',
      nombre: 'D1',
      colorValue: 0xFF00A884,
      x: 500,
      y: 100,
      rol: NorthwestRoles.destination,
      cantidad: 10,
    );
    const connection = Conexion(
      id: 'c1',
      nodoOrigenId: 'o1',
      nodoDestinoId: 'd1',
      colorValue: 0xFF7C3AED,
      direccion: Direccion.unidireccional,
    );
    const graph = Grafo(nodos: {'o1': origin, 'd1': destination});

    expect(
      policy
          .canCreateConnection(graph, 'o1', 'd1', Direccion.unidireccional)
          .allowed,
      isTrue,
    );
    expect(
      policy
          .canCreateConnection(graph, 'd1', 'o1', Direccion.unidireccional)
          .allowed,
      isFalse,
    );
    expect(
      policy
          .canCreateConnection(
            graph.copyWith(conexiones: const {'c1': connection}),
            'o1',
            'd1',
            Direccion.unidireccional,
          )
          .allowed,
      isFalse,
    );
  });
}
