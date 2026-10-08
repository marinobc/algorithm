import 'package:flutter/material.dart';

import 'sorting_steps.dart';

/// Abstract strategy contract for all sorting algorithms.
abstract class BaseSortingAlgorithm {
  final String id;
  final String name;
  final String description;
  final Color accentColor;

  const BaseSortingAlgorithm({
    required this.id,
    required this.name,
    required this.description,
    required this.accentColor,
  });

  /// Builds a step-by-step [SortingTimeline] for the provided [input] values.
  SortingTimeline buildTimeline(List<int> input);

  /// Returns a human-readable display label for a given [SortingPhase].
  String formatPhase(SortingPhase phase) => switch (phase) {
    SortingPhase.ready => 'LISTO',
    SortingPhase.current => 'POSICIÓN ACTUAL',
    SortingPhase.comparing => 'COMPARANDO',
    SortingPhase.minimum => 'NUEVO MÍNIMO',
    SortingPhase.swapping => 'INTERCAMBIO',
    SortingPhase.sorted => 'REGIÓN ORDENADA',
    SortingPhase.key => 'ELEMENTO CLAVE',
    SortingPhase.shifting => 'DESPLAZAMIENTO',
    SortingPhase.inserting => 'INSERCIÓN',
    SortingPhase.finished => 'TERMINADO',
  };
}
