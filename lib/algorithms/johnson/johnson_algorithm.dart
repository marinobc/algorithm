import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/conexion.dart';
import '../../domain/models/nodo.dart';
import '../../ui/dialogs/connection_value_input_dialog.dart';
import '../core/graph_algorithm.dart';
import '../core/models/algorithm_step.dart';
import 'domain/policy/johnson_graph_policy.dart';
import 'providers/johnson_provider.dart';

import 'ui/johnson_algorithm_card.dart';
import 'ui/johnson_canvas_controls.dart';
import 'ui/johnson_launch_button.dart';

/// Pluggable GraphAlgorithm implementation for Johnson / CPM (Critical Path Method).
class JohnsonAlgorithm implements GraphAlgorithm {
  static const String algorithmId = 'johnson';

  const JohnsonAlgorithm();

  @override
  String get id => algorithmId;

  @override
  String get name => 'Johnson';

  @override
  String get shortName => 'Johnson';

  @override
  String get description =>
      'Ruta Crítica (CPM) y holguras sobre redes de actividades dirigidas acíclicas (DAG).';

  @override
  IconData get icon => Icons.alt_route_rounded;

  @override
  Color get themeColor => const Color(0xFF00BFA5);

  @override
  GraphAlgorithmPolicy get policy => const JohnsonGraphPolicy();

  @override
  Widget buildLaunchButton(BuildContext context, WidgetRef ref) {
    return const JohnsonLaunchButton();
  }

  @override
  Widget? buildCanvasControls(BuildContext context, WidgetRef ref) {
    return const JohnsonCanvasControls();
  }

  @override
  Map<String, dynamic>? newNodeParams(WidgetRef ref) => null;

  @override
  Widget? buildEmptyState(BuildContext context, WidgetRef ref) => null;

  @override
  Widget? buildAlgorithmCard(BuildContext context, WidgetRef ref) {
    final validation = ref.watch(johnsonValidationProvider);
    final state = ref.watch(johnsonNotifierProvider);

    if (state.isActive && validation.isValid) {
      return const JohnsonAlgorithmCard();
    }
    return null;
  }

  @override
  Widget? buildNodeEditControls(
    BuildContext context,
    WidgetRef ref,
    Nodo nodo,
  ) => null;

  @override
  bool get supportsMatrix => false;

  @override
  String? get matrixUnavailableReason =>
      'El algoritmo de Johnson / CPM opera sobre redes de actividades acíclicas (DAG) y listas de predecesores; no utiliza matriz de adyacencia.';

  @override
  Widget? buildMatrixScreen(BuildContext context, WidgetRef ref) => null;

  @override
  bool get supportsStepByStep => true;

  @override
  String? get stepByStepUnavailableReason => null;

  @override
  Widget? buildStepByStepScreen(BuildContext context, WidgetRef ref) => null;

  @override
  List<AlgorithmStep> getStepByStepList(WidgetRef ref) {
    final result = ref.read(johnsonResultProvider);
    if (result == null) return const [];

    final steps = <AlgorithmStep>[];

    // Step 1: Forward Pass (ES/EF)
    final forwardLines = <String>[];
    for (final node in result.nodeResults) {
      forwardLines.add(
        '• Nodo ${node.nodeName}: ES = ${node.earlyTime.toStringAsFixed(1)}, EF = ${node.earlyTime.toStringAsFixed(1)}',
      );
    }

    steps.add(
      AlgorithmStep(
        stepNumber: 1,
        title: 'Pasada Hacia Adelante (Tiempos Tempranos ES / EF)',
        description:
            'Se inicia en el nodo de origen con ES_0 = 0. Para cada nodo posterior, su tiempo temprano de inicio (ES) se calcula como el máximo tiempo temprano de finalización (EF) de todos sus predecesores:\n\n'
            '${forwardLines.join('\n')}',
        formulaLatex:
            r'ES_j = \max_{(i,j)} \{ EF_i \}, \quad EF_j = ES_j + t_j',
        metrics: {
          'Duración del Proyecto (T_max)': result.totalDuration.toStringAsFixed(
            1,
          ),
          'Nodos Procesados': result.nodeResults.length.toString(),
        },
      ),
    );

    // Step 2: Backward Pass (LS/LF)
    final backwardLines = <String>[];
    for (final node in result.nodeResults) {
      backwardLines.add(
        '• Nodo ${node.nodeName}: LF = ${node.lateTime.toStringAsFixed(1)}, LS = ${node.lateTime.toStringAsFixed(1)}',
      );
    }

    steps.add(
      AlgorithmStep(
        stepNumber: 2,
        title: 'Pasada Hacia Atrás (Tiempos Tardíos LF / LS)',
        description:
            'Fijando la fecha final igual a la duración total del proyecto (LF = T_max = ${result.totalDuration.toStringAsFixed(1)}), se recorre la red en sentido inverso. El tiempo tardío de finalización (LF) es el mínimo tiempo tardío de inicio (LS) de sus sucesores:\n\n'
            '${backwardLines.join('\n')}',
        formulaLatex:
            r'LF_i = \min_{(i,j)} \{ LS_j \}, \quad LS_i = LF_i - t_i',
        metrics: {
          'Duración Total del Proyecto': result.totalDuration.toStringAsFixed(
            1,
          ),
        },
      ),
    );

    // Step 3: Node Total Slack (Holgura Total por Nodo)
    final nodeSlackLines = <String>[];
    for (final node in result.nodeResults) {
      nodeSlackLines.add(
        '• Nodo ${node.nodeName}: Holgura = LF - EF = ${node.lateTime.toStringAsFixed(1)} - ${node.earlyTime.toStringAsFixed(1)} = ${node.slack.toStringAsFixed(1)}',
      );
    }

    steps.add(
      AlgorithmStep(
        stepNumber: 3,
        title: 'Cálculo de Holgura Total por Nodo (H_i)',
        description:
            'La holgura total de un nodo es la diferencia entre su tiempo tardío y su tiempo temprano (H = LF - EF = LS - ES):\n\n'
            '${nodeSlackLines.join('\n')}',
        formulaLatex: r'H_i = LF_i - EF_i = LS_i - ES_i',
        metrics: {
          'Nodos Críticos (H_i = 0)': result.criticalNodeIds.length.toString(),
        },
      ),
    );

    // Step 4: Activity Total Slack & Free Slack (Holgura Total y Holgura Libre por Arista)
    final edgeSlackLines = <String>[];
    for (final edge in result.edgeResults) {
      final u = result.nodeResults
          .firstWhere((n) => n.nodeId == edge.sourceId)
          .nodeName;
      final v = result.nodeResults
          .firstWhere((n) => n.nodeId == edge.targetId)
          .nodeName;
      edgeSlackLines.add(
        '• Actividad $u ➔ $v (t = ${edge.duration.toStringAsFixed(1)}):\n'
        '   - Holgura Total (HT): LF_$v - ES_$u - t = ${edge.totalSlack.toStringAsFixed(1)}\n'
        '   - Holgura Libre (HL): ES_$v - ES_$u - t = ${edge.freeSlack.toStringAsFixed(1)}',
      );
    }

    steps.add(
      AlgorithmStep(
        stepNumber: 4,
        title: 'Cálculo de Holguras por Actividad (Holgura Total HT y Holgura Libre HL)',
        description:
            'Para cada actividad (i, j) con duración t:\n'
            '• Holgura Total (HT): tiempo máximo de retraso sin afectar la fecha final del proyecto (HT = LF_j - ES_i - t).\n'
            '• Holgura Libre (HL): tiempo máximo de retraso sin afectar el inicio temprano del sucesor (HL = ES_j - ES_i - t).\n\n'
            '${edgeSlackLines.join('\n')}',
        formulaLatex: r'HT_{ij} = LF_j - ES_i - t_{ij}, \quad HL_{ij} = ES_j - ES_i - t_{ij}',
        metrics: {
          'Aristas Críticas': result.criticalConnectionIds.length.toString(),
        },
      ),
    );

    // Step 5: Critical Path Determination
    steps.add(
      AlgorithmStep(
        stepNumber: 5,
        title: 'Determinación de la Ruta Crítica',
        description: 'La ruta crítica está constituida por la secuencia contigua de nodos y actividades con Holgura Total nula (H = 0 y HT = 0). Ninguna actividad de esta ruta puede retrasarse sin extender la duración total.',
        formulaLatex: r'\text{Ruta Crítica: } HT_{ij} = 0 \implies \text{Secuencia Óptima}',
        metrics: {'Ruta Crítica': result.criticalPathSequence.join(' ➔ ')},
      ),
    );

    return steps;
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
      title: 'Duración de Actividad (Johnson)',
      valueLabel: 'Duración de Actividad',
    );
  }

  @override
  Future<void> onConnectionCreated(
    BuildContext context,
    WidgetRef ref,
    Conexion conexion,
  ) {
    // Opens the single-connection value input popup (pre-filled with default),
    // allowing the user to set the duration immediately after creating the connection.
    showConnectionValueInputDialog(context, ref, conexion);
    return Future.value();
  }

  @override
  Future<void> onNodeCreated(BuildContext context, WidgetRef ref, Nodo nodo) =>
      Future.value();
}
