import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/grafo_provider.dart';
import '../domain/policy/assignment_graph_policy.dart';

/// Floating canvas status pill displayed when the Assignment Algorithm
/// mode is active. Informs the user of the automatically detected Origins and
/// Destinations based on current graph topology.
class AssignmentCanvasControls extends ConsumerWidget {
  const AssignmentCanvasControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grafo = ref.watch(grafoProvider);

    int originCount = 0;
    int destCount = 0;
    for (final node in grafo.nodos.values) {
      final outD = grafo.conexiones.values
          .where((c) => c.nodoOrigenId == node.id)
          .length;
      final inD = grafo.conexiones.values
          .where((c) => c.nodoDestinoId == node.id)
          .length;

      if (inD == 0 && outD > 0) {
        originCount++;
      } else if (outD == 0 && inD > 0) {
        destCount++;
      }
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF7C4DFF).withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.assignment_turned_in_rounded,
              color: Color(0xFF7C4DFF),
              size: 18,
            ),
            const SizedBox(width: 8),
            const Text(
              'Asignación:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),

            // Detected Origins Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(AssignmentRoles.originColor)
                    .withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(AssignmentRoles.originColor)
                      .withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(AssignmentRoles.originColor),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Orígenes: $originCount',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(AssignmentRoles.originColor),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            // Detected Destinations Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(AssignmentRoles.destinationColor)
                    .withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(AssignmentRoles.destinationColor)
                      .withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(AssignmentRoles.destinationColor),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Destinos: $destCount',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(AssignmentRoles.destinationColor),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            // Help info tooltip
            Tooltip(
              message:
                  'Detección automática:\n'
                  '• Los nodos que emiten conexiones actúan como Orígenes.\n'
                  '• Los nodos que reciben conexiones actúan como Destinos.\n'
                  '• Se impiden conexiones inválidas entre nodos del mismo rol.',
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              showDuration: const Duration(seconds: 4),
              child: Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
