import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/domain/models/atributo.dart';
import 'package:nodos/domain/models/conexion.dart';
import 'package:nodos/domain/models/direccion.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/domain/models/nodo.dart';
import 'package:nodos/domain/services/graph_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'save and load preserve two opposite directed edges independently',
    () async {
      SharedPreferences.setMockInitialValues({});
      final graph = Grafo(
        tipoAlgoritmo: 'dijkstra',
        nodos: const {
          'A': Nodo(id: 'A', nombre: 'A', colorValue: 0xFF6754B2, x: 0, y: 0),
          'B': Nodo(id: 'B', nombre: 'B', colorValue: 0xFF008F87, x: 200, y: 0),
        },
        conexiones: const {
          'AB': Conexion(
            id: 'AB',
            nodoOrigenId: 'A',
            nodoDestinoId: 'B',
            colorValue: 0xFF6754B2,
            direccion: Direccion.unidireccional,
            atributos: [AtributoValor(atributoId: 'attr_valor', valor: '2')],
          ),
          'BA': Conexion(
            id: 'BA',
            nodoOrigenId: 'B',
            nodoDestinoId: 'A',
            colorValue: 0xFF008F87,
            direccion: Direccion.unidireccional,
            atributos: [AtributoValor(atributoId: 'attr_valor', valor: '7')],
          ),
        },
      );
      final saved = await GraphStorageService.saveGraphSlot('ciclo', graph);
      expect(saved.tipoAlgoritmo, 'dijkstra');
      expect(
        await GraphStorageService.getSavedGraphs(algorithmId: 'kruskal'),
        isEmpty,
      );
      final stored = await GraphStorageService.getSavedGraphs(
        algorithmId: 'dijkstra',
      );
      expect(stored, hasLength(1));
      final restored = GraphStorageService.importFromJson(
        stored.single.jsonContent,
      );
      expect(restored.conexiones.keys.toSet(), {'AB', 'BA'});
      expect(restored.conexiones['AB']!.nodoOrigenId, 'A');
      expect(restored.conexiones['AB']!.nodoDestinoId, 'B');
      expect(restored.conexiones['AB']!.atributos.single.valor, '2');
      expect(restored.conexiones['BA']!.nodoOrigenId, 'B');
      expect(restored.conexiones['BA']!.nodoDestinoId, 'A');
      expect(restored.conexiones['BA']!.atributos.single.valor, '7');
    },
  );
}
