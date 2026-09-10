import 'dart:math';

import '../../../../domain/models/conexion.dart';
import '../../../../domain/models/grafo.dart';
import '../models/johnson_models.dart';

class JohnsonSolver {
  JohnsonResult solve(Grafo grafo) {
    final nodesList = grafo.nodos.values.toList();
    final nodeIds = grafo.nodos.keys.toSet();

    // 1. Extract edge durations
    final edgeDurations = <String, double>{};
    final outgoingConns = <String, List<Conexion>>{
      for (final id in nodeIds) id: [],
    };
    final incomingConns = <String, List<Conexion>>{
      for (final id in nodeIds) id: [],
    };

    for (final conn in grafo.conexiones.values) {
      if (nodeIds.contains(conn.nodoOrigenId) &&
          nodeIds.contains(conn.nodoDestinoId)) {
        outgoingConns[conn.nodoOrigenId]?.add(conn);
        incomingConns[conn.nodoDestinoId]?.add(conn);

        double duration = 1.0;
        for (final av in conn.atributos) {
          final parsed = double.tryParse(av.valor.trim());
          if (parsed != null && parsed >= 0) {
            duration = parsed;
            break;
          }
        }
        edgeDurations[conn.id] = duration;
      }
    }

    // 2. Topological Sort (Kahn's Algorithm)
    final inDegree = <String, int>{for (final id in nodeIds) id: 0};
    for (final conn in grafo.conexiones.values) {
      if (nodeIds.contains(conn.nodoOrigenId) &&
          nodeIds.contains(conn.nodoDestinoId)) {
        inDegree[conn.nodoDestinoId] = (inDegree[conn.nodoDestinoId] ?? 0) + 1;
      }
    }

    final queue = <String>[];
    for (final entry in inDegree.entries) {
      if (entry.value == 0) queue.add(entry.key);
    }

    final topologicalOrder = <String>[];
    final inDegreeCopy = Map<String, int>.from(inDegree);

    while (queue.isNotEmpty) {
      final u = queue.removeAt(0);
      topologicalOrder.add(u);

      for (final conn in outgoingConns[u] ?? <Conexion>[]) {
        final v = conn.nodoDestinoId;
        inDegreeCopy[v] = (inDegreeCopy[v] ?? 1) - 1;
        if (inDegreeCopy[v] == 0) {
          queue.add(v);
        }
      }
    }

    // Standard fallback if topological order missing nodes
    if (topologicalOrder.length < nodesList.length) {
      for (final n in nodesList) {
        if (!topologicalOrder.contains(n.id)) {
          topologicalOrder.add(n.id);
        }
      }
    }

    // 3. Forward Pass (Early Time E_i)
    final earlyTimes = <String, double>{for (final id in nodeIds) id: 0.0};

    for (final u in topologicalOrder) {
      final currentE = earlyTimes[u] ?? 0.0;
      for (final conn in outgoingConns[u] ?? <Conexion>[]) {
        final v = conn.nodoDestinoId;
        final dur = edgeDurations[conn.id] ?? 1.0;
        if (currentE + dur > (earlyTimes[v] ?? 0.0)) {
          earlyTimes[v] = currentE + dur;
        }
      }
    }

    double maxEarlyTime = 0.0;
    for (final val in earlyTimes.values) {
      maxEarlyTime = max(maxEarlyTime, val);
    }

    // 4. Backward Pass (Late Time L_i)
    final lateTimes = <String, double>{
      for (final id in nodeIds) id: maxEarlyTime,
    };

    final reverseTopoOrder = topologicalOrder.reversed.toList();
    for (final v in reverseTopoOrder) {
      final currentL = lateTimes[v] ?? maxEarlyTime;
      for (final conn in incomingConns[v] ?? <Conexion>[]) {
        final u = conn.nodoOrigenId;
        final dur = edgeDurations[conn.id] ?? 1.0;
        final candidateL = currentL - dur;
        if (candidateL < (lateTimes[u] ?? maxEarlyTime)) {
          lateTimes[u] = candidateL;
        }
      }
    }

    // 5. Calculate Slack, Critical Nodes, & Critical Edges
    final nodeResults = <JohnsonNodeResult>[];
    final criticalNodeIds = <String>{};

    for (final n in nodesList) {
      final e = earlyTimes[n.id] ?? 0.0;
      final l = lateTimes[n.id] ?? 0.0;
      final slack = max(0.0, l - e);
      final isCritical = slack.abs() < 1e-5;

      if (isCritical) {
        criticalNodeIds.add(n.id);
      }

      nodeResults.add(
        JohnsonNodeResult(
          nodeId: n.id,
          nodeName: n.nombre ?? n.id,
          earlyTime: e,
          lateTime: l,
          slack: slack,
          isCritical: isCritical,
        ),
      );
    }

    final edgeResults = <JohnsonEdgeResult>[];
    final criticalConnectionIds = <String>{};

    for (final conn in grafo.conexiones.values) {
      final u = conn.nodoOrigenId;
      final v = conn.nodoDestinoId;
      final dur = edgeDurations[conn.id] ?? 1.0;

      final isSourceCritical = criticalNodeIds.contains(u);
      final isTargetCritical = criticalNodeIds.contains(v);
      final eSource = earlyTimes[u] ?? 0.0;
      final eTarget = earlyTimes[v] ?? 0.0;

      final isCriticalEdge =
          isSourceCritical &&
          isTargetCritical &&
          ((eSource + dur) - eTarget).abs() < 1e-5;

      if (isCriticalEdge) {
        criticalConnectionIds.add(conn.id);
      }

      edgeResults.add(
        JohnsonEdgeResult(
          connectionId: conn.id,
          sourceId: u,
          targetId: v,
          duration: dur,
          isCritical: isCriticalEdge,
        ),
      );
    }

    // 6. Build Critical Path Sequence (Node Names in order)
    final criticalSequence = <String>[];
    for (final nodeId in topologicalOrder) {
      if (criticalNodeIds.contains(nodeId)) {
        final node = grafo.nodos[nodeId];
        if (node != null) {
          criticalSequence.add(node.nombre ?? node.id);
        }
      }
    }

    return JohnsonResult(
      nodeResults: nodeResults,
      edgeResults: edgeResults,
      totalDuration: maxEarlyTime,
      criticalNodeIds: criticalNodeIds,
      criticalConnectionIds: criticalConnectionIds,
      criticalPathSequence: criticalSequence,
    );
  }
}
