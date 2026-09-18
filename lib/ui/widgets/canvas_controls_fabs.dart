import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../algorithms/assignment/providers/assignment_provider.dart';
import '../../algorithms/core/algorithm_registry.dart';
import '../../algorithms/johnson/providers/johnson_provider.dart';
import '../../application/providers/config_provider.dart';
import '../../application/providers/grafo_invalido_provider.dart';
import '../../application/providers/grafo_provider.dart';
import '../../debug/graph_debug_fab.dart';
import '../dialogs/matrix_view_coordinator.dart';
import 'app_toast.dart';

class CanvasControlsFabs extends ConsumerWidget {
  final VoidCallback onResetView;

  const CanvasControlsFabs({super.key, required this.onResetView});

  void _runOptimizar(BuildContext context, WidgetRef ref) {
    final activeAlgo = ref.read(activeAlgorithmProvider);

    if (activeAlgo == null) {
      AppToast.show(
        context,
        'Seleccione un tipo de algoritmo en la barra superior para optimizar.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    if (activeAlgo.id == AlgorithmRegistry.assignmentId) {
      final validation = ref.read(transportationValidationProvider);
      if (!validation.isValid) {
        AppToast.show(
          context,
          validation.errorMessage ??
              'Grafo no válido para el algoritmo de Asignación.',
          icon: Icons.warning_amber_rounded,
        );
        return;
      }

      ref.read(johnsonNotifierProvider.notifier).setActive(false);
      ref.read(transportationNotifierProvider.notifier).setActive(true);

      AppToast.show(
        context,
        'Optimizando con Algoritmo de Asignación...',
        icon: Icons.play_arrow_rounded,
        duration: const Duration(seconds: 2),
      );
    } else if (activeAlgo.id == AlgorithmRegistry.johnsonId) {
      final validation = ref.read(johnsonValidationProvider);
      if (!validation.isValid) {
        AppToast.show(
          context,
          validation.errorMessage ??
              'Grafo no válido para el algoritmo de Johnson.',
          icon: Icons.warning_amber_rounded,
        );
        return;
      }

      ref.read(transportationNotifierProvider.notifier).setActive(false);
      ref.read(johnsonNotifierProvider.notifier).setActive(true);

      AppToast.show(
        context,
        'Optimizando con Algoritmo de Johnson...',
        icon: Icons.play_arrow_rounded,
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(grafoProvider);
    final notifier = ref.read(grafoProvider.notifier);
    final canUndo = notifier.puedeDeshacer;
    final canRedo = notifier.puedeRehacer;
    final colorScheme = Theme.of(context).colorScheme;
    final mostrarDebug = ref.watch(configProvider).mostrarBotonesDebug;
    final activeAlgo = ref.watch(activeAlgorithmProvider);

    bool isAlgoValid = true;
    if (activeAlgo != null) {
      if (activeAlgo.id == AlgorithmRegistry.assignmentId) {
        isAlgoValid = ref.watch(transportationValidationProvider).isValid;
      } else if (activeAlgo.id == AlgorithmRegistry.johnsonId) {
        isAlgoValid = ref.watch(johnsonValidationProvider).isValid;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // When in Algorithm mode, show dedicated Matrix FAB if algorithm supports matrix
        if (activeAlgo != null && activeAlgo.supportsMatrix) ...[
          FloatingActionButton.small(
            heroTag: 'fab_algo_matrix_view',
            tooltip: isAlgoValid
                ? 'Ver Matriz de ${activeAlgo.shortName}'
                : 'Conecte o corrija el grafo para ver la matriz',
            elevation: isAlgoValid ? 2 : 0,
            backgroundColor: isAlgoValid
                ? colorScheme.secondaryContainer
                : colorScheme.surfaceContainerLow,
            foregroundColor: isAlgoValid
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurface.withValues(alpha: 0.38),
            onPressed: isAlgoValid
                ? () => MatrixViewCoordinator.openMatrix(context, ref)
                : null,
            child: const Icon(Icons.grid_on_rounded, size: 20),
          ),
          const SizedBox(height: 10),
        ],

        // Undo FAB
        FloatingActionButton.small(
          heroTag: 'fab_undo',
          tooltip: 'Deshacer (Undo)',
          elevation: 2,
          backgroundColor: canUndo
              ? colorScheme.surfaceContainerHigh
              : colorScheme.surfaceContainerLow,
          foregroundColor: canUndo
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.38),
          onPressed: canUndo ? () => notifier.deshacer() : null,
          child: const Icon(Icons.undo_rounded),
        ),
        const SizedBox(height: 10),

        // Redo FAB
        FloatingActionButton.small(
          heroTag: 'fab_redo',
          tooltip: 'Rehacer (Redo)',
          elevation: 2,
          backgroundColor: canRedo
              ? colorScheme.surfaceContainerHigh
              : colorScheme.surfaceContainerLow,
          foregroundColor: canRedo
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.38),
          onPressed: canRedo ? () => notifier.rehacer() : null,
          child: const Icon(Icons.redo_rounded),
        ),
        const SizedBox(height: 10),

        // Reset View FAB
        FloatingActionButton.small(
          heroTag: 'fab_center',
          tooltip: 'Centrar Lienzo (Origen)',
          elevation: 2,
          backgroundColor: colorScheme.surfaceContainerHigh,
          foregroundColor: colorScheme.primary,
          onPressed: onResetView,
          child: const Icon(Icons.center_focus_strong_rounded),
        ),
        const SizedBox(height: 12),

        // Debug FABs (only shown when enabled in config)
        if (mostrarDebug) ...[
          const GraphDebugFab(),
          const SizedBox(height: 10),
        ],

        // When in Modo Libre (activeAlgo == null), show Matriz button
        // When an algorithm is active, show Optimizar button
        if (activeAlgo == null)
          Builder(
            builder: (context) {
              final esInvalido = ref.watch(esGrafoInvalidoProvider);
              final grafo = ref.watch(grafoProvider);
              final isMatrixDisabled = esInvalido || grafo.nodos.isEmpty;

              return FloatingActionButton.extended(
                heroTag: 'fab_matriz',
                tooltip: isMatrixDisabled
                    ? (grafo.nodos.isEmpty
                          ? 'Agregue nodos para ver la matriz'
                          : 'Conecta el grafo para poder ver la matriz')
                    : 'Ver Matriz de Adyacencia',
                elevation: isMatrixDisabled ? 0 : 4,
                backgroundColor: isMatrixDisabled
                    ? colorScheme.surfaceContainerLow
                    : colorScheme.secondaryContainer,
                foregroundColor: isMatrixDisabled
                    ? colorScheme.onSurface.withValues(alpha: 0.38)
                    : colorScheme.onSecondaryContainer,
                icon: const Icon(Icons.grid_on_rounded),
                label: const Text(
                  'Matriz',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: isMatrixDisabled
                    ? null
                    : () => MatrixViewCoordinator.openMatrix(context, ref),
              );
            },
          )
        else
          FloatingActionButton.extended(
            heroTag: 'fab_optimizar',
            tooltip: 'Ejecutar / Optimizar Algoritmo',
            elevation: 4,
            backgroundColor: activeAlgo.themeColor,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text(
              'Optimizar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => _runOptimizar(context, ref),
          ),
      ],
    );
  }
}
