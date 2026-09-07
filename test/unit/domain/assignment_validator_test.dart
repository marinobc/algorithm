import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/algorithms/assignment/domain/services/assignment_validator.dart';
import 'package:nodos/domain/models/conexion.dart';
import 'package:nodos/domain/models/direccion.dart';
import 'package:nodos/domain/models/grafo.dart';
import 'package:nodos/domain/models/nodo.dart';

void main() {
  group('Domain - Assignment Validator', () {
    test(
      'Detects origin and destination nodes correctly in valid bipartite graph',
      () {
        final o1 = const Nodo(
          id: 'O1',
          nombre: 'Origen 1',
          colorValue: 0,
          x: 0,
          y: 0,
        );
        final o2 = const Nodo(
          id: 'O2',
          nombre: 'Origen 2',
          colorValue: 0,
          x: 0,
          y: 0,
        );
        final d1 = const Nodo(
          id: 'D1',
          nombre: 'Destino 1',
          colorValue: 0,
          x: 100,
          y: 100,
        );
        final d2 = const Nodo(
          id: 'D2',
          nombre: 'Destino 2',
          colorValue: 0,
          x: 100,
          y: 100,
        );

        final c1 = const Conexion(
          id: 'c1',
          nodoOrigenId: 'O1',
          nodoDestinoId: 'D1',
          colorValue: 0,
          direccion: Direccion.unidireccional,
        );
        final c2 = const Conexion(
          id: 'c2',
          nodoOrigenId: 'O2',
          nodoDestinoId: 'D2',
          colorValue: 0,
          direccion: Direccion.unidireccional,
        );

        final grafo = Grafo(
          nodos: {'O1': o1, 'O2': o2, 'D1': d1, 'D2': d2},
          conexiones: {'c1': c1, 'c2': c2},
        );

        final result = TransportationValidator.validate(grafo);
        expect(result.isValid, isTrue);
        expect(result.origins.map((n) => n.id), containsAll(['O1', 'O2']));
        expect(result.destinations.map((n) => n.id), containsAll(['D1', 'D2']));
      },
    );

    test('Fails validation and returns error message when origin has incoming connection', () {
      final o1 = const Nodo(
        id: 'O1',
        nombre: 'Planta A',
        colorValue: 0,
        x: 0,
        y: 0,
      );
      final o2 = const Nodo(
        id: 'O2',
        nombre: 'Planta B',
        colorValue: 0,
        x: 0,
        y: 0,
      );
      final d1 = const Nodo(
        id: 'D1',
        nombre: 'Destino 1',
        colorValue: 0,
        x: 100,
        y: 100,
      );

      final c1 = const Conexion(
        id: 'c1',
        nodoOrigenId: 'O1',
        nodoDestinoId: 'O2',
        colorValue: 0,
        direccion: Direccion.unidireccional,
      );
      final c2 = const Conexion(
        id: 'c2',
        nodoOrigenId: 'O2',
        nodoDestinoId: 'D1',
        colorValue: 0,
        direccion: Direccion.unidireccional,
      );

      final grafo = Grafo(
        nodos: {'O1': o1, 'O2': o2, 'D1': d1},
        conexiones: {'c1': c1, 'c2': c2},
      );

      final result = TransportationValidator.validate(grafo);
      expect(result.isValid, isFalse);
      expect(
        result.errorMessage,
        startsWith('No se puede aplicar el algoritmo, modifique'),
      );
    });

    test('Fails validation when graph has bidirectional connections', () {
      final o1 = const Nodo(
        id: 'O1',
        nombre: 'Origen A',
        colorValue: 0,
        x: 0,
        y: 0,
      );
      final d1 = const Nodo(
        id: 'D1',
        nombre: 'Destino A',
        colorValue: 0,
        x: 100,
        y: 100,
      );

      final c1 = const Conexion(
        id: 'c1',
        nodoOrigenId: 'O1',
        nodoDestinoId: 'D1',
        colorValue: 0,
        direccion: Direccion.bidireccional,
      );

      final grafo = Grafo(nodos: {'O1': o1, 'D1': d1}, conexiones: {'c1': c1});

      final result = TransportationValidator.validate(grafo);
      expect(result.isValid, isFalse);
      expect(
        result.errorMessage,
        contains('No se puede aplicar el algoritmo, modifique'),
      );
    });
  });
}
