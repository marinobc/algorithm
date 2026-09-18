import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/assignment/domain/policy/assignment_graph_policy.dart';
import 'package:nodos/domain/models/conexion.dart';
import 'package:nodos/domain/models/direccion.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/domain/models/nodo.dart';

void main() {
  group('AssignmentGraphPolicy Unit Tests', () {
    const policy = AssignmentGraphPolicy();

    test('prepares standard nodes cleanly without forced role', () {
      const emptyGraph = Grafo();

      final node1 = policy.prepareNewNode(emptyGraph, 100, 100);
      expect(node1.rol, isNull);
      expect(node1.nombre, isNotNull);
      expect(node1.nombre, isNotEmpty);
      expect(node1.nombre, isNot(equals('Nodo 1')));

      final graphWithNode1 = Grafo(
        nodos: {node1.id: node1},
        conexiones: const {},
      );

      final node2 = policy.prepareNewNode(graphWithNode1, 200, 200);
      expect(node2.rol, isNull);
      expect(node2.nombre, isNotNull);
      expect(node2.nombre, isNotEmpty);
    });

    test('allows first connection between two neutral nodes', () {
      const n1 = Nodo(id: 'n1', nombre: 'Nodo 1', colorValue: 0, x: 0, y: 0);
      const n2 = Nodo(
        id: 'n2',
        nombre: 'Nodo 2',
        colorValue: 0,
        x: 100,
        y: 100,
      );

      final grafo = Grafo(nodos: {'n1': n1, 'n2': n2}, conexiones: const {});

      final result = policy.canCreateConnection(
        grafo,
        'n1',
        'n2',
        Direccion.unidireccional,
      );
      expect(result.allowed, isTrue);
      expect(result.message, isNull);
    });

    test('automatically detects destination and denies it from emitting connections', () {
      // n1 -> n2 exists, so n2 acts as Destination
      const n1 = Nodo(id: 'n1', nombre: 'Nodo 1', colorValue: 0, x: 0, y: 0);
      const n2 = Nodo(
        id: 'n2',
        nombre: 'Nodo 2',
        colorValue: 0,
        x: 100,
        y: 100,
      );
      const n3 = Nodo(
        id: 'n3',
        nombre: 'Nodo 3',
        colorValue: 0,
        x: 200,
        y: 200,
      );

      final conn = Conexion(
        id: 'c1',
        nodoOrigenId: 'n1',
        nodoDestinoId: 'n2',
        direccion: Direccion.unidireccional,
        colorValue: 0,
      );

      final grafo = Grafo(
        nodos: {'n1': n1, 'n2': n2, 'n3': n3},
        conexiones: {'c1': conn},
      );

      // Attempting to connect from n2 (which is a destination) to n3 must be blocked!
      final result = policy.canCreateConnection(
        grafo,
        'n2',
        'n3',
        Direccion.unidireccional,
      );
      expect(result.allowed, isFalse);
      expect(result.message, contains('actúa como Destino'));
    });

    test(
      'automatically detects origin and denies it from receiving connections',
      () {
        // n1 -> n2 exists, so n1 acts as Origin
        const n1 = Nodo(id: 'n1', nombre: 'Nodo 1', colorValue: 0, x: 0, y: 0);
        const n2 = Nodo(
          id: 'n2',
          nombre: 'Nodo 2',
          colorValue: 0,
          x: 100,
          y: 100,
        );
        const n3 = Nodo(
          id: 'n3',
          nombre: 'Nodo 3',
          colorValue: 0,
          x: 200,
          y: 200,
        );

        final conn = Conexion(
          id: 'c1',
          nodoOrigenId: 'n1',
          nodoDestinoId: 'n2',
          direccion: Direccion.unidireccional,
          colorValue: 0,
        );

        final grafo = Grafo(
          nodos: {'n1': n1, 'n2': n2, 'n3': n3},
          conexiones: {'c1': conn},
        );

        // Attempting to connect from n3 to n1 (which is an origin) must be blocked!
        final result = policy.canCreateConnection(
          grafo,
          'n3',
          'n1',
          Direccion.unidireccional,
        );
        expect(result.allowed, isFalse);
        expect(result.message, contains('actúa como Origen'));
      },
    );

    test('allows valid bipartite connections (multiple origins to same destination, origin to multiple destinations)', () {
      const n1 = Nodo(id: 'n1', nombre: 'Nodo 1', colorValue: 0, x: 0, y: 0);
      const n2 = Nodo(
        id: 'n2',
        nombre: 'Nodo 2',
        colorValue: 0,
        x: 100,
        y: 100,
      );
      const n3 = Nodo(
        id: 'n3',
        nombre: 'Nodo 3',
        colorValue: 0,
        x: 200,
        y: 200,
      );
      const n4 = Nodo(
        id: 'n4',
        nombre: 'Nodo 4',
        colorValue: 0,
        x: 300,
        y: 300,
      );

      final conn1 = Conexion(
        id: 'c1',
        nodoOrigenId: 'n1',
        nodoDestinoId: 'n2',
        direccion: Direccion.unidireccional,
        colorValue: 0,
      );

      final grafo = Grafo(
        nodos: {'n1': n1, 'n2': n2, 'n3': n3, 'n4': n4},
        conexiones: {'c1': conn1},
      );

      // n1 (origin) -> n4 (neutral): should be allowed!
      final result1 = policy.canCreateConnection(
        grafo,
        'n1',
        'n4',
        Direccion.unidireccional,
      );
      expect(result1.allowed, isTrue);

      // n3 (neutral) -> n2 (destination): should be allowed!
      final result2 = policy.canCreateConnection(
        grafo,
        'n3',
        'n2',
        Direccion.unidireccional,
      );
      expect(result2.allowed, isTrue);
    });

    test('denies duplicate and reverse connections', () {
      const n1 = Nodo(id: 'n1', nombre: 'Nodo 1', colorValue: 0, x: 0, y: 0);
      const n2 = Nodo(
        id: 'n2',
        nombre: 'Nodo 2',
        colorValue: 0,
        x: 100,
        y: 100,
      );

      final conn1 = Conexion(
        id: 'c1',
        nodoOrigenId: 'n1',
        nodoDestinoId: 'n2',
        direccion: Direccion.unidireccional,
        colorValue: 0,
      );

      final grafo = Grafo(
        nodos: {'n1': n1, 'n2': n2},
        conexiones: {'c1': conn1},
      );

      // Duplicate n1 -> n2
      final duplicate = policy.canCreateConnection(
        grafo,
        'n1',
        'n2',
        Direccion.unidireccional,
      );
      expect(duplicate.allowed, isFalse);
      expect(duplicate.message, contains('Ya existe una conexión'));

      // Reverse n2 -> n1
      final reverse = policy.canCreateConnection(
        grafo,
        'n2',
        'n1',
        Direccion.unidireccional,
      );
      expect(reverse.allowed, isFalse);
      expect(reverse.message, contains('sentido contrario'));
    });

    test('denies self-loop connection', () {
      const n1 = Nodo(id: 'n1', nombre: 'Nodo 1', colorValue: 0, x: 0, y: 0);

      final grafo = Grafo(nodos: {'n1': n1}, conexiones: const {});

      final result = policy.canCreateConnection(
        grafo,
        'n1',
        'n1',
        Direccion.unidireccional,
      );
      expect(result.allowed, isFalse);
      expect(result.message, contains('no permite auto-conexiones'));
    });

    test('denies bidirectional connections and self loops properties', () {
      expect(policy.allowBidirectional, isFalse);
      expect(policy.allowSelfLoops, isFalse);
      expect(
        policy.allowedDirections(const Grafo(), 'a', 'b'),
        equals([Direccion.unidireccional]),
      );
    });
  });
}
