import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../algorithms/assignment/domain/policy/assignment_graph_policy.dart';
import '../../algorithms/assignment/providers/assignment_provider.dart';
import '../../algorithms/assignment/ui/assignment_matrix_screen.dart';
import '../../algorithms/core/algorithm_registry.dart';
import '../../algorithms/johnson/providers/johnson_provider.dart';
import '../../algorithms/northwest/domain/services/northwest_problem_extractor.dart';
import '../../algorithms/northwest/providers/northwest_provider.dart';
import '../../algorithms/northwest/ui/northwest_matrix_screen.dart';
import '../../application/providers/config_provider.dart';
import '../../application/providers/grafo_invalido_provider.dart';
import '../../application/providers/grafo_provider.dart';
import '../../debug/graph_debug_fab.dart';
import '../dialogs/matrix_view_coordinator.dart';
import 'algorithm_optimize_action.dart';

/// Floating Action Buttons for Undo, Redo, and Reset View placed on the bottom left side of the canvas.
class UndoRedoCanvasFabs extends ConsumerWidget {
  final VoidCallback onResetView;

  const UndoRedoCanvasFabs({super.key, required this.onResetView});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(grafoProvider);
    final notifier = ref.read(grafoProvider.notifier);
    final canUndo = notifier.puedeDeshacer;
    final canRedo = notifier.puedeRehacer;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
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
      ],
    );
  }
}

class CanvasControlsFabs extends ConsumerWidget {
  const CanvasControlsFabs({super.key});

  Future<void> _runOptimizar(BuildContext context, WidgetRef ref) async {
    await runActiveAlgorithm(context, ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(grafoProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final mostrarDebug = ref.watch(configProvider).mostrarBotonesDebug;
    final activeAlgo = ref.watch(activeAlgorithmProvider);

    bool isAlgoValid = true;
    if (activeAlgo != null) {
      if (activeAlgo.id == AlgorithmRegistry.assignmentId) {
        isAlgoValid = ref.watch(transportationValidationProvider).isValid;
      } else if (activeAlgo.id == AlgorithmRegistry.johnsonId) {
        isAlgoValid = ref.watch(johnsonValidationProvider).isValid;
      } else if (activeAlgo.id == AlgorithmRegistry.northwestId) {
        isAlgoValid = ref.watch(northwestValidationProvider).isValid;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (activeAlgo?.id == AlgorithmRegistry.northwestId) ...[
          FloatingActionButton.small(
            heroTag: 'fab_northwest_data_entry',
            tooltip: 'Ingresar datos de transporte',
            elevation: 2,
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            onPressed: () => NorthwestMatrixScreen.open(context),
            child: const Icon(Icons.edit_note_rounded, size: 20),
          ),
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              final graph = ref.watch(grafoProvider);
              final canViewGraphMatrix =
                  graph.nodos.values.any(
                    (node) =>
                        node.rol == NorthwestRoles.origin ||
                        node.rol == 'origen',
                  ) &&
                  graph.nodos.values.any(
                    (node) =>
                        node.rol == NorthwestRoles.destination ||
                        node.rol == 'destino',
                  );
              return FloatingActionButton.small(
                heroTag: 'fab_northwest_graph_matrix',
                tooltip: canViewGraphMatrix
                    ? 'Ver matriz del grafo'
                    : 'Agrega un origen y un destino para ver la matriz',
                elevation: canViewGraphMatrix ? 2 : 0,
                backgroundColor: canViewGraphMatrix
                    ? colorScheme.secondaryContainer
                    : colorScheme.surfaceContainerLow,
                foregroundColor: canViewGraphMatrix
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurface.withValues(alpha: 0.38),
                onPressed: canViewGraphMatrix
                    ? () => MatrixViewCoordinator.openGraphMatrix(context, ref)
                    : null,
                child: const Icon(Icons.grid_on_rounded, size: 20),
              );
            },
          ),
          const SizedBox(height: 10),
        ] else if (activeAlgo?.id == AlgorithmRegistry.assignmentId) ...[
          FloatingActionButton.small(
            heroTag: 'fab_assignment_data_entry',
            tooltip: 'Ingresar matriz de asignación',
            elevation: 2,
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            onPressed: () => AssignmentMatrixScreen.open(context),
            child: const Icon(Icons.edit_note_rounded, size: 20),
          ),
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              final graph = ref.watch(grafoProvider);
              final canViewGraphMatrix =
                  graph.nodos.values.any(
                    (node) => node.rol == AssignmentRoles.origin,
                  ) &&
                  graph.nodos.values.any(
                    (node) => node.rol == AssignmentRoles.destination,
                  );
              return FloatingActionButton.small(
                heroTag: 'fab_assignment_graph_matrix',
                tooltip: canViewGraphMatrix
                    ? 'Ver matriz del grafo'
                    : 'Agrega un origen y un destino para ver la matriz',
                elevation: canViewGraphMatrix ? 2 : 0,
                backgroundColor: canViewGraphMatrix
                    ? colorScheme.secondaryContainer
                    : colorScheme.surfaceContainerLow,
                foregroundColor: canViewGraphMatrix
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurface.withValues(alpha: 0.38),
                onPressed: canViewGraphMatrix
                    ? () => MatrixViewCoordinator.openGraphMatrix(context, ref)
                    : null,
                child: const Icon(Icons.grid_on_rounded, size: 20),
              );
            },
          ),
          const SizedBox(height: 10),
        ] else if (activeAlgo != null && activeAlgo.supportsMatrix) ...[
          Builder(
            builder: (context) {
              final enabled = isAlgoValid;
              return FloatingActionButton.small(
                heroTag: 'fab_algo_matrix_view',
                tooltip: isAlgoValid
                    ? 'Ver Matriz de ${activeAlgo.shortName}'
                    : 'Conecte o corrija el grafo para ver la matriz',
                elevation: enabled ? 2 : 0,
                backgroundColor: enabled
                    ? colorScheme.secondaryContainer
                    : colorScheme.surfaceContainerLow,
                foregroundColor: enabled
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurface.withValues(alpha: 0.38),
                onPressed: enabled
                    ? () => MatrixViewCoordinator.openMatrix(context, ref)
                    : null,
                child: const Icon(Icons.grid_on_rounded, size: 20),
              );
            },
          ),
          const SizedBox(height: 10),
        ],

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
            tooltip:
                (activeAlgo.id == AlgorithmRegistry.northwestId ||
                        activeAlgo.id == AlgorithmRegistry.assignmentId) &&
                    !isAlgoValid
                ? 'Configura una matriz de ${activeAlgo.shortName.toLowerCase()} válida para optimizar'
                : 'Ejecutar / Optimizar Algoritmo',
            elevation:
                (activeAlgo.id == AlgorithmRegistry.northwestId ||
                        activeAlgo.id == AlgorithmRegistry.assignmentId) &&
                    !isAlgoValid
                ? 0
                : 4,
            backgroundColor:
                (activeAlgo.id == AlgorithmRegistry.northwestId ||
                        activeAlgo.id == AlgorithmRegistry.assignmentId) &&
                    !isAlgoValid
                ? colorScheme.surfaceContainerLow
                : activeAlgo.themeColor,
            foregroundColor:
                (activeAlgo.id == AlgorithmRegistry.northwestId ||
                        activeAlgo.id == AlgorithmRegistry.assignmentId) &&
                    !isAlgoValid
                ? colorScheme.onSurface.withValues(alpha: 0.38)
                : Colors.white,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text(
              'Optimizar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed:
                (activeAlgo.id == AlgorithmRegistry.northwestId ||
                        activeAlgo.id == AlgorithmRegistry.assignmentId) &&
                    !isAlgoValid
                ? null
                : () => _runOptimizar(context, ref),
          ),
      ],
    );
  }
}
