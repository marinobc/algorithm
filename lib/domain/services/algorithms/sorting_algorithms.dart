import 'package:flutter/material.dart';

import '../base_sorting_algorithm.dart';
import '../sorting_steps.dart';

class SelectionSortAlgorithm extends BaseSortingAlgorithm {
  const SelectionSortAlgorithm()
    : super(
        id: 'selection',
        name: 'Selection Sort',
        description:
            'Busca el mínimo y lo intercambia hasta ordenar el conjunto.',
        accentColor: const Color(0xFFFF9100),
      );

  @override
  SortingTimeline buildTimeline(List<int> input) {
    return SortingTimeline.build(SortingAlgorithm.selection, input);
  }
}

class InsertionSortAlgorithm extends BaseSortingAlgorithm {
  const InsertionSortAlgorithm()
    : super(
        id: 'insertion',
        name: 'Insertion Sort',
        description:
            'Inserta cada elemento en una región que ya está ordenada.',
        accentColor: const Color(0xFF00BFA5),
      );

  @override
  SortingTimeline buildTimeline(List<int> input) {
    return SortingTimeline.build(SortingAlgorithm.insertion, input);
  }
}

class ShellSortAlgorithm extends BaseSortingAlgorithm {
  const ShellSortAlgorithm()
    : super(
        id: 'shell',
        name: 'Shell Sort',
        description: 'Ordena por inserción con incrementos de Knuth.',
        accentColor: const Color(0xFF008C9E),
      );

  @override
  SortingTimeline buildTimeline(List<int> input) =>
      SortingTimeline.build(SortingAlgorithm.shell, input);
}

class MergeSortAlgorithm extends BaseSortingAlgorithm {
  const MergeSortAlgorithm()
    : super(
        id: 'merge',
        name: 'Merge Sort',
        description: 'Divide el conjunto y fusiona mitades ordenadas.',
        accentColor: const Color(0xFFE17237),
      );

  @override
  SortingTimeline buildTimeline(List<int> input) =>
      SortingTimeline.build(SortingAlgorithm.merge, input);
}
