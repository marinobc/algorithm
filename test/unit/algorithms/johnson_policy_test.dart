import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/johnson/domain/policy/johnson_graph_policy.dart';
import 'package:nodos/domain/models/conexion.dart';
import 'package:nodos/domain/models/direccion.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/domain/models/nodo.dart';

void main() {
  group('JohnsonGraphPolicy Unit Tests', () {
    const policy = JohnsonGraphPolicy();

    test('allows forward directed acyclic connections (A -> B, B -> C)', () {
      const a = Nodo(id: 'a', nombre: 'A', colorValue: 0, x: 0, y: 0);
      const b = Nodo(id: 'b', nombre: 'B', colorValue: 0, x: 50, y: 50);
      const c = Nodo(id: 'c', nombre: 'C', colorValue: 0, x: 100, y: 100);

      final grafo1 = Grafo(
        nodos: {'a': a, 'b': b, 'c': c},
        conexiones: const {},
      );

      // A -> B
      final res1 = policy.canCreateConnection(
        grafo1,
        'a',
        'b',
        Direccion.unidireccional,
      );
      expect(res1.allowed, isTrue);

      const connAB = Conexion(
        id: 'c1',
        nodoOrigenId: 'a',
        nodoDestinoId: 'b',
        colorValue: 0,
        direccion: Direccion.unidireccional,
      );

      final grafo2 = Grafo(
        nodos: {'a': a, 'b': b, 'c': c},
        conexiones: {'c1': connAB},
      );

      // B -> C
      final res2 = policy.canCreateConnection(
        grafo2,
        'b',
        'c',
        Direccion.unidireccional,
      );
      expect(res2.allowed, isTrue);
    });

    test('detects and denies cycle-creating backward edge (C -> A when A -> B -> C)', () {
      const a = Nodo(id: 'a', nombre: 'A', colorValue: 0, x: 0, y: 0);
      const b = Nodo(id: 'b', nombre: 'B', colorValue: 0, x: 50, y: 50);
      const c = Nodo(id: 'c', nombre: 'C', colorValue: 0, x: 100, y: 100);

      const connAB = Conexion(
        id: 'c1',
        nodoOrigenId: 'a',
        nodoDestinoId: 'b',
        colorValue: 0,
        direccion: Direccion.unidireccional,
      );
      const connBC = Conexion(
        id: 'c2',
        nodoOrigenId: 'b',
        nodoDestinoId: 'c',
        colorValue: 0,
        direccion: Direccion.unidireccional,
      );

      final grafo = Grafo(
        nodos: {'a': a, 'b': b, 'c': c},
        conexiones: {'c1': connAB, 'c2': connBC},
      );

      // Attempting C -> A: creates cycle A -> B -> C -> A
      final result = policy.canCreateConnection(
        grafo,
        'c',
        'a',
        Direccion.unidireccional,
      );
      expect(result.allowed, isFalse);
      expect(result.message, contains('formaría un ciclo hacia atrás'));
    });

    test('denies reverse connection when forward connection exists (B -> A when A -> B)', () {
      const a = Nodo(id: 'a', nombre: 'A', colorValue: 0, x: 0, y: 0);
      const b = Nodo(id: 'b', nombre: 'B', colorValue: 0, x: 50, y: 50);

      const connAB = Conexion(
        id: 'c1',
        nodoOrigenId: 'a',
        nodoDestinoId: 'b',
        colorValue: 0,
        direccion: Direccion.unidireccional,
      );

      final grafo = Grafo(nodos: {'a': a, 'b': b}, conexiones: {'c1': connAB});

      final result = policy.canCreateConnection(
        grafo,
        'b',
        'a',
        Direccion.unidireccional,
      );
      expect(result.allowed, isFalse);
      expect(
        result.message,
        contains('ya existe una conexión en sentido contrario'),
      );
    });

    test('denies self-loop and bidirectional connections', () {
      const a = Nodo(id: 'a', nombre: 'A', colorValue: 0, x: 0, y: 0);
      final grafo = Grafo(nodos: {'a': a}, conexiones: const {});

      final loopResult = policy.canCreateConnection(
        grafo,
        'a',
        'a',
        Direccion.unidireccional,
      );
      expect(loopResult.allowed, isFalse);
      expect(loopResult.message, contains('no permite auto-conexiones'));

      const b = Nodo(id: 'b', nombre: 'B', colorValue: 0, x: 50, y: 50);
      final grafo2 = Grafo(nodos: {'a': a, 'b': b}, conexiones: const {});
      final bidirResult = policy.canCreateConnection(
        grafo2,
        'a',
        'b',
        Direccion.bidireccional,
      );
      expect(bidirResult.allowed, isFalse);
      expect(bidirResult.message, contains('estrictamente unidireccionales'));
    });
  });
}
