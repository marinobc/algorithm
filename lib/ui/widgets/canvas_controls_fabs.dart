import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../algorithms/assignment/domain/models/assignment_models.dart';
import '../../algorithms/assignment/providers/assignment_provider.dart';
import '../../algorithms/johnson/providers/johnson_provider.dart';
import '../../application/providers/grafo_provider.dart';
import '../../debug/graph_debug_fab.dart';

class CanvasControlsFabs extends ConsumerWidget {
  final VoidCallback onResetView;

  const CanvasControlsFabs({super.key, required this.onResetView});

  void _showAlgorithmBottomSheet(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final activeState = ref.watch(transportationNotifierProvider);
        final currentMethod = activeState.selectedMethod;
        final johnsonState = ref.watch(johnsonNotifierProvider);

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.alt_route_rounded,
                        color: colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seleccionar Algoritmo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Selecciona el algoritmo a ejecutar en el lienzo',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // 1. Assignment Algorithm Card
                ...TransportationMethod.values.map((method) {
                  final isSelected =
                      activeState.isActive && currentMethod == method;

                  return Card(
                    elevation: 0,
                    color: isSelected
                        ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                        : colorScheme.surfaceContainerLow,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Icon(
                        Icons.alt_route_rounded,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      title: Text(
                        method.displayName,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        'Resuelve optimización de asignación.',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: colorScheme.primary,
                            )
                          : Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        final validation = ref.read(
                          transportationValidationProvider,
                        );
                        if (!validation.isValid) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                validation.errorMessage ??
                                    'Grafo no válido para asignación.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        // Deactivate other algorithms
                        ref
                            .read(johnsonNotifierProvider.notifier)
                            .setActive(false);
                        final notifier = ref.read(
                          transportationNotifierProvider.notifier,
                        );
                        notifier.setMethod(method);
                        notifier.setActive(true);
                      },
                    ),
                  );
                }),

                // 2. Johnson's Algorithm Card
                Card(
                  elevation: 0,
                  color: johnsonState.isActive
                      ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                      : colorScheme.surfaceContainerLow,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: johnsonState.isActive
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      width: johnsonState.isActive ? 1.5 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Icon(
                      Icons.timeline_rounded,
                      color: johnsonState.isActive
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      'Algoritmo de Johnson',
                      style: TextStyle(
                        fontWeight: johnsonState.isActive
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: johnsonState.isActive
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'Calcula tiempos tempranos, tardíos, holgura y ruta crítica.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: johnsonState.isActive
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: colorScheme.primary,
                          )
                        : Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      final validation = ref.read(johnsonValidationProvider);
                      if (!validation.isValid) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              validation.errorMessage ?? 'Grafo no válido para el algoritmo de Johnson.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      // Deactivate other algorithms
                      ref
                          .read(transportationNotifierProvider.notifier)
                          .setActive(false);
                      ref
                          .read(johnsonNotifierProvider.notifier)
                          .setActive(true);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(grafoProvider);
    final notifier = ref.read(grafoProvider.notifier);
    final canUndo = notifier.puedeDeshacer;
    final canRedo = notifier.puedeRehacer;
    final colorScheme = Theme.of(context).colorScheme;

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

        // Center FAB
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

        // Debug FAB for exporting/copying graph test data
        const GraphDebugFab(),
        const SizedBox(height: 10),

        // Algoritmos FAB to select algorithm via bottom-to-top modal sheet
        FloatingActionButton.extended(
          heroTag: 'fab_algoritmos',
          tooltip: 'Seleccionar Algoritmo',
          elevation: 4,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          icon: const Icon(Icons.alt_route_rounded),
          label: const Text(
            'Algoritmos',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () => _showAlgorithmBottomSheet(context, ref),
        ),
      ],
    );
  }
}
