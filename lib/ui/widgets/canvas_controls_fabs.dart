import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../algorithms/assignment/providers/assignment_provider.dart';
import '../../algorithms/core/algorithm_registry.dart';
import '../../algorithms/johnson/providers/johnson_provider.dart';
import '../../application/providers/config_provider.dart';
import '../../application/providers/grafo_provider.dart';
import '../../debug/graph_debug_fab.dart';

class CanvasControlsFabs extends ConsumerWidget {
  final VoidCallback onResetView;

  const CanvasControlsFabs({super.key, required this.onResetView});

  void _runOptimizar(BuildContext context, WidgetRef ref) {
    final activeAlgo = ref.read(activeAlgorithmProvider);

    if (activeAlgo == null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Seleccione un tipo de algoritmo en la barra superior para optimizar.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (activeAlgo.id == AlgorithmRegistry.assignmentId) {
      final validation = ref.read(transportationValidationProvider);
      if (!validation.isValid) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              validation.errorMessage ??
                  'Grafo no válido para el algoritmo de Asignación.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      ref.read(johnsonNotifierProvider.notifier).setActive(false);
      ref.read(transportationNotifierProvider.notifier).setActive(true);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Optimizando con Algoritmo de Asignación...'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } else if (activeAlgo.id == AlgorithmRegistry.johnsonId) {
      final validation = ref.read(johnsonValidationProvider);
      if (!validation.isValid) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              validation.errorMessage ??
                  'Grafo no válido para el algoritmo de Johnson.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      ref.read(transportationNotifierProvider.notifier).setActive(false);
      ref.read(johnsonNotifierProvider.notifier).setActive(true);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Optimizando con Algoritmo de Johnson...'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
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

        // Optimizar FAB that automatically runs only the assigned algorithm to the canvas
        FloatingActionButton.extended(
          heroTag: 'fab_optimizar',
          tooltip: 'Ejecutar / Optimizar Algoritmo',
          elevation: 4,
          backgroundColor: activeAlgo != null
              ? activeAlgo.themeColor
              : colorScheme.primary,
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
