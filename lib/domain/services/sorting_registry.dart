import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'algorithms/sorting_algorithms.dart';
import 'base_sorting_algorithm.dart';

/// Central registry managing all registered sorting algorithms.
class SortingRegistry {
  static const BaseSortingAlgorithm selection = SelectionSortAlgorithm();
  static const BaseSortingAlgorithm insertion = InsertionSortAlgorithm();

  static final List<BaseSortingAlgorithm> registeredAlgorithms = [
    selection,
    insertion,
  ];

  static BaseSortingAlgorithm? findById(String? id) {
    if (id == null) return null;
    try {
      return registeredAlgorithms.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Provider exposing the list of all registered sorting algorithms.
final sortingRegistryProvider = Provider<List<BaseSortingAlgorithm>>((ref) {
  return SortingRegistry.registeredAlgorithms;
});

/// Notifier managing the currently active sorting algorithm in the application.
class ActiveSortingAlgorithmNotifier extends Notifier<BaseSortingAlgorithm> {
  @override
  BaseSortingAlgorithm build() => SortingRegistry.selection;

  void selectAlgorithm(BaseSortingAlgorithm algorithm) {
    state = algorithm;
  }

  void selectById(String id) {
    final algo = SortingRegistry.findById(id);
    if (algo != null) {
      state = algo;
    }
  }
}

final activeSortingAlgorithmProvider =
    NotifierProvider<ActiveSortingAlgorithmNotifier, BaseSortingAlgorithm>(() {
      return ActiveSortingAlgorithmNotifier();
    });
