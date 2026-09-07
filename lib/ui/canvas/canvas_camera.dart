import 'dart:math';

import 'package:flutter/material.dart';

/// Handles viewport transform (zoom, pan, bounds clamping, screen-to-world conversion)
/// for the graph canvas.
class CanvasCamera {
  // Spatial Base Unit & World Grid Constants
  static const double nodeDiameter = 64.0; // 1 Node unit (U)
  static const double worldGridNodes =
      100.0; // 100x100 node world grid (6400 x 6400 px)
  static const double baseViewNodes =
      8.0; // Default mode view starts zoomed-in (~8x8 nodes)
  static const double minViewNodes = 5.0; // Max zoom in displays ~5x5 nodes
  static const double maxViewNodes = 40.0; // Max zoom out displays ~40x40 nodes

  Matrix4 transform = Matrix4.identity();

  // Extract actual XY scale from the transform matrix.
  // IMPORTANT: Do NOT use getMaxScaleOnAxis() — it returns the Z-axis
  // scale (always 1.0) when XY scale drops below 1.0, which completely
  // breaks zoom-out clamping.
  double getXYScale() {
    final col0 = transform.getColumn(0);
    return sqrt(col0.x * col0.x + col0.y * col0.y);
  }

  // Convert screen coordinates to canvas world coordinates
  Offset screenToWorld(Offset screenPos, Size screenSize) {
    ensureValidTransform(screenSize);
    final inverted = Matrix4.inverted(transform);
    return MatrixUtils.transformPoint(inverted, screenPos);
  }

  void ensureValidTransform(Size screenSize) {
    final storage = transform.storage;
    bool corrupt = false;
    for (int i = 0; i < 16; i++) {
      if (storage[i].isNaN || storage[i].isInfinite) {
        corrupt = true;
        break;
      }
    }
    if (corrupt) {
      centerOnScreen(screenSize);
    } else {
      clampTransformBounds(screenSize);
    }
  }

  /// Clamp scale and translation so camera view never zooms or pans beyond bounds
  void clampTransformBounds(Size screenSize) {
    if (screenSize.width <= 0 || screenSize.height <= 0) return;

    final minDim = min(screenSize.width, screenSize.height);
    final baseScale = minDim > 0
        ? (minDim / (baseViewNodes * nodeDiameter))
        : 1.0;
    final minScale = baseScale * (baseViewNodes / maxViewNodes);
    final maxScale = baseScale * (baseViewNodes / minViewNodes);

    double scale = getXYScale();
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
      transform = scaleUpdate..multiply(transform);
      scale = targetScale;
    }

    const halfGridWidth = (worldGridNodes * nodeDiameter) / 2.0; // 2400.0
    const halfGridHeight = (worldGridNodes * nodeDiameter) / 2.0; // 2400.0

    final maxTx = halfGridWidth * scale;
    final minTx = screenSize.width - (halfGridWidth * scale);

    final maxTy = halfGridHeight * scale;
    final minTy = screenSize.height - (halfGridHeight * scale);

    final storage = transform.storage;
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

  void centerOnScreen(Size screenSize, {bool preserveScale = true}) {
    if (screenSize.width <= 0 || screenSize.height <= 0) return;

    final minDim = min(screenSize.width, screenSize.height);
    final baseScale = minDim > 0
        ? (minDim / (baseViewNodes * nodeDiameter))
        : 1.0;

    double scaleToUse = baseScale;
    if (preserveScale) {
      final existingScale = getXYScale();
      if (existingScale > 0 && existingScale.isFinite) {
        scaleToUse = existingScale;
      }
    }

    final screenCenterX = screenSize.width / 2.0;
    final screenCenterY = screenSize.height / 2.0;

    transform = Matrix4.identity()
      // ignore: deprecated_member_use
      ..translate(screenCenterX, screenCenterY)
      // ignore: deprecated_member_use
      ..scale(scaleToUse, scaleToUse, 1.0);
  }
}
