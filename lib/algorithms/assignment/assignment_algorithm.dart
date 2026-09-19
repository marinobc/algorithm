import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/grafo_provider.dart';
import '../../domain/models/conexion.dart';
import '../../domain/models/nodo.dart';
import '../../ui/dialogs/connection_value_input_dialog.dart';
import '../core/graph_algorithm.dart';
import 'domain/policy/assignment_graph_policy.dart';
import 'providers/assignment_provider.dart';
import 'ui/assignment_algorithm_card.dart';
import 'ui/assignment_canvas_controls.dart';
import 'ui/assignment_graph_matrix_screen.dart';
import 'ui/assignment_launch_button.dart';

/// Pluggable GraphAlgorithm implementation for Assignment / Hungarian method.
class AssignmentAlgorithm implements GraphAlgorithm {
  static const String algorithmId = 'assignment';

  const AssignmentAlgorithm();

  @override
  String get id => algorithmId;

  @override
  String get name => 'Algoritmo de Asignación';

  @override
  String get shortName => 'Asignación';

  @override
  String get description =>
      'Problema de asignación y transporte bipartito resuelto con el Algoritmo Húngaro.';

  @override
  IconData get icon => Icons.assignment_turned_in_rounded;

  @override
  Color get themeColor => const Color(0xFF7C4DFF);

  @override
  GraphAlgorithmPolicy get policy => const AssignmentGraphPolicy();

  @override
  Widget buildLaunchButton(BuildContext context, WidgetRef ref) {
    return const AssignmentLaunchButton();
  }

  @override
  Widget? buildCanvasControls(BuildContext context, WidgetRef ref) {
    return const AssignmentCanvasControls();
  }

  @override
  Map<String, dynamic>? newNodeParams(WidgetRef ref) => {
    'role': ref.read(assignmentActiveRoleProvider),
    'rol': ref.read(assignmentActiveRoleProvider),
  };

  @override
  Widget? buildEmptyState(BuildContext context, WidgetRef ref) => null;

  @override
  Widget? buildAlgorithmCard(BuildContext context, WidgetRef ref) {
    final validation = ref.watch(transportationValidationProvider);
    final state = ref.watch(transportationNotifierProvider);

    if (state.isActive && validation.isValid) {
      return const AssignmentAlgorithmCard();
    }
    return null;
  }

  @override
  Widget? buildNodeEditControls(
    BuildContext context,
    WidgetRef ref,
    Nodo nodo,
  ) {
    final grafo = ref.watch(grafoProvider);
    final outD = grafo.conexiones.values
        .where((c) => c.nodoOrigenId == nodo.id)
        .length;
    final inD = grafo.conexiones.values
        .where((c) => c.nodoDestinoId == nodo.id)
        .length;

    String roleTitle;
    String roleDesc;
    Color roleColor;
    IconData roleIcon;

    if (inD == 0 && outD > 0) {
      roleTitle = 'Origen (detectado)';
      roleDesc =
          'Este nodo emite $outD ${outD == 1 ? "conexión" : "conexiones"}.';
      roleColor = const Color(AssignmentRoles.originColor);
      roleIcon = Icons.outbox_rounded;
    } else if (outD == 0 && inD > 0) {
      roleTitle = 'Destino (detectado)';
      roleDesc =
          'Este nodo recibe $inD ${inD == 1 ? "conexión" : "conexiones"}.';
      roleColor = const Color(AssignmentRoles.destinationColor);
      roleIcon = Icons.move_to_inbox_rounded;
    } else if (inD == 0 && outD == 0) {
      roleTitle = 'Sin conectar';
      roleDesc = 'El rol se detectará automáticamente al conectar este nodo.';
      roleColor = Colors.grey;
      roleIcon = Icons.help_outline_rounded;
    } else {
      roleTitle = 'Intermedio (Inválido)';
      roleDesc = 'No puede recibir y emitir conexiones simultáneamente.';
      roleColor = Colors.redAccent;
      roleIcon = Icons.error_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: roleColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: roleColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(roleIcon, color: roleColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roleTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: roleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  roleDesc,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get supportsMatrix => true;

  @override
  String? get matrixUnavailableReason => null;

  @override
  Widget? buildMatrixScreen(BuildContext context, WidgetRef ref) {
    return const AssignmentGraphMatrixScreen();
  }

  @override
  Future<bool?> showConnectionValueInputDialog(
    BuildContext context,
    WidgetRef ref,
    Conexion conexion,
  ) {
    return ConnectionValueInputDialog.show(
      context: context,
      ref: ref,
      conexion: conexion,
      title: 'Costo de Conexión (Asignación)',
      valueLabel: 'Costo de Asignación',
    );
  }

  @override
  Future<void> onConnectionCreated(
    BuildContext context,
    WidgetRef ref,
    Conexion conexion,
  ) {
    // Opens the single-connection value input popup (pre-filled with default),
    // allowing the user to set the cost immediately after creating the connection.
    showConnectionValueInputDialog(context, ref, conexion);
    return Future.value();
  }

  @override
  Future<void> onNodeCreated(BuildContext context, WidgetRef ref, Nodo nodo) =>
      Future.value();
}
