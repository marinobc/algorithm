import 'dart:async';

import 'package:flutter/material.dart';

/// State object holding transient user gesture tracking data for GraphCanvas.
class CanvasGestureState {
  Offset? pointerDownScreenPosition;
  Timer? longPressTimer;
  bool isDraggingNode = false;
  String? draggedNodeId;
  bool isDraggingConn = false;
  String? draggedConnId;
  double lastScale = 1.0;
  Offset? lastFocalPoint;
  bool isInitialCentered = false;
  int maxPointerCountDuringGesture = 0;

  // Live drag-to-connect state tracking
  String? dragConnectingStartNodeId;
  Offset? dragConnectingCurrentPos;
  String? dragConnectingTargetNodeId;

  // Node Move Hold timer & unlock state
  Timer? nodeHoldTimer;
  bool isNodeMoveUnlocked = false;

  // Single-tap edit debounce timer
  Timer? singleTapEditTimer;

  // Track if current gesture panned or moved canvas
  bool hasPannedCanvas = false;

  // Zoom Lockout debouncer tracking
  bool isZoomLockoutActive = false;
  Timer? zoomLockoutTimer;
  Set<int> activePointerIds = {};
  DateTime? lastZoomGestureEndTime;

  // Double tap tracking on nodes
  String? lastTapNodeId;
  DateTime? lastTapTime;

  void resetDragConnect() {
    dragConnectingStartNodeId = null;
    dragConnectingCurrentPos = null;
    dragConnectingTargetNodeId = null;
  }

  void resetGesture() {
    pointerDownScreenPosition = null;
    lastFocalPoint = null;
    maxPointerCountDuringGesture = 0;
    isNodeMoveUnlocked = false;
    hasPannedCanvas = false;
  }

  void cancelTimers() {
    longPressTimer?.cancel();
    nodeHoldTimer?.cancel();
    singleTapEditTimer?.cancel();
    zoomLockoutTimer?.cancel();
  }
}
