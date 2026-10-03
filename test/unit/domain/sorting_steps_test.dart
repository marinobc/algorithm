import 'package:flutter_test/flutter_test.dart';
import 'package:nodos/domain/services/sorting_steps.dart';

List<int> valuesInSlotOrder(SortingTimeline timeline) {
  final last = timeline.steps.last;
  final ids = List<int>.generate(timeline.values.length, (index) => index)
    ..sort((left, right) => last.slots[left].compareTo(last.slots[right]));
  return [for (final id in ids) timeline.values[id]];
}

void main() {
  test('Selection Sort records comparisons and a spatial swap', () {
    final timeline = SortingTimeline.build(SortingAlgorithm.selection, [
      8,
      3,
      5,
    ]);
    final swapIndex = timeline.steps.indexWhere(
      (step) => step.phase == SortingPhase.swapping,
    );
    expect(swapIndex, greaterThan(0));
    final before = timeline.steps[swapIndex - 1].slots;
    final after = timeline.steps[swapIndex].slots;
    expect(after[0], before[1]);
    expect(after[1], before[0]);
    expect(timeline.steps.last.comparisons, 3);
    expect(timeline.steps.last.movements, 2);
    expect(valuesInSlotOrder(timeline), [3, 5, 8]);
  });

  test('Insertion Sort raises the key and shifts larger values', () {
    final timeline = SortingTimeline.build(SortingAlgorithm.insertion, [
      5,
      2,
      4,
      2,
    ]);
    final key = timeline.steps.firstWhere(
      (step) => step.phase == SortingPhase.key,
    );
    final shifted = timeline.steps.firstWhere(
      (step) => step.phase == SortingPhase.shifting,
    );
    expect(key.keyRaised, isTrue);
    expect(key.keyId, 1);
    expect(shifted.slots[0], 1);
    expect(shifted.slots[1], 1);
    expect(timeline.steps.last.comparisons, 6);
    expect(timeline.steps.last.movements, 4);
    expect(timeline.steps.last.insertions, 3);
    expect(valuesInSlotOrder(timeline), [2, 2, 4, 5]);
  });

  test(
    'both algorithms handle empty, single, negative and duplicate values',
    () {
      for (final algorithm in SortingAlgorithm.values) {
        for (final values in <List<int>>[
          [],
          [0],
          [1000, -7, 0, -7, 3],
        ]) {
          final timeline = SortingTimeline.build(algorithm, values);
          expect(valuesInSlotOrder(timeline), [...values]..sort());
          expect(timeline.steps.last.phase, SortingPhase.finished);
          expect(timeline.steps.last.sortedCount, values.length);
        }
      }
    },
  );
}
