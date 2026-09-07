import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/domain/models/atributo.dart';
import 'package:nodos/domain/models/conexion.dart';
import 'package:nodos/domain/models/direccion.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/domain/models/nodo.dart';
import 'package:nodos/domain/services/graph_storage_service.dart';

void main() {
  group('Domain - Grafo JSON Serialization & Deserialization', () {
    test('Grafo -> toJson -> fromJson restores exact graph state', () {
      const n1 = Nodo(
        id: 'n1',
        nombre: 'Nodo A',
        colorValue: 0xFF2196F3,
        x: 100,
        y: 150,
      );
      const n2 = Nodo(
        id: 'n2',
        nombre: 'Nodo B',
        colorValue: 0xFFFF9800,
        x: 300,
        y: 350,
      );

      const conn = Conexion(
        id: 'c1',
        nodoOrigenId: 'n1',
        nodoDestinoId: 'n2',
        colorValue: 0xFF4CAF50,
        direccion: Direccion.unidireccional,
        atributos: [AtributoValor(atributoId: 'attr_valor', valor: '10')],
      );

      final originalGraph = Grafo(
        nodos: {'n1': n1, 'n2': n2},
        conexiones: {'c1': conn},
        atributosGlobales: const [Atributo(id: 'attr_valor', nombre: 'Valor')],
      );

      final jsonMap = originalGraph.toJson();
      final restoredGraph = Grafo.fromJson(jsonMap);

      expect(restoredGraph.nodos.length, equals(2));
      expect(restoredGraph.conexiones.length, equals(1));

      final restoredN1 = restoredGraph.nodos['n1'];
      expect(restoredN1?.nombre, equals('Nodo A'));
      expect(restoredN1?.x, equals(100));

      final restoredC1 = restoredGraph.conexiones['c1'];
      expect(restoredC1?.direccion, equals(Direccion.unidireccional));
      expect(restoredC1?.atributos.first.valor, equals('10'));
    });

    test('GraphStorageService exportToJson and importFromJson roundtrip', () {
      const n1 = Nodo(
        id: 'n1',
        nombre: 'Alpha',
        colorValue: 0xFF000000,
        x: 0,
        y: 0,
      );
      final original = Grafo(nodos: {'n1': n1});

      final jsonStr = GraphStorageService.exportToJson(original);
      expect(jsonStr, contains('"nombre": "Alpha"'));

      final imported = GraphStorageService.importFromJson(jsonStr);
      expect(imported.nodos.containsKey('n1'), isTrue);
      expect(imported.nodos['n1']?.nombre, equals('Alpha'));
    });
  });
}
