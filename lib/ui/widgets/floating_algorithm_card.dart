import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../algorithms/assignment/providers/assignment_provider.dart';
import '../../algorithms/assignment/ui/assignment_algorithm_card.dart';

/// Top-level high-level UI widget overlay that conditionally renders
/// the active algorithm's card interface on the canvas.
class FloatingAlgorithmCard extends ConsumerWidget {
  const FloatingAlgorithmCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentState = ref.watch(transportationNotifierProvider);
    final assignmentValidation = ref.watch(transportationValidationProvider);

    // If Assignment algorithm is active and valid, render AssignmentAlgorithmCard
    if (assignmentState.isActive && assignmentValidation.isValid) {
      return const AssignmentAlgorithmCard();
    }

    // Future algorithms (e.g. Dijkstra, Shortest Path) will be checked here seamlessly:
    // if (dijkstraState.isActive) return const DijkstraAlgorithmCard();

    return const SizedBox.shrink();
  }
}
