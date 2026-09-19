import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/johnson/domain/services/johnson_validator.dart';
import 'package:nodos/domain/models/atributo.dart';
import 'package:nodos/domain/models/conexion.dart';
import 'package:nodos/domain/models/direccion.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/domain/models/nodo.dart';

void main() {
  group('JohnsonValidator Unit Tests', () {
    test('returns invalid when graph is empty', () {
      const grafo = Grafo(nodos: {}, conexiones: {});
      final result = JohnsonValidator.validate(grafo);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('al menos un nodo'));
    });

    test('returns invalid when graph has no connections', () {
      const grafo = Grafo(
        nodos: {'n1': Nodo(id: 'n1', colorValue: 0, x: 0, y: 0)},
        conexiones: {},
      );
      final result = JohnsonValidator.validate(grafo);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('al menos una conexión'));
    });

    test('returns invalid when an isolated node exists', () {
      const grafo = Grafo(
        nodos: {
          'n1': Nodo(id: 'n1', nombre: 'A', colorValue: 0, x: 0, y: 0),
          'n2': Nodo(id: 'n2', nombre: 'B', colorValue: 0, x: 50, y: 0),
          'n3': Nodo(id: 'n3', nombre: 'C', colorValue: 0, x: 100, y: 0),
        },
        conexiones: {
          'c1': Conexion(
            id: 'c1',
            nodoOrigenId: 'n1',
            nodoDestinoId: 'n2',
            colorValue: 0,
            direccion: Direccion.unidireccional,
          ),
        },
      );
      final result = JohnsonValidator.validate(grafo);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('nodo aislado "C"'));
    });

    test(
      'returns invalid when graph has disconnected subgraphs (2 components)',
      () {
        // Actividad 1 -> Actividad 3, Actividad 2 -> Actividad 3 (Component 1)
        // Actividad 4 -> Actividad 5 (Component 2)
        final grafo = Grafo(
          nodos: {
            'nodo_1': const Nodo(
              id: 'nodo_1',
              nombre: 'Actividad 1',
              colorValue: 0,
              x: 0,
              y: 0,
            ),
            'nodo_2': const Nodo(
              id: 'nodo_2',
              nombre: 'Actividad 2',
              colorValue: 0,
              x: 0,
              y: 50,
            ),
            'nodo_3': const Nodo(
              id: 'nodo_3',
              nombre: 'Actividad 3',
              colorValue: 0,
              x: 100,
              y: 25,
            ),
            'nodo_4': const Nodo(
              id: 'nodo_4',
              nombre: 'Actividad 4',
              colorValue: 0,
              x: 0,
              y: 200,
            ),
            'nodo_5': const Nodo(
              id: 'nodo_5',
              nombre: 'Actividad 5',
              colorValue: 0,
              x: 100,
              y: 200,
            ),
          },
          conexiones: {
            'conn_1': const Conexion(
              id: 'conn_1',
              nodoOrigenId: 'nodo_4',
              nodoDestinoId: 'nodo_5',
              colorValue: 0,
              direccion: Direccion.unidireccional,
              atributos: [AtributoValor(atributoId: 'attr_valor', valor: '1')],
            ),
            'conn_2': const Conexion(
              id: 'conn_2',
              nodoOrigenId: 'nodo_2',
              nodoDestinoId: 'nodo_3',
              colorValue: 0,
              direccion: Direccion.unidireccional,
              atributos: [AtributoValor(atributoId: 'attr_valor', valor: '1')],
            ),
            'conn_3': const Conexion(
              id: 'conn_3',
              nodoOrigenId: 'nodo_1',
              nodoDestinoId: 'nodo_3',
              colorValue: 0,
              direccion: Direccion.unidireccional,
              atributos: [AtributoValor(atributoId: 'attr_valor', valor: '1')],
            ),
          },
        );

        final result = JohnsonValidator.validate(grafo);
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('subgrafos no conectados'));
      },
    );

    test('returns valid when graph is a single connected DAG', () {
      final grafo = Grafo(
        nodos: {
          'n1': const Nodo(id: 'n1', nombre: 'A', colorValue: 0, x: 0, y: 0),
          'n2': const Nodo(id: 'n2', nombre: 'B', colorValue: 0, x: 50, y: 0),
          'n3': const Nodo(id: 'n3', nombre: 'C', colorValue: 0, x: 100, y: 0),
        },
        conexiones: {
          'c1': const Conexion(
            id: 'c1',
            nodoOrigenId: 'n1',
            nodoDestinoId: 'n2',
            colorValue: 0,
            direccion: Direccion.unidireccional,
          ),
          'c2': const Conexion(
            id: 'c2',
            nodoOrigenId: 'n2',
            nodoDestinoId: 'n3',
            colorValue: 0,
            direccion: Direccion.unidireccional,
          ),
        },
      );

      final result = JohnsonValidator.validate(grafo);
      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    test(
      'returns valid when graph is a simple 2-node directed edge (A -> B)',
      () {
        final grafo = Grafo(
          nodos: {
            'n1': const Nodo(
              id: 'n1',
              nombre: 'A',
              rol: 'actividad',
              colorValue: 0,
              x: 0,
              y: 0,
            ),
            'n2': const Nodo(
              id: 'n2',
              nombre: 'B',
              rol: 'actividad',
              colorValue: 0,
              x: 50,
              y: 0,
            ),
            'n3': const Nodo(
              id: 'n3',
              nombre: 'C',
              rol: 'actividad',
              colorValue: 0,
              x: 100,
              y: 0,
            ),
          },
          conexiones: {
            'c1': const Conexion(
              id: 'c1',
              nodoOrigenId: 'n1',
              nodoDestinoId: 'n2',
              colorValue: 0,
              direccion: Direccion.unidireccional,
            ),
            'c2': const Conexion(
              id: 'c2',
              nodoOrigenId: 'n2',
              nodoDestinoId: 'n3',
              colorValue: 0,
              direccion: Direccion.unidireccional,
            ),
          },
        );

        final result = JohnsonValidator.validate(grafo);
        expect(result.isValid, isTrue);
        expect(result.errorMessage, isNull);
      },
    );

    test('returns invalid when graph contains cycles', () {
      final grafo = Grafo(
        nodos: {
          'n1': const Nodo(id: 'n1', nombre: 'A', colorValue: 0, x: 0, y: 0),
          'n2': const Nodo(id: 'n2', nombre: 'B', colorValue: 0, x: 50, y: 0),
        },
        conexiones: {
          'c1': const Conexion(
            id: 'c1',
            nodoOrigenId: 'n1',
            nodoDestinoId: 'n2',
            colorValue: 0,
            direccion: Direccion.unidireccional,
          ),
          'c2': const Conexion(
            id: 'c2',
            nodoOrigenId: 'n2',
            nodoDestinoId: 'n1',
            colorValue: 0,
            direccion: Direccion.unidireccional,
          ),
        },
      );

      final result = JohnsonValidator.validate(grafo);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('contiene ciclos'));
    });

    test('returns invalid when graph is a 3x4 Bipartite Assignment graph (classified as ASSIGNMENT, not JOHNSON)', () {
      // 3 origins (o1, o2, o3) and 4 destinations (d1, d2, d3, d4)
      final nodos = <String, Nodo>{
        'o1': const Nodo(id: 'o1', nombre: 'O1', colorValue: 0, x: 0, y: 0),
        'o2': const Nodo(id: 'o2', nombre: 'O2', colorValue: 0, x: 0, y: 50),
        'o3': const Nodo(id: 'o3', nombre: 'O3', colorValue: 0, x: 0, y: 100),
        'd1': const Nodo(id: 'd1', nombre: 'D1', colorValue: 0, x: 100, y: 0),
        'd2': const Nodo(id: 'd2', nombre: 'D2', colorValue: 0, x: 100, y: 50),
        'd3': const Nodo(id: 'd3', nombre: 'D3', colorValue: 0, x: 100, y: 100),
        'd4': const Nodo(id: 'd4', nombre: 'D4', colorValue: 0, x: 100, y: 150),
      };

      final conexiones = <String, Conexion>{};
      int counter = 1;
      for (final o in ['o1', 'o2', 'o3']) {
        for (final d in ['d1', 'd2', 'd3', 'd4']) {
          final id = 'c_$counter';
          conexiones[id] = Conexion(
            id: id,
            nodoOrigenId: o,
            nodoDestinoId: d,
            colorValue: 0,
            direccion: Direccion.unidireccional,
            atributos: const [
              AtributoValor(atributoId: 'attr_valor', valor: '5'),
            ],
          );
          counter++;
        }
      }

      final grafo = Grafo(nodos: nodos, conexiones: conexiones);

      final result = JohnsonValidator.validate(grafo);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Asignación'));
    });
  });
}
