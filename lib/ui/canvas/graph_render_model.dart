import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/models/direccion.dart';
import '../../domain/models/grafo.dart';
import '../../domain/services/graph_geometry.dart';
import '../theme/app_theme.dart';
import 'graph_hit_tester.dart';

class RenderPoint {
  final double x;
  final double y;
  const RenderPoint(this.x, this.y);

  Offset toOffset() => Offset(x, y);
}

class RenderNode {
  final String id;
  final String nombre;
  final Offset position;
  final double width;
  final double height;
  final bool isCapsule;
  final Color color;
  final bool isSelected;
  final bool isHighlighted;
  final bool isDisconnected; // Red glow if true
  final bool isPendingConnectTarget; // Visual hint during creation

  const RenderNode({
    required this.id,
    required this.nombre,
    required this.position,
    required this.width,
    required this.height,
    required this.isCapsule,
    required this.color,
    this.isSelected = false,
    this.isHighlighted = false,
    this.isDisconnected = false,
    this.isPendingConnectTarget = false,
  });
}

class RenderBezierCurve {
  final Offset start;
  final Offset control1;
  final Offset control2;
  final Offset end;

  const RenderBezierCurve({
    required this.start,
    required this.control1,
    required this.control2,
    required this.end,
  });
}

class RenderConnectionLine {
  final String conexionId;
  final RenderBezierCurve curve;
  final Color color;
  final bool isDirected;
  final Offset? arrowPoint;
  final double? arrowAngle;
  final Offset? reverseArrowPoint;
  final double? reverseArrowAngle;
  final String? labelText;
  final Offset? labelPosition;
  final bool isSelected;
  final bool isHighlighted;

  const RenderConnectionLine({
    required this.conexionId,
    required this.curve,
    required this.color,
    this.isDirected = false,
    this.arrowPoint,
    this.arrowAngle,
    this.reverseArrowPoint,
    this.reverseArrowAngle,
    this.labelText,
    this.labelPosition,
    this.isSelected = false,
    this.isHighlighted = false,
  });
}

class RenderDragLine {
  final Offset start;
  final Offset end;
  final Color color;
  final String? targetNodeId;

  const RenderDragLine({
    required this.start,
    required this.end,
    required this.color,
    this.targetNodeId,
  });
}

class GraphRenderModel {
  final List<RenderNode> nodes;
  final List<RenderConnectionLine> connections;
  final RenderDragLine? dragLine;
  final double
  gridSpacing; // Distance between grid dots = 1 node diameter (50.0)

  const GraphRenderModel({
    required this.nodes,
    required this.connections,
    this.dragLine,
    this.gridSpacing = 50.0,
  });

  /// Factory constructor to build a unified [GraphRenderModel] from domain [Grafo].
  factory GraphRenderModel.fromGrafo(
    Grafo grafo, {
    required NeumorphicPalette palette,
    String? selectedItemId,
    bool isSelectedNode = true,
    Set<String> disconnectedNodeIds = const {},
    Set<String> highlightedNodeIds = const {},
    Set<String> highlightedConnectionIds = const {},
    String? pendingConnectNodeId,
    String? dragConnectingStartNodeId,
    Offset? dragConnectingCurrentPos,
    String? dragConnectingTargetNodeId,
  }) {
    final renderNodes = <RenderNode>[];
    for (final n in grafo.nodos.values) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: n.nombre ?? n.id,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final minDiameter = n.diameter;
      final textWidth = textPainter.width + 24;
      final isCapsule = textWidth > minDiameter;
      final width = max(minDiameter, textWidth);

      renderNodes.add(
        RenderNode(
          id: n.id,
          nombre: n.nombre ?? n.id,
          position: Offset(n.x, n.y),
          width: width,
          height: minDiameter,
          isCapsule: isCapsule,
          color: Color(n.colorValue),
          isSelected: isSelectedNode && selectedItemId == n.id,
          isHighlighted: highlightedNodeIds.contains(n.id),
          isDisconnected: disconnectedNodeIds.contains(n.id),
          isPendingConnectTarget: pendingConnectNodeId == n.id,
        ),
      );
    }

    final selectedConn = !isSelectedNode && selectedItemId != null
        ? grafo.conexiones[selectedItemId]
        : null;

    final renderConns = <RenderConnectionLine>[];
    final pairCounts = <String, int>{};
    for (final c in grafo.conexiones.values) {
      final key = c.nodoOrigenId.compareTo(c.nodoDestinoId) < 0
          ? '${c.nodoOrigenId}_${c.nodoDestinoId}'
          : '${c.nodoDestinoId}_${c.nodoOrigenId}';
      pairCounts[key] = (pairCounts[key] ?? 0) + 1;
    }

    final pairIndex = <String, int>{};

    final sortedConns = grafo.conexiones.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    for (final c in sortedConns) {
      final origen = grafo.nodos[c.nodoOrigenId];
      final destino = grafo.nodos[c.nodoDestinoId];
      if (origen == null || destino == null) continue;

      final pairKey = c.nodoOrigenId.compareTo(c.nodoDestinoId) < 0
          ? '${c.nodoOrigenId}_${c.nodoDestinoId}'
          : '${c.nodoDestinoId}_${c.nodoOrigenId}';

      final totalInPair = pairCounts[pairKey] ?? 1;
      final currentIdx = pairIndex[pairKey] ?? 0;
      pairIndex[pairKey] = currentIdx + 1;

      final offsetFactor = GraphHitTester.calculateOffsetFactor(
        c,
        currentIdx,
        totalInPair,
      );

      final curve = GraphGeometry.calculateBezierCurve(
        origen: origen,
        destino: destino,
        offsetFactor: offsetFactor,
        customCurvatura: c.curvatura,
        loopAngle: c.loopAngle,
        offsetControlX: c.offsetControlX,
        offsetControlY: c.offsetControlY,
      );

      Offset? arrowPoint;
      double? arrowAngle;
      Offset? reverseArrowPoint;
      double? reverseArrowAngle;

      if (c.direccion == Direccion.unidireccional ||
          c.direccion == Direccion.bidireccional) {
        final t = 1.0;
        final px = GraphHitTester.evalBezier(
          t,
          curve.start.x,
          curve.control1.x,
          curve.control2.x,
          curve.end.x,
        );
        final py = GraphHitTester.evalBezier(
          t,
          curve.start.y,
          curve.control1.y,
          curve.control2.y,
          curve.end.y,
        );
        final dx = GraphHitTester.evalBezierDeriv(
          t,
          curve.start.x,
          curve.control1.x,
          curve.control2.x,
          curve.end.x,
        );
        final dy = GraphHitTester.evalBezierDeriv(
          t,
          curve.start.y,
          curve.control1.y,
          curve.control2.y,
          curve.end.y,
        );

        arrowPoint = Offset(px, py);
        arrowAngle = atan2(dy, dx);
      }

      if (c.direccion == Direccion.bidireccional) {
        final t = 0.0;
        final px = GraphHitTester.evalBezier(
          t,
          curve.start.x,
          curve.control1.x,
          curve.control2.x,
          curve.end.x,
        );
        final py = GraphHitTester.evalBezier(
          t,
          curve.start.y,
          curve.control1.y,
          curve.control2.y,
          curve.end.y,
        );
        final dx = GraphHitTester.evalBezierDeriv(
          t,
          curve.start.x,
          curve.control1.x,
          curve.control2.x,
          curve.end.x,
        );
        final dy = GraphHitTester.evalBezierDeriv(
          t,
          curve.start.y,
          curve.control1.y,
          curve.control2.y,
          curve.end.y,
        );

        reverseArrowPoint = Offset(px, py);
        reverseArrowAngle = atan2(-dy, -dx);
      }

      String? labelText;
      if (c.atributos.isNotEmpty) {
        labelText = c.atributos.map((a) => a.valor).join(', ');
      }

      final labelPos = Offset(
        GraphHitTester.evalBezier(
          0.5,
          curve.start.x,
          curve.control1.x,
          curve.control2.x,
          curve.end.x,
        ),
        GraphHitTester.evalBezier(
          0.5,
          curve.start.y,
          curve.control1.y,
          curve.control2.y,
          curve.end.y,
        ),
      );

      final isConnSelected =
          !isSelectedNode &&
          (selectedItemId == c.id ||
              (selectedConn != null &&
                  ((c.nodoOrigenId == selectedConn.nodoOrigenId &&
                          c.nodoDestinoId == selectedConn.nodoDestinoId) ||
                      (c.nodoOrigenId == selectedConn.nodoDestinoId &&
                          c.nodoDestinoId == selectedConn.nodoOrigenId))));

      renderConns.add(
        RenderConnectionLine(
          conexionId: c.id,
          curve: RenderBezierCurve(
            start: Offset(curve.start.x, curve.start.y),
            control1: Offset(curve.control1.x, curve.control1.y),
            control2: Offset(curve.control2.x, curve.control2.y),
            end: Offset(curve.end.x, curve.end.y),
          ),
          color: (c.direccion == Direccion.ninguna)
              ? (palette.surfaceBg.computeLuminance() > 0.45
                    ? const Color(0xFF212121)
                    : const Color(0xFFFFFFFF))
              : Color(origen.colorValue),
          isDirected: c.direccion != Direccion.ninguna,
          arrowPoint: arrowPoint,
          arrowAngle: arrowAngle,
          reverseArrowPoint: reverseArrowPoint,
          reverseArrowAngle: reverseArrowAngle,
          labelText: labelText,
          labelPosition: labelPos,
          isSelected: isConnSelected,
          isHighlighted: highlightedConnectionIds.contains(c.id),
        ),
      );
    }

    RenderDragLine? dragLine;
    if (dragConnectingStartNodeId != null && dragConnectingCurrentPos != null) {
      final startNode = grafo.nodos[dragConnectingStartNodeId];
      if (startNode != null) {
        dragLine = RenderDragLine(
          start: Offset(startNode.x, startNode.y),
          end: dragConnectingCurrentPos,
          color: palette.primaryAccent,
          targetNodeId: dragConnectingTargetNodeId,
        );
      }
    }

    return GraphRenderModel(
      nodes: renderNodes,
      connections: renderConns,
      dragLine: dragLine,
    );
  }
}
