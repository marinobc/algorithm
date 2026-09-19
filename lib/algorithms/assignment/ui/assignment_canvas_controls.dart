import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/grafo_provider.dart';
import '../domain/policy/assignment_graph_policy.dart';
import '../providers/assignment_provider.dart';

/// Floating canvas status pill displayed when the Assignment Algorithm
/// mode is active. Informs the user of the automatically detected Origins and
/// Destinations based on current graph topology.
class AssignmentCanvasControls extends ConsumerWidget {
  const AssignmentCanvasControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graph = ref.watch(grafoProvider);
    final selectedRole = ref.watch(assignmentActiveRoleProvider);

    int originCount = 0;
    int destCount = 0;
    for (final node in graph.nodos.values) {
      if (node.rol == AssignmentRoles.origin) {
        originCount++;
      } else if (node.rol == AssignmentRoles.destination) {
        destCount++;
      } else {
        final outD = graph.conexiones.values
            .where((c) => c.nodoOrigenId == node.id)
            .length;
        final inD = graph.conexiones.values
            .where((c) => c.nodoDestinoId == node.id)
            .length;

        if (inD == 0 && outD > 0) {
          originCount++;
        } else if (outD == 0 && inD > 0) {
          destCount++;
        }
      }
    }

    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nuevo nodo (Asignación)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 7),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: AssignmentRoles.origin,
                  icon: const Icon(Icons.outbox_rounded, size: 17),
                  label: Text('Origen ($originCount)'),
                ),
                ButtonSegment(
                  value: AssignmentRoles.destination,
                  icon: const Icon(Icons.move_to_inbox_rounded, size: 17),
                  label: Text('Destino ($destCount)'),
                ),
              ],
              selected: {selectedRole},
              onSelectionChanged: (selection) => ref
                  .read(assignmentActiveRoleProvider.notifier)
                  .setRole(selection.first),
            ),
          ],
        ),
      ),
    );
  }
}
