import 'dart:math' as math;

import 'package:flutter/material.dart';

class SortingVisualTokens {
  const SortingVisualTokens._();

  static const double pinAspect = 39.54 / 114.06;
  static const double compactSlotWidth = 32;
  static const Color current = Color(0xFF7650B4);
  static const Color compared = Color(0xFF087E91);
  static const Color minimum = Color(0xFFAD6900);
  static const Color key = Color(0xFF6247AD);
  static const Color ordered = Color(0xFF27815F);
  static const Color internallyOrdered = Color(0xFF337B85);
  static const Color neutral = Color(0xFF847990);
  static const Color stripe = Color(0xFFC45A5D);

  static double relativeHeight(int value, int maxAbsolute, int minPositive) {
    if (maxAbsolute == 0) return 0.64;
    final absolute = value.abs();
    final useLog = maxAbsolute > minPositive * 20;
    final ratio = useLog
        ? math.log(1 + absolute) / math.log(1 + maxAbsolute)
        : absolute / maxAbsolute;
    return 0.56 + 0.44 * math.sqrt(ratio);
  }
}
