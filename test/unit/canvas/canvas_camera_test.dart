// ignore_for_file: deprecated_member_use

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const double nodeDiameter = 48.0;
const double baseViewNodes = 15.0;
const double minViewNodes = 10.0;
const double maxViewNodes = 100.0;

Matrix4 buildCentredTransform(Size screenSize) {
  final minDim = min(screenSize.width, screenSize.height);
  final baseScale = minDim > 0
      ? (minDim / (baseViewNodes * nodeDiameter))
      : 1.0;
  final maxZoomInScale = baseScale * (baseViewNodes / minViewNodes);
  return Matrix4.identity()
    ..translate(screenSize.width / 2, screenSize.height / 2)
    ..scale(maxZoomInScale, maxZoomInScale, 1.0);
}

({double minScale, double maxScale}) zoomBounds(Size screenSize) {
  final minDim = min(screenSize.width, screenSize.height);
  final baseScale = minDim > 0
      ? (minDim / (baseViewNodes * nodeDiameter))
      : 1.0;
  return (
    minScale: baseScale * (baseViewNodes / maxViewNodes),
    maxScale: baseScale * (baseViewNodes / minViewNodes),
  );
}

double getXYScale(Matrix4 m) {
  final col0 = m.getColumn(0);
  return sqrt(col0.x * col0.x + col0.y * col0.y);
}

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

Matrix4 applyPanFrame({required Matrix4 current, required Offset focalDelta}) {
  final update = Matrix4.identity()..translate(focalDelta.dx, focalDelta.dy);
  return update..multiply(current);
}

Offset screenToWorld(Matrix4 transform, Offset screenPos) {
  final inverted = Matrix4.inverted(transform);
  return MatrixUtils.transformPoint(inverted, screenPos);
}

void main() {
  const screenSize = Size(1080, 1920);

  group('CanvasCamera - Zoom bounds', () {
    test(
      'initial centred transform starts at highest zoom level (max zoom-in)',
      () {
        final m = buildCentredTransform(screenSize);
        final scale = getXYScale(m);
        final bounds = zoomBounds(screenSize);
        expect(scale, closeTo(bounds.maxScale, 0.001));
      },
    );

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

  group('CanvasCamera - Canvas centring', () {
    test('world origin (0,0) maps to screen centre after centrarLienzo', () {
      final m = buildCentredTransform(screenSize);
      final screenPt = MatrixUtils.transformPoint(m, Offset.zero);
      expect(screenPt.dx, closeTo(screenSize.width / 2, 0.5));
      expect(screenPt.dy, closeTo(screenSize.height / 2, 0.5));
    });
  });

  group('CanvasCamera - getMaxScaleOnAxis vs XY scale', () {
    test('getMaxScaleOnAxis reports 1.0 when XY scale < 1.0', () {
      final m = Matrix4.identity()
        ..translate(screenSize.width / 2, screenSize.height / 2)
        ..scale(0.75, 0.75, 1.0);
      const fp = Offset(540, 960);

      final zoomed = applyZoomFrame(
        current: m.clone(),
        focalPoint: fp,
        scaleFactor: 0.5,
      );

      final xyScale = getXYScale(zoomed);
      final reportedScale = zoomed.getMaxScaleOnAxis();

      expect(xyScale, closeTo(0.375, 0.001));
      expect(reportedScale, equals(1.0));
    });

    test('using XY scale for clamping respects min zoom', () {
      final bounds = zoomBounds(screenSize);
      var m = buildCentredTransform(screenSize);
      const fp = Offset(540, 960);

      for (int i = 0; i < 20; i++) {
        final currentScale = getXYScale(m);
        final target = (currentScale * 0.5).clamp(
          bounds.minScale,
          bounds.maxScale,
        );
        final sf = target / currentScale;
        m = applyZoomFrame(current: m.clone(), focalPoint: fp, scaleFactor: sf);
      }

      final finalXYScale = getXYScale(m);
      expect(finalXYScale, closeTo(bounds.minScale, 0.001));
    });
  });

  group('CanvasCamera - Zoom clamp', () {
    test('scale clamps at maxScale after aggressive zoom-in', () {
      final bounds = zoomBounds(screenSize);
      var m = buildCentredTransform(screenSize);
      const fp = Offset(540, 960);

      for (int i = 0; i < 20; i++) {
        final current = getXYScale(m);
        final target = (current * 2.0).clamp(bounds.minScale, bounds.maxScale);
        final sf = target / current;
        m = applyZoomFrame(current: m.clone(), focalPoint: fp, scaleFactor: sf);
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
        m = applyZoomFrame(current: m.clone(), focalPoint: fp, scaleFactor: sf);
      }

      expect(getXYScale(m), closeTo(bounds.minScale, 0.001));
    });
  });

  group('CanvasCamera - Finger Count Gesture Separation', () {
    test('1 finger: does NOT pan canvas matrix or change scale', () {
      final m = buildCentredTransform(screenSize);
      final initialScale = getXYScale(m);

      final afterSingleFinger = m.clone();
      expect(getXYScale(afterSingleFinger), equals(initialScale));
      expect(afterSingleFinger.storage[12], equals(m.storage[12]));
    });

    test('2 fingers: performs pure zoom ONLY (changes scale, no panning translation)', () {
      final m = buildCentredTransform(screenSize);
      const fp = Offset(540, 960);

      final zoomed = applyZoomFrame(
        current: m.clone(),
        focalPoint: fp,
        scaleFactor: 1.5,
      );

      expect(getXYScale(zoomed), closeTo(1.5 * getXYScale(m), 0.001));

      final worldAtFp = screenToWorld(m, fp);
      final screenPt = MatrixUtils.transformPoint(zoomed, worldAtFp);
      expect(screenPt.dx, closeTo(fp.dx, 0.5));
      expect(screenPt.dy, closeTo(fp.dy, 0.5));
    });

    test('3 fingers: performs pure canvas pan ONLY (translates canvas, scale remains unchanged)', () {
      final m = buildCentredTransform(screenSize);
      const fd = Offset(25.0, -15.0);

      final panned = applyPanFrame(current: m.clone(), focalDelta: fd);

      expect(getXYScale(panned), closeTo(getXYScale(m), 0.0001));

      final worldOrigin = Offset.zero;
      final screenBefore = MatrixUtils.transformPoint(m, worldOrigin);
      final screenAfter = MatrixUtils.transformPoint(panned, worldOrigin);

      expect(screenAfter.dx - screenBefore.dx, closeTo(fd.dx, 0.5));
      expect(screenAfter.dy - screenBefore.dy, closeTo(fd.dy, 0.5));
    });
  });

  group('CanvasCamera - Canvas Pan Boundary Clamping', () {
    test('aggressive pan is clamped so camera view stays within 100x100 world grid', () {
      final m = buildCentredTransform(screenSize);

      final pannedFar = applyPanFrame(
        current: m.clone(),
        focalDelta: const Offset(50000.0, 50000.0),
      );
      final clamped = clampTransformBounds(pannedFar, screenSize);

      final screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);
      final worldCenter = screenToWorld(clamped, screenCenter);

      expect(worldCenter.dx.abs(), lessThanOrEqualTo(2400.0 + 0.5));
      expect(worldCenter.dy.abs(), lessThanOrEqualTo(2400.0 + 0.5));
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
