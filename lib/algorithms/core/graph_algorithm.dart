import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/conexion.dart';
import '../../domain/models/direccion.dart';
import '../../domain/models/grafo.dart';
import '../../domain/models/nodo.dart';
import '../../ui/dialogs/connection_value_input_dialog.dart';

/// Result returned when evaluating whether a graph mutation is permitted
/// under the active algorithm's policy.
class PolicyResult {
  final bool allowed;
  final String? message;

  const PolicyResult({required this.allowed, this.message});

  const PolicyResult.allow() : allowed = true, message = null;

  const PolicyResult.deny(String reason) : allowed = false, message = reason;
}

/// Abstract policy specifying graph construction and editing constraints
/// for an algorithm.
abstract class GraphAlgorithmPolicy {
  /// Checks whether creating a new node at coordinates [x, y] is allowed.
  PolicyResult canCreateNode(
    Grafo grafo,
    double x,
    double y, {
    Map<String, dynamic>? params,
  });

  /// Factory method to construct and prepare a new [Nodo] instance according
  /// to the algorithm's requirements (e.g. assigning roles, default names, colors).
  Nodo prepareNewNode(
    Grafo grafo,
    double x,
    double y, {
    String? nombre,
    int? colorValue,
    Map<String, dynamic>? params,
  });

  /// Checks whether adding a connection from [origenId] to [destinoId]
  /// with direction [direccion] is permitted.
  PolicyResult canCreateConnection(
    Grafo grafo,
    String origenId,
    String destinoId,
    Direccion direccion,
  );

  /// Returns the allowed directions when creating or editing a connection
  /// between [origenId] and [destinoId].
  List<Direccion> allowedDirections(
    Grafo grafo,
    String origenId,
    String destinoId,
  );

  /// Whether self-loops (node connecting to itself) are permitted.
  bool get allowSelfLoops;

  /// Whether bidirectional connections are permitted.
  bool get allowBidirectional;

  /// Checks structural deletion. Most algorithms keep the unrestricted default.
  PolicyResult canDeleteNode(Grafo grafo, String nodeId) =>
      const PolicyResult.allow();

  /// Checks structural deletion. Most algorithms keep the unrestricted default.
  PolicyResult canDeleteConnection(Grafo grafo, String connectionId) =>
      const PolicyResult.allow();
}

/// Abstract contract for a pluggable graph algorithm.
///
/// Encapsulates algorithm identification, graph drawing policy, and
/// modular UI components (launch button, canvas controls, algorithm card,
/// and node edit controls).
abstract class GraphAlgorithm {
  /// Unique identifier (e.g. 'assignment', 'johnson').
  String get id;

  /// Full descriptive name (e.g. 'Algoritmo de Asignación').
  String get name;

  /// Short name for compact chips and badges (e.g. 'Asignación').
  String get shortName;

  /// Brief explanation of what the algorithm computes.
  String get description;

  /// Icon representing the algorithm.
  IconData get icon;

  /// Accent color theme for the algorithm UI elements.
  Color get themeColor;

  /// Drawing policy and constraints governing this algorithm.
  GraphAlgorithmPolicy get policy;

  /// Builds the dedicated launch button to display on the explanation webpage.
  Widget buildLaunchButton(BuildContext context, WidgetRef ref);

  /// Builds optional canvas overlay controls (e.g. role toggle pill).
  Widget? buildCanvasControls(BuildContext context, WidgetRef ref) => null;

  /// Parameters passed to the policy when creating a node on the canvas.
  Map<String, dynamic>? newNodeParams(WidgetRef ref) => null;

  /// Builds an optional overlay when the active algorithm has no configured data.
  Widget? buildEmptyState(BuildContext context, WidgetRef ref) => null;

  /// Builds the floating algorithm card rendered on top of the canvas
  /// when active and validated.
  Widget? buildAlgorithmCard(BuildContext context, WidgetRef ref) => null;

  /// Builds optional controls inside the node properties section of EditPanel
  /// (e.g. switching between Origen and Destino).
  Widget? buildNodeEditControls(
    BuildContext context,
    WidgetRef ref,
    Nodo nodo,
  ) => null;

  /// Whether this algorithm supports or uses a matrix view representation.
  /// Defaults to false.
  bool get supportsMatrix => false;

  /// Reason why a matrix is unavailable for this algorithm, shown to users if queried.
  String? get matrixUnavailableReason => null;

  /// Builds the dedicated matrix view/screen for this algorithm.
  /// Returns null if not supported.
  Widget? buildMatrixScreen(BuildContext context, WidgetRef ref) => null;

  /// Opens the connection value input dialog/widget for editing a connection's numeric value.
  Future<bool?> showConnectionValueInputDialog(
    BuildContext context,
    WidgetRef ref,
    Conexion conexion,
  ) {
    return ConnectionValueInputDialog.show(
      context: context,
      ref: ref,
      conexion: conexion,
      title: 'Valor de Conexión ($shortName)',
    );
  }

  /// Triggered when a new connection is created on the canvas while this algorithm is active.
  /// Defaults to displaying [showConnectionValueInputDialog].
  Future<void> onConnectionCreated(
    BuildContext context,
    WidgetRef ref,
    Conexion conexion,
  ) {
    showConnectionValueInputDialog(context, ref, conexion);
    return Future.value();
  }
}
