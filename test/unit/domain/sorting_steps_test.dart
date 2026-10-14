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
    'all algorithms handle empty, single, negative and duplicate values',
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

  test('Shell Sort follows Knuth gaps and counts real operations', () {
    final timeline = SortingTimeline.build(SortingAlgorithm.shell, [
      8,
      7,
      6,
      5,
      4,
      3,
      2,
      1,
    ]);
    final gaps = timeline.steps
        .where((step) => step.phase == SortingPhase.gap)
        .map((step) => step.gap)
        .toList();
    expect(gaps, [4, 1]);
    final last = timeline.steps.last;
    expect(last.comparisons, greaterThan(0));
    expect(last.movements, greaterThan(0));
    expect(last.insertions, greaterThan(0));
    expect(
      timeline.steps.where((s) => s.phase == SortingPhase.comparing).length,
      last.comparisons,
    );
    expect(
      timeline.steps.where((s) => s.phase == SortingPhase.shifting).length,
      last.movements,
    );
    expect(valuesInSlotOrder(timeline), [1, 2, 3, 4, 5, 6, 7, 8]);
  });

  test('Merge Sort splits, compares and writes every merged element', () {
    final timeline = SortingTimeline.build(SortingAlgorithm.merge, [
      4,
      1,
      3,
      2,
    ]);
    expect(
      timeline.steps.where((s) => s.phase == SortingPhase.splitting).length,
      3,
    );
    final last = timeline.steps.last;
    expect(last.comparisons, 5);
    expect(last.writes, 8);
    expect(
      timeline.steps
          .where((s) => s.phase == SortingPhase.mergeComparing)
          .length,
      last.comparisons,
    );
    expect(
      timeline.steps.where((s) => s.phase == SortingPhase.mergeWriting).length,
      last.writes,
    );
    expect(valuesInSlotOrder(timeline), [1, 2, 3, 4]);
  });

  test('Merge shows real left and right recursion before the final fusion', () {
    for (final input in <List<int>>[
      [4, 1, 3, 2],
      [5, 1, 4, 2, 3],
      [1, 2, 3, 4, 5],
      [5, 4, 3, 2, 1],
      [3, 1, 3, 2, 1],
    ]) {
      final timeline = SortingTimeline.build(SortingAlgorithm.merge, input);
      final steps = timeline.steps;
      final division = steps.indexWhere(
        (s) => s.mergeState?.stage == SortingMergeStage.division,
      );
      final left = steps.indexWhere(
        (s) => s.mergeState?.stage == SortingMergeStage.left,
      );
      final right = steps.indexWhere(
        (s) => s.mergeState?.stage == SortingMergeStage.right,
      );
      final fusion = steps.indexWhere(
        (s) => s.mergeState?.stage == SortingMergeStage.fusion,
      );
      final result = steps.indexWhere(
        (s) => s.mergeState?.stage == SortingMergeStage.result,
      );
      expect(division, greaterThan(0));
      expect(division, lessThan(left));
      expect(left, lessThan(right));
      expect(right, lessThan(fusion));
      expect(fusion, lessThan(result));
      expect(
        steps
            .sublist(left, right)
            .any((s) => s.phase == SortingPhase.mergeWriting),
        isTrue,
      );
      expect(
        steps
            .sublist(right, fusion)
            .any((s) => s.phase == SortingPhase.mergeWriting),
        isTrue,
      );
      expect(steps[left].mergeState!.leftReady, isFalse);
      expect(steps[right].mergeState!.leftReady, isTrue);
      expect(steps[right].mergeState!.rightReady, isFalse);
      expect(steps[fusion].mergeState!.rightReady, isTrue);
      final leftIds = steps[fusion].mergeState!.rootLeftIds;
      final rightIds = steps[fusion].mergeState!.rootRightIds;
      final leftValues = [for (final id in leftIds) input[id]];
      final rightValues = [for (final id in rightIds) input[id]];
      expect(leftValues, [...leftValues]..sort());
      expect(rightValues, [...rightValues]..sort());
      expect(valuesInSlotOrder(timeline), [...input]..sort());
      for (var i = 1; i < steps.length; i++) {
        if (steps[i].phase == SortingPhase.mergeFocus) {
          expect(steps[i].comparisons, steps[i - 1].comparisons);
          expect(steps[i].writes, steps[i - 1].writes);
        }
      }
    }
  });

  test(
    'Merge writes one destination per event and preserves duplicate order',
    () {
      final input = [3, 1, 3, 2, 1, 3];
      final timeline = SortingTimeline.build(SortingAlgorithm.merge, input);
      final fusionWrites = timeline.steps
          .where(
            (s) =>
                s.mergeState?.stage == SortingMergeStage.fusion &&
                s.phase == SortingPhase.mergeWriting,
          )
          .toList();
      expect(fusionWrites, hasLength(input.length));
      for (var i = 0; i < fusionWrites.length; i++) {
        final state = fusionWrites[i].mergeState!;
        expect(state.outputIds, hasLength(i + 1));
        expect(state.selectedId, state.outputIds.last);
        expect(state.leftConsumed + state.rightConsumed, i + 1);
      }
      final finalStep = timeline.steps.last;
      final ids = List<int>.generate(input.length, (i) => i)
        ..sort((a, b) => finalStep.slots[a].compareTo(finalStep.slots[b]));
      expect([for (final id in ids) input[id]], [1, 1, 2, 3, 3, 3]);
      expect(
        [
          for (final id in ids)
            if (input[id] == 3) id,
        ],
        [0, 2, 5],
      );
      expect(
        [
          for (final id in ids)
            if (input[id] == 1) id,
        ],
        [1, 4],
      );
    },
  );

  test('all four sort ordered, reversed and deterministic random inputs', () {
    final cases = <List<int>>[
      [1, 2, 3, 4, 5],
      [5, 4, 3, 2, 1],
      [7, -3, 7, 0, 2, -8, 2, 9, 1, 0],
    ];
    for (final values in cases) {
      for (final algorithm in SortingAlgorithm.values) {
        final timeline = SortingTimeline.build(algorithm, values);
        expect(valuesInSlotOrder(timeline), [...values]..sort());
        expect(timeline.values, values);
        expect(timeline.steps.first.comparisons, 0);
        expect(timeline.steps.last.phase, SortingPhase.finished);
        expect(() => timeline.values[0] = 99, throwsUnsupportedError);
      }
    }
  });
}
