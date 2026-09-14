import 'dart:math';

import 'package:flutter/material.dart';

import '../models/grafo.dart';

/// Helper utility service for generating vibrant, maximally distinct colors for graph nodes.
class GraphColorGenerator {
  /// Generates a bright HSV color value that maximizes minimum hue distance from all existing nodes in [grafo].
  static int generateMaximallyDistinctColor(Grafo grafo) {
    final existingHues = grafo.nodos.values
        .map((n) => HSVColor.fromColor(Color(n.colorValue)).hue)
        .toList();

    if (existingHues.isEmpty) {
      final initialHue = Random().nextDouble() * 360.0;
      return HSVColor.fromAHSV(
        1.0,
        initialHue,
        0.85,
        0.95,
      ).toColor().toARGB32();
    }

    double bestHue = 0.0;
    double maxMinDistance = -1.0;

    for (int i = 0; i < 72; i++) {
      final candHue = i * 5.0;
      double minDistance = 360.0;

      for (final existingHue in existingHues) {
        double diff = (candHue - existingHue).abs();
        if (diff > 180.0) {
          diff = 360.0 - diff;
        }
        if (diff < minDistance) {
          minDistance = diff;
        }
      }

      if (minDistance > maxMinDistance) {
        maxMinDistance = minDistance;
        bestHue = candHue;
      }
    }

    final rng = Random();
    final sat = 0.75 + rng.nextDouble() * 0.20;
    final val = 0.85 + rng.nextDouble() * 0.15;
    return HSVColor.fromAHSV(1.0, bestHue, sat, val).toColor().toARGB32();
  }
}
