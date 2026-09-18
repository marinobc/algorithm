import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../algorithms/core/algorithm_registry.dart';
import '../../application/providers/grafo_invalido_provider.dart';
import '../widgets/app_toast.dart';
import 'adjacency_matrix_dialog.dart';

/// Central coordinator for launching matrix screens depending on the active algorithm mode.
class MatrixViewCoordinator {
  /// Opens the matrix screen corresponding to the currently active algorithm,
  /// or the general Adjacency Matrix if in Free Mode.
  static void openMatrix(BuildContext context, WidgetRef ref) {
    final activeAlgo = ref.read(activeAlgorithmProvider);

    // 1. Free Mode: uses standard complete adjacency matrix
    if (activeAlgo == null) {
      final esInvalido = ref.read(esGrafoInvalidoProvider);
      if (esInvalido) {
        AppToast.show(
          context,
          'Conecta el grafo para poder ver la matriz.',
          icon: Icons.hub_outlined,
        );
        return;
      }
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AdjacencyMatrixScreen()));
      return;
    }

    // 2. Algorithm does NOT support matrix (e.g. Johnson)
    if (!activeAlgo.supportsMatrix) {
      final reason =
          activeAlgo.matrixUnavailableReason ??
          'Este algoritmo no utiliza matriz de adyacencia.';
      AppToast.show(
        context,
        reason,
        icon: Icons.info_outline_rounded,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // 3. Algorithm supports matrix: build screen via polymorphic contract
    final screen = activeAlgo.buildMatrixScreen(context, ref);
    if (screen != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    } else {
      // Fallback if null was returned
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AdjacencyMatrixScreen()));
    }
  }
}
