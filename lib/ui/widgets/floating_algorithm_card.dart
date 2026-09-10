import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../algorithms/assignment/providers/assignment_provider.dart';
import '../../algorithms/assignment/ui/assignment_algorithm_card.dart';
import '../../algorithms/johnson/providers/johnson_provider.dart';
import '../../algorithms/johnson/ui/johnson_algorithm_card.dart';

/// Top-level high-level UI widget overlay that conditionally renders
/// the active algorithm's card interface on the canvas.
class FloatingAlgorithmCard extends ConsumerWidget {
  const FloatingAlgorithmCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentState = ref.watch(transportationNotifierProvider);
    final assignmentValidation = ref.watch(transportationValidationProvider);

    // 1. If Assignment algorithm is active and valid, render AssignmentAlgorithmCard
    if (assignmentState.isActive && assignmentValidation.isValid) {
      return const AssignmentAlgorithmCard();
    }

    final johnsonState = ref.watch(johnsonNotifierProvider);
    final johnsonValidation = ref.watch(johnsonValidationProvider);

    // 2. If Johnson algorithm is active and valid, render JohnsonAlgorithmCard
    if (johnsonState.isActive && johnsonValidation.isValid) {
      return const JohnsonAlgorithmCard();
    }

    return const SizedBox.shrink();
  }
}
