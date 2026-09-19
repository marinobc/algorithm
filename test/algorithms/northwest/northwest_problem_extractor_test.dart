import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/northwest/domain/models/northwest_models.dart';
import 'package:nodos/algorithms/northwest/domain/services/northwest_problem_extractor.dart';
import 'package:nodos/domain/models/atributo.dart';
import 'package:nodos/domain/models/conexion.dart';
import 'package:nodos/domain/models/direccion.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/domain/models/nodo.dart';

void main() {
  Grafo buildGraph({List<double> demands = const [10, 30, 40, 20]}) {
    const originIds = ['o1', 'o2', 'o3'];
    const destinationIds = ['d1', 'd2', 'd3', 'd4'];
    const costs = [
      [2.0, 7.0, 6.0, 8.0],
      [2.0, 2.0, 6.0, 9.0],
      [9.0, 2.0, 2.0, 2.0],
    ];
    final nodes = <String, Nodo>{};
    for (var i = 0; i < originIds.length; i++) {
      nodes[originIds[i]] = Nodo(
        id: originIds[i],
        nombre: String.fromCharCode(65 + i),
        colorValue: 0xFF14B8A6,
        x: 100,
        y: i * 100,
        rol: NorthwestRoles.origin,
        cantidad: const [20.0, 30.0, 50.0][i],
      );
    }
    for (var j = 0; j < destinationIds.length; j++) {
      nodes[destinationIds[j]] = Nodo(
        id: destinationIds[j],
        nombre: 'D${j + 1}',
        colorValue: 0xFFF59E0B,
        x: 700,
        y: j * 100,
        rol: NorthwestRoles.destination,
        cantidad: demands[j],
      );
    }
    final connections = <String, Conexion>{};
    for (var i = 0; i < originIds.length; i++) {
      for (var j = 0; j < destinationIds.length; j++) {
        final id = 'c_${i}_$j';
        connections[id] = Conexion(
          id: id,
          nodoOrigenId: originIds[i],
          nodoDestinoId: destinationIds[j],
          colorValue: 0xFF14B8A6,
          direccion: Direccion.unidireccional,
          atributos: [
            AtributoValor(atributoId: 'attr_valor', valor: '${costs[i][j]}'),
          ],
        );
      }
    }
    return Grafo(
      nodos: nodes,
      conexiones: connections,
      tipoAlgoritmo: 'northwest',
      metadata: const {
        NorthwestMetadata.originOrder: 'o1,o2,o3',
        NorthwestMetadata.destinationOrder: 'd1,d2,d3,d4',
        NorthwestMetadata.objective: 'minimize',
      },
    );
  }

  test('extrae una matriz completa desde el grafo persistente', () {
    final validation = NorthwestProblemExtractor.extract(buildGraph());

    expect(validation.isValid, isTrue);
    expect(validation.problem!.costs[2][3], 2);
    expect(validation.problem!.supplies, const [20, 30, 50]);
    expect(validation.problem!.demands, const [10, 30, 40, 20]);
    expect(validation.problem!.objective, TransportationObjective.minimize);
  });

  test('la serializacion conserva cantidades, orden y objetivo', () {
    final restored = Grafo.fromJson(buildGraph().toJson());
    final validation = NorthwestProblemExtractor.extract(restored);

    expect(validation.isValid, isTrue);
    expect(restored.nodos['o1']!.cantidad, 20);
    expect(
      restored.metadata[NorthwestMetadata.destinationOrder],
      'd1,d2,d3,d4',
    );
  });

  test(
    'equilibra automáticamente agregando fila o columna ficticia con costo 0',
    () {
      final validation = NorthwestProblemExtractor.extract(
        buildGraph(demands: const [10, 30, 40, 10]),
      );

      expect(validation.isValid, isTrue);
      expect(validation.problem!.destinationNames.last, 'Ficticio');
      expect(validation.problem!.demands.last, 10);
      expect(validation.problem!.costs[0].last, 0);
    },
  );

  test('recupera el orden si la metadata quedo desactualizada', () {
    final graph = buildGraph();
    final validation = NorthwestProblemExtractor.extract(
      graph.copyWith(
        metadata: {...graph.metadata, NorthwestMetadata.originOrder: 'o1,o2'},
      ),
    );

    expect(validation.isValid, isTrue);
    expect(validation.problem!.originIds, const ['o1', 'o2', 'o3']);
  });
}
