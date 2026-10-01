import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/domain/services/node_name_deduplicator.dart';

void main() {
  group('NodeNameDeduplicator', () {
    test('returns original name when no collision exists', () {
      final existing = ['Nodo 1', 'Nodo 2'];
      final result = NodeNameDeduplicator.deduplicateName('Nodo 3', existing);
      expect(result, equals('Nodo 3'));
    });

    test('appends (1) on first collision with space', () {
      final existing = ['Nodo 1'];
      final result = NodeNameDeduplicator.deduplicateName('Nodo 1', existing);
      expect(result, equals('Nodo 1 (1)'));
    });

    test('increments counter to (2) when (1) already exists', () {
      final existing = ['A', 'A (1)'];
      final result = NodeNameDeduplicator.deduplicateName('A', existing);
      expect(result, equals('A (2)'));
    });

    test('handles batch list with duplicate names', () {
      final input = ['Origen', 'Origen', 'Origen', 'Destino', 'Destino'];
      final result = NodeNameDeduplicator.deduplicateNameList(input);
      expect(
        result,
        equals(['Origen', 'Origen (1)', 'Origen (2)', 'Destino', 'Destino (1)']),
      );
    });

    test('batch list respects existing graph names', () {
      final existing = ['O1', 'O1 (1)'];
      final input = ['O1', 'O2'];
      final result = NodeNameDeduplicator.deduplicateNameList(
        input,
        existingNames: existing,
      );
      expect(result, equals(['O1 (2)', 'O2']));
    });
  });
}
