import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/atributos_provider.dart';
import '../../application/providers/creacion_provider.dart';
import '../../application/providers/edicion_provider.dart';
import '../../application/providers/grafo_invalido_provider.dart';
import '../../application/providers/grafo_provider.dart';
import '../../application/providers/modo_provider.dart';
import '../../domain/models/conexion.dart';
import '../../domain/models/direccion.dart';
import '../../domain/models/grafo.dart';
import '../../domain/models/nodo.dart';
import '../../domain/services/graph_geometry.dart';
import '../dialogs/delete_confirmation_dialog.dart';
import '../dialogs/overlapping_elements_dialog.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_context_menu.dart';
import 'graph_hit_tester.dart';
import 'graph_painter.dart';
import 'graph_render_model.dart';

class GraphCanvas extends ConsumerStatefulWidget {
  const GraphCanvas({super.key});

  @override
  ConsumerState<GraphCanvas> createState() => GraphCanvasState();
}

class GraphCanvasState extends ConsumerState<GraphCanvas>
    with SingleTickerProviderStateMixin {
  // Spatial Base Unit & World Grid Constants
  static const double nodeDiameter = 64.0; // 1 Node unit (U)
  static const double worldGridNodes =
      100.0; // 100x100 node world grid (6400 x 6400 px)
  static const double baseViewNodes = 8.0; // Default mode view starts zoomed-in (~8x8 nodes)
  static const double minViewNodes = 5.0; // Max zoom in displays ~5x5 nodes
  static const double maxViewNodes = 40.0; // Max zoom out displays ~40x40 nodes

  // Transformation matrix for Pan & Zoom
  Matrix4 _transform = Matrix4.identity();

  // Gesture state tracking
  Offset? _pointerDownScreenPosition;
  Timer? _longPressTimer;
  bool _isDraggingNode = false;
  String? _draggedNodeId;
  bool _isDraggingConn = false;
  String? _draggedConnId;
  double _lastScale = 1.0;
  Offset? _lastFocalPoint;
  bool _isInitialCentered = false;
  int _maxPointerCountDuringGesture = 0;

  // Snap-back animation controller for invalid node positioning
  late AnimationController _snapBackController;
  Animation<Offset>? _snapBackAnimation;
  String? _animatingNodeId;

  // Contextual Floating Menu state
  Offset? _contextMenuScreenPosition;
  String? _contextMenuTargetId;
  bool _contextMenuIsNode = true;

  // Live drag-to-connect state tracking
  String? _dragConnectingStartNodeId;
  Offset? _dragConnectingCurrentPos;
  String? _dragConnectingTargetNodeId;

  // Node Move Hold timer & unlock state
  Timer? _nodeHoldTimer;
  bool _isNodeMoveUnlocked = false;

  // Single-tap edit debounce timer (prevents edit modal popping on double-tap self loop)
  Timer? _singleTapEditTimer;

  // Track if current gesture panned or moved canvas
  bool _hasPannedCanvas = false;

  @override
  void initState() {
    super.initState();
    _snapBackController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        )..addListener(() {
          if (_animatingNodeId != null && _snapBackAnimation != null) {
            ref
                .read(grafoProvider.notifier)
                .moverNodo(
                  _animatingNodeId!,
                  _snapBackAnimation!.value.dx,
                  _snapBackAnimation!.value.dy,
                );
          }
        });
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _nodeHoldTimer?.cancel();
    _singleTapEditTimer?.cancel();
    _zoomLockoutTimer?.cancel();
    _snapBackController.dispose();
    super.dispose();
  }

  Matrix4 get transform => _transform;


  void _ensureValidTransform() {
    final storage = _transform.storage;
    bool corrupt = false;
    for (int i = 0; i < 16; i++) {
      if (storage[i].isNaN || storage[i].isInfinite) {
        corrupt = true;
        break;
      }
    }
    if (corrupt) {
      // Recover by rebuilding to base-mode centred on current screen centre
      // rather than wiping to identity, which breaks centring.
      if (mounted) {
        _centrarLienzo();
      } else {
        _transform = Matrix4.identity();
      }
    } else {
      _clampTransformBounds();
    }
  }

  /// Clamp scale and translation so camera view never zooms or pans beyond bounds
  void _clampTransformBounds() {
    if (!mounted) return;
    final screenSize = MediaQuery.of(context).size;
    if (screenSize.width <= 0 || screenSize.height <= 0) return;

    final minDim = min(screenSize.width, screenSize.height);
    final baseScale = minDim > 0 ? (minDim / (baseViewNodes * nodeDiameter)) : 1.0;
    final minScale = baseScale * (baseViewNodes / maxViewNodes);
    final maxScale = baseScale * (baseViewNodes / minViewNodes);

    double scale = _getXYScale();
    if (scale <= 0 || !scale.isFinite) return;

    if (scale < minScale || scale > maxScale) {
      final targetScale = scale.clamp(minScale, maxScale);
      final factor = targetScale / scale;
      final center = Offset(screenSize.width / 2, screenSize.height / 2);
      final scaleUpdate = Matrix4.identity()
        // ignore: deprecated_member_use
        ..translate(center.dx, center.dy)
        // ignore: deprecated_member_use
        ..scale(factor, factor, 1.0)
        // ignore: deprecated_member_use
        ..translate(-center.dx, -center.dy);
      _transform = scaleUpdate..multiply(_transform);
      scale = targetScale;
    }

    const halfGridWidth = (worldGridNodes * nodeDiameter) / 2.0; // 2400.0
    const halfGridHeight = (worldGridNodes * nodeDiameter) / 2.0; // 2400.0

    final maxTx = halfGridWidth * scale;
    final minTx = screenSize.width - (halfGridWidth * scale);

    final maxTy = halfGridHeight * scale;
    final minTy = screenSize.height - (halfGridHeight * scale);

    final storage = _transform.storage;
    double tx = storage[12];
    double ty = storage[13];

    if (minTx <= maxTx) {
      tx = tx.clamp(minTx, maxTx);
    } else {
      tx = screenSize.width / 2.0;
    }

    if (minTy <= maxTy) {
      ty = ty.clamp(minTy, maxTy);
    } else {
      ty = screenSize.height / 2.0;
    }

    storage[12] = tx;
    storage[13] = ty;
  }

  // Extract actual XY scale from the transform matrix.
  // IMPORTANT: Do NOT use getMaxScaleOnAxis() — it returns the Z-axis
  // scale (always 1.0) when XY scale drops below 1.0, which completely
  // breaks zoom-out clamping.
  double _getXYScale() {
    final col0 = _transform.getColumn(0);
    return sqrt(col0.x * col0.x + col0.y * col0.y);
  }

  // Convert screen coordinates to canvas world coordinates
  Offset _screenToWorld(Offset screenPos) {
    _ensureValidTransform();
    final inverted = Matrix4.inverted(_transform);
    return MatrixUtils.transformPoint(inverted, screenPos);
  }


  DateTime? _lastTapTime;
  String? _lastTapNodeId;
  DateTime? _lastZoomGestureEndTime;

  final Set<int> _activePointerIds = {};
  bool _isZoomLockoutActive = false;
  Timer? _zoomLockoutTimer;

  void _handlePointerDown(PointerDownEvent event) {
    _activePointerIds.add(event.pointer);
    if (_activePointerIds.length >= 2) {
      _triggerZoomLockout();
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _activePointerIds.remove(event.pointer);
    if (_activePointerIds.isEmpty && _isZoomLockoutActive) {
      _scheduleZoomLockoutRelease();
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _activePointerIds.remove(event.pointer);
    if (_activePointerIds.isEmpty && _isZoomLockoutActive) {
      _scheduleZoomLockoutRelease();
    }
  }

  void _triggerZoomLockout() {
    _zoomLockoutTimer?.cancel();
    _isZoomLockoutActive = true;
    _hasPannedCanvas = true;
    _isNodeMoveUnlocked = false;
    _isDraggingNode = false;
    _draggedNodeId = null;
    _isDraggingConn = false;
    _draggedConnId = null;
    _dragConnectingStartNodeId = null;
    _dragConnectingCurrentPos = null;
    _dragConnectingTargetNodeId = null;
    _longPressTimer?.cancel();
    _nodeHoldTimer?.cancel();
  }

  void _scheduleZoomLockoutRelease() {
    _zoomLockoutTimer?.cancel();
    _zoomLockoutTimer = Timer(const Duration(milliseconds: 80), () {
      if (mounted) {
        setState(() {
          _isZoomLockoutActive = false;
        });
      }
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    _longPressTimer?.cancel();
    _nodeHoldTimer?.cancel();
    _isNodeMoveUnlocked = false;
    _hasPannedCanvas = false;

    // Dismiss floating context menu on tap outside
    if (_contextMenuScreenPosition != null) {
      setState(() {
        _contextMenuScreenPosition = null;
        _contextMenuTargetId = null;
      });
    }

    _pointerDownScreenPosition = details.localFocalPoint;
    _lastFocalPoint = details.localFocalPoint;
    _lastScale = 1.0;
    _maxPointerCountDuringGesture = details.pointerCount;

    if (_isZoomLockoutActive || details.pointerCount >= 2) {
      _triggerZoomLockout();
      return;
    }

    final worldPos = _screenToWorld(details.localFocalPoint);
    final grafo = ref.read(grafoProvider);
    final touchedNode = GraphHitTester.hitTestNode(worldPos, grafo.nodos.values, scale: _getXYScale());

    if (touchedNode != null) {
      _draggedNodeId = touchedNode.id;
      _draggedConnId = null;
      _dragConnectingStartNodeId = touchedNode.id;
      _dragConnectingCurrentPos = Offset(touchedNode.x, touchedNode.y);
      _dragConnectingTargetNodeId = null;

      // Start 250ms hold timer for node MOVE mode
      _nodeHoldTimer = Timer(const Duration(milliseconds: 250), () {
        if (mounted && _draggedNodeId == touchedNode.id) {
          setState(() {
            _isNodeMoveUnlocked = true;
            _dragConnectingStartNodeId = null;
            _dragConnectingCurrentPos = null;
            _dragConnectingTargetNodeId = null;
          });
        }
      });

      // Start 1.0-second long press timer for contextual popup
      _longPressTimer = Timer(const Duration(milliseconds: 1000), () {
        if (!_isDraggingNode && !_isNodeMoveUnlocked) {
          _triggerContextMenu(details.localFocalPoint, touchedNode.id, true);
        }
      });
    } else {
      _dragConnectingStartNodeId = null;
      _dragConnectingCurrentPos = null;
      _dragConnectingTargetNodeId = null;

      final touchedConn = GraphHitTester.hitTestConnection(worldPos, grafo, _getXYScale());
      if (touchedConn != null) {
        _draggedNodeId = null;
        _draggedConnId = touchedConn.id;
        _longPressTimer = Timer(const Duration(milliseconds: 1000), () {
          if (!_isDraggingConn) {
            _triggerContextMenu(details.localFocalPoint, touchedConn.id, false);
          }
        });
      } else {
        _draggedNodeId = null;
        _draggedConnId = null;
      }
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount > _maxPointerCountDuringGesture) {
      _maxPointerCountDuringGesture = details.pointerCount;
    }

    // 2-Finger Pinch Zoom (scale centred at focal point)
    if (details.pointerCount >= 2 || _maxPointerCountDuringGesture >= 2 || _isZoomLockoutActive) {
      _triggerZoomLockout();

      final focalPoint = details.localFocalPoint;
      _lastFocalPoint = focalPoint;

      final screenSize = MediaQuery.of(context).size;
      final minDim = min(screenSize.width, screenSize.height);
      final baseScale = minDim > 0
          ? (minDim / (baseViewNodes * nodeDiameter))
          : 1.0;

      // Scale bounds: max zoom-in shows 10×10 nodes, max zoom-out shows 100×100
      final minZoomOutScale = baseScale * (baseViewNodes / maxViewNodes);
      final maxZoomInScale = baseScale * (baseViewNodes / minViewNodes);

      // Compute per-frame incremental scale ratio
      final scaleDelta = (_lastScale > 0 && _lastScale.isFinite)
          ? (details.scale / _lastScale)
          : 1.0;
      _lastScale = details.scale;

      final currentScale = _getXYScale();
      if (currentScale <= 0 || !currentScale.isFinite) {
        _centrarLienzo();
        return;
      }

      final targetScale = (currentScale * scaleDelta).clamp(
        minZoomOutScale,
        maxZoomInScale,
      );
      final scaleFactor = targetScale / currentScale;

      setState(() {
        final update = Matrix4.identity()
          // ignore: deprecated_member_use
          ..translate(focalPoint.dx, focalPoint.dy)
          // ignore: deprecated_member_use
          ..scale(scaleFactor, scaleFactor, 1.0)
          // ignore: deprecated_member_use
          ..translate(-focalPoint.dx, -focalPoint.dy);

        _transform = update..multiply(_transform);
        _ensureValidTransform();
      });
      return;
    }

    // Single-finger touch — check movement threshold against initial touch point
    if (_pointerDownScreenPosition == null) return;
    final screenDelta =
        (details.localFocalPoint - _pointerDownScreenPosition!).distance;

    if (screenDelta > 6.0) {
      _longPressTimer?.cancel();
      if (!_isNodeMoveUnlocked) {
        _nodeHoldTimer?.cancel();
      }
    }

    final worldPos = _screenToWorld(details.localFocalPoint);

    if (_isNodeMoveUnlocked && _draggedNodeId != null) {
      // User held node for >250ms -> Move Node mode active!
      _isDraggingNode = true;
      _dragConnectingStartNodeId = null;
      _dragConnectingCurrentPos = null;
      ref
          .read(grafoProvider.notifier)
          .moverNodo(_draggedNodeId!, worldPos.dx, worldPos.dy);
    } else if (_dragConnectingStartNodeId != null && screenDelta > 6.0) {
      // Instant drag from node -> Live direction connection line to target!
      final grafo = ref.read(grafoProvider);
      final targetNode = GraphHitTester.hitTestNode(worldPos, grafo.nodos.values, scale: _getXYScale());

      setState(() {
        _dragConnectingCurrentPos = worldPos;
        _dragConnectingTargetNodeId = targetNode?.id;
      });
    } else if (screenDelta > 6.0) {
      if (_draggedConnId != null) {
        _isDraggingConn = true;
        final grafo = ref.read(grafoProvider);
        final conn = grafo.conexiones[_draggedConnId];
        if (conn != null) {
          final origen = grafo.nodos[conn.nodoOrigenId];
          final destino = grafo.nodos[conn.nodoDestinoId];
          if (origen != null && destino != null) {
            if (origen.id == destino.id) {
              final angle = atan2(worldPos.dy - origen.y, worldPos.dx - origen.x);
              final distFromCenter = sqrt(
                (worldPos.dx - origen.x) * (worldPos.dx - origen.x) +
                (worldPos.dy - origen.y) * (worldPos.dy - origen.y),
              );
              final textLength = (origen.nombre ?? origen.id).length;
              final nodeOuterRadius = max(origen.radius, (textLength * 8.0 + 24.0) / 2.0);
              final newCurvatura = max(0.0, (distFromCenter - nodeOuterRadius * 1.1) / (nodeOuterRadius * 0.8)).clamp(0.0, 5.0);
              ref
                  .read(grafoProvider.notifier)
                  .actualizarConexion(_draggedConnId!, loopAngle: angle, curvatura: newCurvatura, recordUndo: false);
            } else {
              final midX = (origen.x + destino.x) / 2.0;
              final midY = (origen.y + destino.y) / 2.0;
              final offX = worldPos.dx - midX;
              final offY = worldPos.dy - midY;
              ref.read(grafoProvider.notifier).actualizarConexion(
                    _draggedConnId!,
                    offsetControlX: offX,
                    offsetControlY: offY,
                    recordUndo: false,
                  );
            }
          }
        }
      } else if (_lastFocalPoint != null) {
        // Direct 1-finger canvas panning when no element is dragged
        final focalDelta = details.localFocalPoint - _lastFocalPoint!;
        if (focalDelta.distance > 0.5) {
          _hasPannedCanvas = true;
        }
        setState(() {
          _transform = Matrix4.identity()
            // ignore: deprecated_member_use
            ..translate(focalDelta.dx, focalDelta.dy)
            ..multiply(_transform);
          _ensureValidTransform();
        });
      }
    }
    _lastFocalPoint = details.localFocalPoint;
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _longPressTimer?.cancel();
    _nodeHoldTimer?.cancel();
    _lastScale = 1.0;

    if (_isZoomLockoutActive || _maxPointerCountDuringGesture >= 2) {
      _triggerZoomLockout();
      if (_activePointerIds.isEmpty) {
        _scheduleZoomLockoutRelease();
      }
      setState(() {});
      return;
    }

    if (_isNodeMoveUnlocked && _isDraggingNode && _draggedNodeId != null) {
      final grafo = ref.read(grafoProvider);
      final node = grafo.nodos[_draggedNodeId];
      if (node != null) {
        _handleNodeDragEnd(node.id, Offset(node.x, node.y));
      }
      _isDraggingNode = false;
      _draggedNodeId = null;
      _isNodeMoveUnlocked = false;
    } else if (_dragConnectingStartNodeId != null) {
      final startId = _dragConnectingStartNodeId!;
      final endPos = _dragConnectingCurrentPos;
      _dragConnectingStartNodeId = null;
      _dragConnectingCurrentPos = null;
      _dragConnectingTargetNodeId = null;
      setState(() {});

      if (endPos != null && _pointerDownScreenPosition != null) {
        final screenDelta = (details.velocity.pixelsPerSecond).distance;
        final startWorldPos = _screenToWorld(_pointerDownScreenPosition!);
        final distWorld = (endPos - startWorldPos).distance;

        final grafo = ref.read(grafoProvider);
        final targetNode = GraphHitTester.hitTestNode(endPos, grafo.nodos.values, scale: _getXYScale());

        if (distWorld > 15.0 && targetNode != null && targetNode.id != startId) {
          // Instant drag to connect DIFFERENT target node!
          ref.read(grafoProvider.notifier).agregarConexion(startId, targetNode.id);
        } else if (distWorld <= 15.0 || targetNode?.id == startId) {
          if (screenDelta < 200.0) {
            // Tap / release on same node -> Edit node!
            _handleTap(startWorldPos);
          }
        }
      }
    } else if (_isDraggingConn && _draggedConnId != null) {
      _isDraggingConn = false;
      _draggedConnId = null;
    } else if (!_hasPannedCanvas &&
        _pointerDownScreenPosition != null &&
        _maxPointerCountDuringGesture < 2) {
      final isZoomDebounced = _lastZoomGestureEndTime != null &&
          DateTime.now().difference(_lastZoomGestureEndTime!).inMilliseconds < 400;

      if (!isZoomDebounced) {
        final screenVelocity = details.velocity.pixelsPerSecond.distance;
        final worldPos = _screenToWorld(_pointerDownScreenPosition!);
        final endWorldPos = _lastFocalPoint != null ? _screenToWorld(_lastFocalPoint!) : worldPos;
        final distWorld = (endWorldPos - worldPos).distance;

        if (distWorld < 12.0 && screenVelocity < 200.0) {
          _handleTap(worldPos);
        }
      }
    }

    _pointerDownScreenPosition = null;
    _lastFocalPoint = null;
    _maxPointerCountDuringGesture = 0;
    _isNodeMoveUnlocked = false;
    _hasPannedCanvas = false;
  }

  void centrarLienzo({bool preserveScale = true}) {
    _centrarLienzo(preserveScale: preserveScale);
  }

  void _centrarLienzo({bool preserveScale = true}) {
    if (!mounted) return;
    final screenSize = MediaQuery.of(context).size;
    if (screenSize.width <= 0 || screenSize.height <= 0) return;

    final minDim = min(screenSize.width, screenSize.height);
    final baseScale = minDim > 0 ? (minDim / (baseViewNodes * nodeDiameter)) : 1.0;

    double scaleToUse = baseScale;
    if (preserveScale) {
      final existingScale = _getXYScale();
      if (existingScale > 0 && existingScale.isFinite) {
        scaleToUse = existingScale;
      }
    }

    final screenCenterX = screenSize.width / 2.0;
    final screenCenterY = screenSize.height / 2.0;

    final m = Matrix4.identity()
      // ignore: deprecated_member_use
      ..translate(screenCenterX, screenCenterY)
      // ignore: deprecated_member_use
      ..scale(scaleToUse, scaleToUse, 1.0);

    setState(() {
      _transform = m;
    });
  }

  void _handleNodeDragEnd(String nodeId, Offset currentWorldPos) {
    final grafo = ref.read(grafoProvider);
    final isValid = GraphGeometry.isValidNodePosition(
      candidateX: currentWorldPos.dx,
      candidateY: currentWorldPos.dy,
      candidateId: nodeId,
      existingNodes: grafo.nodos.values,
    );

    if (!isValid) {
      final validTarget = GraphGeometry.getNearestValidPosition(
        candidateX: currentWorldPos.dx,
        candidateY: currentWorldPos.dy,
        candidateId: nodeId,
        existingNodes: grafo.nodos.values,
      );

      _animatingNodeId = nodeId;
      _snapBackAnimation =
          Tween<Offset>(
            begin: currentWorldPos,
            end: Offset(validTarget.x, validTarget.y),
          ).animate(
            CurvedAnimation(
              parent: _snapBackController,
              curve: Curves.elasticOut,
            ),
          );

      _snapBackController.forward(from: 0.0);
    }
  }

  void _handleTap(Offset worldPos) {
    // Zoom Lockout Guard: Block all tap actions & node creations while zoom lockout is active
    if (_isZoomLockoutActive) {
      return;
    }

    final grafo = ref.read(grafoProvider);
    final modoActivo = ref.read(modoActivoProvider);
    final now = DateTime.now();

    final hitNodes = GraphHitTester.hitTestAllNodes(worldPos, grafo.nodos.values, scale: _getXYScale());
    final hitConns = GraphHitTester.hitTestAllConnections(worldPos, grafo, _getXYScale());
    final totalHits = hitNodes.length + hitConns.length;

    // Directly trigger deletion dialog if current active mode is ModoActivo.eliminar!
    if (modoActivo == ModoActivo.eliminar) {
      if (totalHits > 1) {
        showDialog(
          context: context,
          builder: (context) {
            return OverlappingElementsDialog(
              nodes: hitNodes,
              connections: hitConns,
              nodeMap: grafo.nodos,
              onSelected: (item) {
                if (item.isNode) {
                  final nodo = grafo.nodos[item.id];
                  if (nodo != null) _showDeleteNodeDialog(nodo);
                } else {
                  final conn = grafo.conexiones[item.id];
                  if (conn != null) _showDeleteConnectionDialog(conn);
                }
              },
            );
          },
        );
      } else if (hitNodes.isNotEmpty) {
        _showDeleteNodeDialog(hitNodes.first);
      } else if (hitConns.isNotEmpty) {
        _showDeleteConnectionDialog(hitConns.first);
      }
      return;
    }

    // Check double tap for self loop
    if (hitNodes.isNotEmpty) {
      final firstNode = hitNodes.first;
      if (_lastTapNodeId == firstNode.id &&
          _lastTapTime != null &&
          now.difference(_lastTapTime!).inMilliseconds < 300) {
        // Double tap detected on node -> Cancel single-tap edit timer & create self loop!
        _singleTapEditTimer?.cancel();
        _lastTapNodeId = null;
        _lastTapTime = null;
        ref.read(grafoProvider.notifier).agregarConexion(firstNode.id, firstNode.id);
        return;
      }

      // First tap on node: cancel previous timer and set a 300ms debounce timer for edit mode
      _singleTapEditTimer?.cancel();
      _lastTapNodeId = firstNode.id;
      _lastTapTime = now;

      _singleTapEditTimer = Timer(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _lastTapNodeId = null;
        _lastTapTime = null;

        if (totalHits > 1) {
          showDialog(
            context: context,
            builder: (context) {
              return OverlappingElementsDialog(
                nodes: hitNodes,
                connections: hitConns,
                nodeMap: grafo.nodos,
                onSelected: (item) {
                  if (item.isNode) {
                    ref.read(estadoEdicionProvider.notifier).seleccionarNodo(item.id);
                  } else {
                    ref.read(estadoEdicionProvider.notifier).seleccionarConexion(item.id);
                  }
                },
              );
            },
          );
        } else {
          ref.read(estadoEdicionProvider.notifier).seleccionarNodo(firstNode.id);
        }
      });
      return;
    } else {
      _singleTapEditTimer?.cancel();
      _lastTapNodeId = null;
      _lastTapTime = null;
    }

    if (totalHits > 1) {
      // Overlapping connections! Trigger selection modal
      showDialog(
        context: context,
        builder: (context) {
          return OverlappingElementsDialog(
            nodes: hitNodes,
            connections: hitConns,
            nodeMap: grafo.nodos,
            onSelected: (item) {
              if (item.isNode) {
                ref.read(estadoEdicionProvider.notifier).seleccionarNodo(item.id);
              } else {
                ref.read(estadoEdicionProvider.notifier).seleccionarConexion(item.id);
              }
            },
          );
        },
      );
    } else if (hitConns.length == 1) {
      ref.read(estadoEdicionProvider.notifier).seleccionarConexion(hitConns.first.id);
    } else {
      // Tap empty canvas -> Create node!
      final validPos = GraphGeometry.getNearestValidPosition(
        candidateX: worldPos.dx,
        candidateY: worldPos.dy,
        candidateId: 'temp_new',
        existingNodes: grafo.nodos.values,
      );

      ref.read(grafoProvider.notifier).agregarNodo(validPos.x, validPos.y);
      ref.read(estadoEdicionProvider.notifier).deseleccionar();
      _singleTapEditTimer?.cancel();
      _lastTapNodeId = null;
      _lastTapTime = null;
    }
  }

  void _triggerContextMenu(Offset screenPos, String targetId, bool isNode) {
    setState(() {
      _contextMenuScreenPosition = screenPos;
      _contextMenuTargetId = targetId;
      _contextMenuIsNode = isNode;
    });
  }

  Future<void> _showDeleteNodeDialog(Nodo nodo) async {
    final grafo = ref.read(grafoProvider);
    final conexiones = grafo.obtenerConexionesDeNodo(nodo.id);
    final atributos = ref.read(atributosGlobalesProvider);

    final Map<String, String> attrNames = {
      for (final a in atributos) a.id: a.nombre
    };
    final Map<String, String> nodeNames = {
      for (final n in grafo.nodos.values) n.id: n.nombre ?? n.id
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return DeleteConfirmationDialog(
          isNode: true,
          nodeName: nodo.nombre ?? nodo.id,
          connectionsToDelete: conexiones,
          attributeNames: attrNames,
          nodeNames: nodeNames,
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    _draggedNodeId = null;
    _animatingNodeId = null;
    _dragConnectingStartNodeId = null;
    _dragConnectingTargetNodeId = null;
    _lastTapNodeId = null;
    _contextMenuTargetId = null;

    ref.read(estadoEdicionProvider.notifier).deseleccionar();
    ref.read(estadoCreacionProvider.notifier).reset();
    ref.read(grafoProvider.notifier).eliminarNodo(nodo.id);
  }

  Future<void> _showDeleteConnectionDialog(Conexion conexion) async {
    final grafo = ref.read(grafoProvider);
    final atributos = ref.read(atributosGlobalesProvider);

    final Map<String, String> attrNames = {
      for (final a in atributos) a.id: a.nombre
    };
    final Map<String, String> nodeNames = {
      for (final n in grafo.nodos.values) n.id: n.nombre ?? n.id
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return DeleteConfirmationDialog(
          isNode: false,
          targetConnection: conexion,
          attributeNames: attrNames,
          nodeNames: nodeNames,
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    _draggedConnId = null;
    _contextMenuTargetId = null;

    ref.read(estadoEdicionProvider.notifier).deseleccionar();
    ref.read(estadoCreacionProvider.notifier).reset();
    ref.read(grafoProvider.notifier).eliminarConexion(conexion.id);
  }



  GraphRenderModel _buildRenderModel() {
    final palette = NeumorphicPalette.of(context);
    final grafo = ref.watch(grafoProvider);
    final desconectados = ref.watch(nodosDesconectadosProvider);
    final edicion = ref.watch(estadoEdicionProvider);
    final creacion = ref.watch(estadoCreacionProvider);

    return GraphRenderModel.fromGrafo(
      grafo,
      palette: palette,
      selectedItemId: edicion.itemSeleccionadoId,
      isSelectedNode: edicion.esNodo,
      disconnectedNodeIds: desconectados,
      pendingConnectNodeId: creacion.primerNodoSeleccionado,
      dragConnectingStartNodeId: _dragConnectingStartNodeId,
      dragConnectingCurrentPos: _dragConnectingCurrentPos,
      dragConnectingTargetNodeId: _dragConnectingTargetNodeId,
    );
  }



  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      _triggerZoomLockout();
      _scheduleZoomLockoutRelease();
      final focalPoint = event.position;
      final scaleFactor = event.scrollDelta.dy > 0 ? 0.9 : 1.1;
      final currentScale = _getXYScale();

      final screenSize = MediaQuery.of(context).size;
      final minDim = min(screenSize.width, screenSize.height);
      final baseScale = minDim > 0 ? (minDim / (baseViewNodes * nodeDiameter)) : 1.0;
      final minZoomOutScale = baseScale * (baseViewNodes / maxViewNodes);
      final maxZoomInScale = baseScale * (baseViewNodes / minViewNodes);

      final targetScale = (currentScale * scaleFactor).clamp(minZoomOutScale, maxZoomInScale);
      final effectiveFactor = targetScale / currentScale;

      setState(() {
        final update = Matrix4.identity()
          // ignore: deprecated_member_use
          ..translate(focalPoint.dx, focalPoint.dy)
          // ignore: deprecated_member_use
          ..scale(effectiveFactor, effectiveFactor, 1.0)
          // ignore: deprecated_member_use
          ..translate(-focalPoint.dx, -focalPoint.dy);
        _transform = update..multiply(_transform);
        _ensureValidTransform();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Grafo>(grafoProvider, (previous, next) {
      if (previous != null && (previous.nodos.isEmpty && next.nodos.isEmpty)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _centrarLienzo();
            _isInitialCentered = true;
          }
        });
      }
    });

    if (!_isInitialCentered) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isInitialCentered) {
          _centrarLienzo();
          _isInitialCentered = true;
        }
      });
    }

    final renderModel = _buildRenderModel();
    final palette = NeumorphicPalette.of(context);

    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      onPointerSignal: _onPointerSignal,
      child: GestureDetector(
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onScaleEnd: _onScaleEnd,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: palette.canvasBg,
          child: Stack(
          children: [
            CustomPaint(
              size: Size.infinite,
              painter: GraphPainter(
                renderModel: renderModel,
                transform: _transform,
                palette: palette,
              ),
            ),
            if (_contextMenuScreenPosition != null &&
                _contextMenuTargetId != null)
              Positioned(
                left: min(
                  _contextMenuScreenPosition!.dx,
                  MediaQuery.of(context).size.width - 150,
                ),
                top: min(
                  _contextMenuScreenPosition!.dy,
                  MediaQuery.of(context).size.height - 120,
                ),
                child: FloatingContextMenu(
                  onEdit: () {
                    final targetId = _contextMenuTargetId!;
                    final isNode = _contextMenuIsNode;
                    setState(() {
                      _contextMenuScreenPosition = null;
                    });
                    if (isNode) {
                      ref
                          .read(estadoEdicionProvider.notifier)
                          .seleccionarNodo(targetId);
                    } else {
                      ref
                          .read(estadoEdicionProvider.notifier)
                          .seleccionarConexion(targetId);
                    }
                  },
                  onDelete: () {
                    final targetId = _contextMenuTargetId!;
                    final isNode = _contextMenuIsNode;
                    setState(() {
                      _contextMenuScreenPosition = null;
                    });
                    final grafo = ref.read(grafoProvider);
                    if (isNode) {
                      final nodo = grafo.nodos[targetId];
                      if (nodo != null) _showDeleteNodeDialog(nodo);
                    } else {
                      final conn = grafo.conexiones[targetId];
                      if (conn != null) _showDeleteConnectionDialog(conn);
                    }
                  },
                  onDismiss: () {
                    setState(() {
                      _contextMenuScreenPosition = null;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }
}

class _MockGrafoNotifier extends GrafoNotifier {
  final Grafo _initial;
  _MockGrafoNotifier(this._initial);

  @override
  Grafo build() => _initial;
}

@Preview(name: 'GraphCanvas - Sample Graph', group: 'Canvas')
Widget graphCanvasPreview() {
  final sampleGraph = Grafo(
    nodos: {
      'n1': const Nodo(
        id: 'n1',
        x: -100,
        y: -50,
        nombre: 'Nodo A',
        colorValue: 0xFF2196F3,
      ),
      'n2': const Nodo(
        id: 'n2',
        x: 100,
        y: -50,
        nombre: 'Nodo B',
        colorValue: 0xFF4CAF50,
      ),
      'n3': const Nodo(
        id: 'n3',
        x: 0,
        y: 100,
        nombre: 'Nodo C',
        colorValue: 0xFFFF9800,
      ),
    },
    conexiones: {
      'c1': const Conexion(
        id: 'c1',
        nodoOrigenId: 'n1',
        nodoDestinoId: 'n2',
        direccion: Direccion.unidireccional,
        colorValue: 0xFF2196F3,
      ),
      'c2': const Conexion(
        id: 'c2',
        nodoOrigenId: 'n2',
        nodoDestinoId: 'n3',
        direccion: Direccion.bidireccional,
        colorValue: 0xFF4CAF50,
      ),
    },
  );

  return ProviderScope(
    overrides: [
      grafoProvider.overrideWith(() => _MockGrafoNotifier(sampleGraph)),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const Scaffold(body: GraphCanvas()),
    ),
  );
}
