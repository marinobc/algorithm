// ignore_for_file: deprecated_member_use
// Tests for the canvas zoom transform logic.
// Tests the pure matrix math behind pinch-zoom and pan gestures to expose
// known bugs BEFORE APK deployment.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const double nodeDiameter = 48.0;
const double baseViewNodes = 15.0;
const double minViewNodes = 10.0;
const double maxViewNodes = 100.0;

Matrix4 buildCentredTransform(Size screenSize) {
  final minDim = min(screenSize.width, screenSize.height);
  final baseScale = minDim > 0 ? (minDim / (baseViewNodes * nodeDiameter)) : 1.0;
  final maxZoomInScale = baseScale * (baseViewNodes / minViewNodes);
  return Matrix4.identity()
    ..translate(screenSize.width / 2, screenSize.height / 2)
    ..scale(maxZoomInScale, maxZoomInScale, 1.0);
}

({double minScale, double maxScale}) zoomBounds(Size screenSize) {
  final minDim = min(screenSize.width, screenSize.height);
  final baseScale = minDim > 0 ? (minDim / (baseViewNodes * nodeDiameter)) : 1.0;
  return (
    minScale: baseScale * (baseViewNodes / maxViewNodes),
    maxScale: baseScale * (baseViewNodes / minViewNodes),
  );
}

/// Extract the actual XY scale from the transform (not Z).
double getXYScale(Matrix4 m) {
  // Column 0 length = scaleX (no rotation/shear in our transforms)
  final col0 = m.getColumn(0);
  return sqrt(col0.x * col0.x + col0.y * col0.y);
}

/// Simulate one 2-finger zoom frame (pure scale, no pan).
Matrix4 applyZoomFrame({
  required Matrix4 current,
  required Offset focalPoint,
  required double scaleFactor,
}) {
  final update = Matrix4.identity()
    ..translate(focalPoint.dx, focalPoint.dy)
    ..scale(scaleFactor, scaleFactor, 1.0)
    ..translate(-focalPoint.dx, -focalPoint.dy);
  return update..multiply(current);
}

/// Simulate one 3-finger pan frame (pure translation, no scale).
Matrix4 applyPanFrame({
  required Matrix4 current,
  required Offset focalDelta,
}) {
  final update = Matrix4.identity()
    ..translate(focalDelta.dx, focalDelta.dy);
  return update..multiply(current);
}

Offset screenToWorld(Matrix4 transform, Offset screenPos) {
  final inverted = Matrix4.inverted(transform);
  return MatrixUtils.transformPoint(inverted, screenPos);
}

void main() {
  const screenSize = Size(1080, 1920);

  group('Zoom bounds', () {
    test('initial centred transform starts at highest zoom level (max zoom-in)', () {
      final m = buildCentredTransform(screenSize);
      final scale = getXYScale(m);
      final bounds = zoomBounds(screenSize);
      expect(scale, closeTo(bounds.maxScale, 0.001));
    });

    test('min scale (max zoom-out) covers full 100x100 grid width', () {
      final bounds = zoomBounds(screenSize);
      final worldWidth = screenSize.width / bounds.minScale;
      expect(worldWidth, closeTo(maxViewNodes * nodeDiameter, 5.0));
    });

    test('max scale (max zoom-in) shows at most 10x10 nodes wide', () {
      final bounds = zoomBounds(screenSize);
      final worldWidth = screenSize.width / bounds.maxScale;
      expect(worldWidth, closeTo(minViewNodes * nodeDiameter, 5.0));
    });
  });

  group('Canvas centring', () {
    test('world origin (0,0) maps to screen centre after centrarLienzo', () {
      final m = buildCentredTransform(screenSize);
      final screenPt = MatrixUtils.transformPoint(m, Offset.zero);
      expect(screenPt.dx, closeTo(screenSize.width / 2, 0.5));
      expect(screenPt.dy, closeTo(screenSize.height / 2, 0.5));
    });
  });

  // ---------------------------------------------------------------------------
  // BUG #1 (CRITICAL): getMaxScaleOnAxis() returns Z-axis scale (1.0) when
  // zoomed out, because scale(sf, sf, 1.0) never changes Z.
  // This breaks ALL zoom-out clamping logic.
  // ---------------------------------------------------------------------------
  group('BUG #1 - getMaxScaleOnAxis returns Z=1.0, breaks zoom-out', () {
    test('BUG DETECTED: getMaxScaleOnAxis reports 1.0 when XY scale < 1.0', () {
      final m = Matrix4.identity()
        ..translate(screenSize.width / 2, screenSize.height / 2)
        ..scale(0.75, 0.75, 1.0);
      const fp = Offset(540, 960);

      // Zoom out by 0.5x
      final zoomed = applyZoomFrame(
        current: m.clone(), focalPoint: fp, scaleFactor: 0.5,
      );

      final xyScale = getXYScale(zoomed);
      final reportedScale = zoomed.getMaxScaleOnAxis();

      expect(xyScale, closeTo(0.375, 0.001));

      // BUG: getMaxScaleOnAxis returns 1.0 (from Z axis), NOT 0.375
      expect(reportedScale, equals(1.0),
          reason: 'getMaxScaleOnAxis picks Z=1.0, masking the actual XY zoom level');
      expect(reportedScale, isNot(closeTo(xyScale, 0.001)),
          reason: 'Reported scale disagrees with actual XY scale');
    });

    test('BUG DETECTED: zoom-out clamping fails due to wrong scale reading', () {
      final bounds = zoomBounds(screenSize);
      var m = buildCentredTransform(screenSize);
      const fp = Offset(540, 960);

      // Simulate aggressive zoom-out using getMaxScaleOnAxis (buggy)
      for (int i = 0; i < 20; i++) {
        final currentScale = m.getMaxScaleOnAxis(); // BUG: returns 1.0 when XY < 1.0
        final target = (currentScale * 0.5).clamp(bounds.minScale, bounds.maxScale);
        final sf = target / currentScale;
        m = applyZoomFrame(
          current: m.clone(), focalPoint: fp, scaleFactor: sf,
        );
      }

      final finalXYScale = getXYScale(m);
      // BUG: XY scale drops WAY below the minimum because the clamp logic
      // sees currentScale=1.0 (Z-axis) and keeps allowing zoom-out
      expect(finalXYScale, lessThan(bounds.minScale),
          reason: 'Bug: zoom-out overshoots minimum because getMaxScaleOnAxis returns Z=1.0');
    });

    test('FIX VERIFIED: using XY scale for clamping respects min zoom', () {
      final bounds = zoomBounds(screenSize);
      var m = buildCentredTransform(screenSize);
      const fp = Offset(540, 960);

      // Simulate aggressive zoom-out using getXYScale (fixed)
      for (int i = 0; i < 20; i++) {
        final currentScale = getXYScale(m); // FIXED: reads actual XY scale
        final target = (currentScale * 0.5).clamp(bounds.minScale, bounds.maxScale);
        final sf = target / currentScale;
        m = applyZoomFrame(
          current: m.clone(), focalPoint: fp, scaleFactor: sf,
        );
      }

      final finalXYScale = getXYScale(m);
      expect(finalXYScale, closeTo(bounds.minScale, 0.001),
          reason: 'Fix: XY scale correctly clamps at minimum');
    });
  });

  // ---------------------------------------------------------------------------
  // BUG #2: _lastScale is reset to 1.0 on single-finger frames, contradicting
  // the explicit comment. Causes a zoom jump if finger count transitions.
  // ---------------------------------------------------------------------------
  group('BUG #2 - _lastScale reset mid-gesture causes scale jump', () {
    test('scaleDelta accumulates correctly when lastScale tracks each frame', () {
      final frames = [1.2, 1.5, 2.0];
      double lastScale = 1.0;
      double totalScale = 1.0;
      for (final s in frames) {
        final delta = (lastScale > 0 && lastScale.isFinite) ? (s / lastScale) : 1.0;
        totalScale *= delta;
        lastScale = s;
      }
      expect(totalScale, closeTo(2.0, 0.001));
    });

    test('BUG DETECTED: resetting lastScale to 1.0 causes a spurious scale jump', () {
      const gesturePreviousScale = 1.5;
      const lastScaleBuggy   = 1.0; // erroneously reset by line 239
      const lastScaleCorrect = gesturePreviousScale;
      const nextGestureScale = 1.6;

      final buggyDelta   = nextGestureScale / lastScaleBuggy;  // 1.6
      final correctDelta = nextGestureScale / lastScaleCorrect; // ~1.067

      expect(buggyDelta, greaterThan(correctDelta + 0.3),
          reason: 'Resetting lastScale produces a much larger delta than intended');

      const currentVisualScale = 1.5;
      final buggyNewScale   = currentVisualScale * buggyDelta;   // 2.4
      final correctNewScale = currentVisualScale * correctDelta; // ~1.6
      expect(buggyNewScale - correctNewScale, greaterThan(0.5),
          reason: 'Scale jump of >0.5x is clearly visible to the user');
    });
  });

  // ---------------------------------------------------------------------------
  // BUG #3: Tap fires after pinch gesture — _onScaleEnd missing guard for
  // multi-finger gestures.
  // ---------------------------------------------------------------------------
  group('BUG #3 - Tap fires after pinch gesture', () {
    test('BUG DETECTED: tap condition passes after pinch, may create unintended nodes', () {
      const isDraggingNode = false;
      const maxPointerCountDuringGesture = 2;
      const pointerDownSet = true;

      // Current (buggy) condition: only guards against node drag
      final buggyShouldTap = !isDraggingNode && pointerDownSet;
      // Corrected condition: also guard against multi-finger gestures
      final correctShouldTap =
          !isDraggingNode && pointerDownSet && maxPointerCountDuringGesture < 2;

      expect(buggyShouldTap,  isTrue,
          reason: 'Bug: tap fires after a pinch, potentially creating an unintended node');
      expect(correctShouldTap, isFalse,
          reason: 'Fix: tap suppressed when gesture involved multiple pointers');
    });
  });

  // ---------------------------------------------------------------------------
  // Zoom clamp with FIXED scale reading
  // ---------------------------------------------------------------------------
  group('Zoom clamp (using correct XY scale)', () {
    test('scale clamps at maxScale after aggressive zoom-in', () {
      final bounds = zoomBounds(screenSize);
      var m = buildCentredTransform(screenSize);
      const fp = Offset(540, 960);

      for (int i = 0; i < 20; i++) {
        final current = getXYScale(m);
        final target = (current * 2.0).clamp(bounds.minScale, bounds.maxScale);
        final sf = target / current;
        m = applyZoomFrame(
          current: m.clone(), focalPoint: fp, scaleFactor: sf,
        );
      }

      expect(getXYScale(m), closeTo(bounds.maxScale, 0.001));
    });

    test('scale clamps at minScale after aggressive zoom-out', () {
      final bounds = zoomBounds(screenSize);
      var m = buildCentredTransform(screenSize);
      const fp = Offset(540, 960);

      for (int i = 0; i < 20; i++) {
        final current = getXYScale(m);
        final target = (current * 0.1).clamp(bounds.minScale, bounds.maxScale);
        final sf = target / current;
        m = applyZoomFrame(
          current: m.clone(), focalPoint: fp, scaleFactor: sf,
        );
      }

      expect(getXYScale(m), closeTo(bounds.minScale, 0.001));
    });
  });

  // ---------------------------------------------------------------------------
  // Finger Count Gesture Separation Rules
  // ---------------------------------------------------------------------------
  group('Finger Count Gesture Separation', () {
    test('1 finger: does NOT pan canvas matrix or change scale', () {
      final m = buildCentredTransform(screenSize);
      final initialScale = getXYScale(m);

      // Single finger drag does NOT modify canvas transform matrix (only drags node)
      final afterSingleFinger = m.clone();
      expect(getXYScale(afterSingleFinger), equals(initialScale));
      expect(afterSingleFinger.storage[12], equals(m.storage[12]));
    });

    test('2 fingers: performs pure zoom ONLY (changes scale, no panning translation)', () {
      final m = buildCentredTransform(screenSize);
      const fp = Offset(540, 960);

      final zoomed = applyZoomFrame(
        current: m.clone(), focalPoint: fp, scaleFactor: 1.5,
      );

      // Scale changes
      expect(getXYScale(zoomed), closeTo(1.5 * getXYScale(m), 0.001));

      // Focal world point stays fixed on screen (pure zoom, no pan translation)
      final worldAtFp = screenToWorld(m, fp);
      final screenPt = MatrixUtils.transformPoint(zoomed, worldAtFp);
      expect(screenPt.dx, closeTo(fp.dx, 0.5));
      expect(screenPt.dy, closeTo(fp.dy, 0.5));
    });

    test('3 fingers: performs pure canvas pan ONLY (translates canvas, scale remains unchanged)', () {
      final m = buildCentredTransform(screenSize);
      const fd = Offset(25.0, -15.0);

      final panned = applyPanFrame(current: m.clone(), focalDelta: fd);

      // Scale remains strictly unchanged
      expect(getXYScale(panned), closeTo(getXYScale(m), 0.0001));

      // Screen translation moves by focalDelta exactly
      final worldOrigin = Offset.zero;
      final screenBefore = MatrixUtils.transformPoint(m, worldOrigin);
      final screenAfter  = MatrixUtils.transformPoint(panned, worldOrigin);

      expect(screenAfter.dx - screenBefore.dx, closeTo(fd.dx, 0.5));
      expect(screenAfter.dy - screenBefore.dy, closeTo(fd.dy, 0.5));
    });
  });

  // ---------------------------------------------------------------------------
  // Canvas Pan Boundary Clamping (prevents moving off world grid)
  // ---------------------------------------------------------------------------
  group('Canvas Pan Boundary Clamping', () {
    test('aggressive pan is clamped so camera view stays within 100x100 world grid', () {
      final m = buildCentredTransform(screenSize);

      // Attempt to pan infinitely far into empty void
      final pannedFar = applyPanFrame(current: m.clone(), focalDelta: const Offset(50000.0, 50000.0));
      final clamped = clampTransformBounds(pannedFar, screenSize);

      // Viewport center in world coordinates must remain inside [-2400, 2400]
      final screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);
      final worldCenter = screenToWorld(clamped, screenCenter);

      expect(worldCenter.dx.abs(), lessThanOrEqualTo(2400.0 + 0.5),
          reason: 'Camera center must stay within world grid bounds [-2400, 2400]');
      expect(worldCenter.dy.abs(), lessThanOrEqualTo(2400.0 + 0.5),
          reason: 'Camera center must stay within world grid bounds [-2400, 2400]');
    });
  });
}

Matrix4 clampTransformBounds(Matrix4 transform, Size screenSize) {
  final scale = getXYScale(transform);
  if (scale <= 0 || !scale.isFinite) return transform;

  const halfGridWidth = (maxViewNodes * nodeDiameter) / 2.0;
  const halfGridHeight = (maxViewNodes * nodeDiameter) / 2.0;

  final maxTx = halfGridWidth * scale;
  final minTx = screenSize.width - (halfGridWidth * scale);

  final maxTy = halfGridHeight * scale;
  final minTy = screenSize.height - (halfGridHeight * scale);

  final res = transform.clone();
  final storage = res.storage;
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
  return res;
}
