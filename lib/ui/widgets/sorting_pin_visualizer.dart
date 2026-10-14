import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/services/sorting_steps.dart';
import 'sorting_visual_tokens.dart';

class SortingPinVisualizer extends StatefulWidget {
  final List<int> values;
  final SortingStep previous;
  final SortingStep current;
  final Animation<double> progress;
  final bool followPlayback;
  final bool selectionStyle;
  final List<int>? scaleValues;

  const SortingPinVisualizer({
    super.key,
    required this.values,
    required this.previous,
    required this.current,
    required this.progress,
    this.followPlayback = false,
    this.selectionStyle = false,
    this.scaleValues,
  });

  @override
  State<SortingPinVisualizer> createState() => _SortingPinVisualizerState();
}

class _SortingPinVisualizerState extends State<SortingPinVisualizer> {
  final ScrollController _scrollController = ScrollController();
  double _viewportWidth = 0;
  double _slotWidth = 0;

  @override
  void didUpdateWidget(covariant SortingPinVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.values, widget.values)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    } else if (widget.followPlayback &&
        (oldWidget.current != widget.current || !oldWidget.followPlayback)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _followCurrent());
    }
  }

  void _followCurrent() {
    if (!mounted || !widget.followPlayback || !_scrollController.hasClients) {
      return;
    }
    final step = widget.current;
    final id = switch (step.phase) {
      SortingPhase.comparing || SortingPhase.shifting => step.comparingId,
      SortingPhase.minimum || SortingPhase.swapping => step.minimumId,
      SortingPhase.key || SortingPhase.inserting => step.keyId,
      SortingPhase.current => step.currentId,
      _ => null,
    };
    final slot = id != null
        ? step.slots[id]
        : step.sortedCount > 0
        ? (step.sortedCount - 1).toDouble()
        : null;
    if (slot == null) return;

    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) return;
    final focusX = (slot + 0.5) * _slotWidth;
    final offset = position.pixels;
    if (focusX >= offset + _viewportWidth * 0.25 &&
        focusX <= offset + _viewportWidth * 0.75) {
      return;
    }
    final destination = (focusX - _viewportWidth / 2).clamp(
      0.0,
      position.maxScrollExtent,
    );
    final duration = Duration(
      milliseconds: (step.durationMs * 0.7).round().clamp(60, 240),
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      _scrollController.jumpTo(destination);
    } else {
      _scrollController.animateTo(
        destination,
        duration: duration,
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final slotWidth = (constraints.maxWidth / widget.values.length).clamp(
          58.0,
          112.0,
        );
        final contentWidth = math.max(
          constraints.maxWidth,
          slotWidth * widget.values.length,
        );
        _viewportWidth = constraints.maxWidth;
        _slotWidth = contentWidth / widget.values.length;
        final hasOverflow = contentWidth > constraints.maxWidth + 1;
        return Scrollbar(
          controller: _scrollController,
          thumbVisibility: hasOverflow,
          trackVisibility: hasOverflow,
          interactive: true,
          thickness: 9,
          radius: const Radius.circular(4),
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: AnimatedBuilder(
              animation: widget.progress,
              builder: (context, _) => CustomPaint(
                size: Size(contentWidth, constraints.maxHeight),
                painter: _SortingPinsPainter(
                  values: widget.values,
                  scaleValues: widget.scaleValues ?? widget.values,
                  previous: widget.previous,
                  current: widget.current,
                  progress: widget.progress.value,
                  slotWidth: _slotWidth,
                  colors: colors,
                  selectionStyle: widget.selectionStyle,
                  reduceMotion: MediaQuery.disableAnimationsOf(context),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SortingPinsPainter extends CustomPainter {
  final List<int> values;
  final List<int> scaleValues;
  final SortingStep previous;
  final SortingStep current;
  final double progress;
  final double slotWidth;
  final ColorScheme colors;
  final bool selectionStyle;
  final bool reduceMotion;

  const _SortingPinsPainter({
    required this.values,
    required this.scaleValues,
    required this.previous,
    required this.current,
    required this.progress,
    required this.slotWidth,
    required this.colors,
    required this.selectionStyle,
    required this.reduceMotion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final baseY = size.height * 0.79;
    final keyY = size.height * 0.22;
    final maxHeight = math.min(
      size.height * 0.42,
      math.min(190.0, (slotWidth - 12) / SortingVisualTokens.pinAspect),
    );
    final maxAbsolute = scaleValues.fold<int>(
      0,
      (maxValue, value) => math.max(maxValue, value.abs()),
    );
    final positive = scaleValues
        .map((value) => value.abs())
        .where((v) => v > 0);
    final minPositive = positive.isEmpty ? 1 : positive.reduce(math.min);
    final curvedProgress = reduceMotion
        ? 1.0
        : Curves.easeInOutCubic.transform(progress);

    final baselinePaint = Paint()
      ..color = colors.outlineVariant
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, baseY), Offset(size.width, baseY), baselinePaint);
    int? hole;
    if (current.keyRaised && current.keyId != null) {
      final occupied = <int>{
        for (var id = 0; id < values.length; id++)
          if (id != current.keyId) current.slots[id].round(),
      };
      for (var position = 0; position < values.length; position++) {
        if (!occupied.contains(position)) {
          hole = position;
          break;
        }
      }
    }
    if (current.sortedCount > 0) {
      final prevSorted = previous.sortedCount.toDouble();
      final currSorted = current.sortedCount.toDouble();
      final animSorted =
          prevSorted + (currSorted - prevSorted) * curvedProgress;
      final sortedPaint = Paint()
        ..color = SortingVisualTokens.ordered
        ..strokeWidth = 3;
      if (hole != null && hole < animSorted) {
        canvas.drawLine(
          Offset(0, baseY + 3),
          Offset(hole * slotWidth, baseY + 3),
          sortedPaint,
        );
        canvas.drawLine(
          Offset((hole + 1) * slotWidth, baseY + 3),
          Offset(animSorted * slotWidth, baseY + 3),
          sortedPaint,
        );
      } else {
        canvas.drawLine(
          Offset(0, baseY + 3),
          Offset(animSorted * slotWidth, baseY + 3),
          sortedPaint,
        );
      }
    }

    if (hole != null) {
      final holeX = (hole + 0.5) * slotWidth;
      final holePaint = Paint()
        ..color = SortingVisualTokens.key.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(holeX, baseY - 24),
            width: math.min(slotWidth - 10, 38),
            height: 46,
          ),
          const Radius.circular(8),
        ),
        holePaint,
      );
      _paintText(
        canvas,
        'HUECO',
        Offset(holeX, baseY + 12),
        slotWidth - 4,
        SortingVisualTokens.key,
        10,
        FontWeight.w700,
      );
    }

    if (current.gap != null &&
        current.keyId != null &&
        current.comparingId != null &&
        (current.phase == SortingPhase.comparing ||
            current.phase == SortingPhase.shifting)) {
      final fromX = (current.slots[current.keyId!] + 0.5) * slotWidth;
      final toX = (current.slots[current.comparingId!] + 0.5) * slotWidth;
      final connector = Paint()
        ..color = SortingVisualTokens.compared.withValues(alpha: 0.48)
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(fromX, keyY + 7),
        Offset(toX, baseY - maxHeight * 0.58),
        connector,
      );
      _paintMarkerBadge(
        canvas,
        'gap ${current.gap}',
        Offset((fromX + toX) / 2, keyY + 27),
        math.max(slotWidth, (fromX - toX).abs()),
        SortingVisualTokens.compared,
      );
    }

    for (var id = 0; id < values.length; id++) {
      final previousX = (previous.slots[id] + 0.5) * slotWidth;
      final currentX = (current.slots[id] + 0.5) * slotWidth;
      final x = previousX + (currentX - previousX) * curvedProgress;

      final wasRaised = previous.keyId == id && previous.keyRaised;
      final isRaised = current.keyId == id && current.keyRaised;
      final raisedProgress =
          (wasRaised ? 1.0 : 0.0) +
          ((isRaised ? 1.0 : 0.0) - (wasRaised ? 1.0 : 0.0)) * curvedProgress;
      final fullHeight =
          maxHeight *
          SortingVisualTokens.relativeHeight(
            values[id],
            maxAbsolute,
            minPositive,
          );
      final compactHeight = math.min(fullHeight * 0.55, size.height * 0.15);
      final pinHeight =
          fullHeight + (compactHeight - fullHeight) * raisedProgress;
      final pinWidth = pinHeight * SortingVisualTokens.pinAspect;
      final pinBaseY = baseY + (keyY - baseY) * raisedProgress;
      final swapping =
          current.phase == SortingPhase.swapping &&
          previous.slots[id] != current.slots[id];
      final swapLift = swapping && currentX < previousX
          ? math.sin(curvedProgress * math.pi) * math.min(40, size.height * 0.1)
          : 0.0;
      final prevColor = _colorForStep(id, previous);
      final currColor = _colorForStep(id, current);
      final color =
          Color.lerp(prevColor, currColor, curvedProgress) ?? currColor;

      _paintPin(
        canvas,
        Offset(x, pinBaseY - swapLift),
        pinWidth,
        pinHeight,
        color,
      );

      _paintText(
        canvas,
        values[id].toString(),
        Offset(x, pinBaseY - swapLift + 9),
        slotWidth - 3,
        colors.onSurface,
        12,
        FontWeight.w700,
      );
      final markers = _markersFor(id);
      for (var markerIndex = 0; markerIndex < markers.length; markerIndex++) {
        final (text, markerColor) = markers[markerIndex];
        _paintMarkerBadge(
          canvas,
          text,
          Offset(
            x,
            math.max(
              3,
              pinBaseY -
                  swapLift -
                  pinHeight -
                  22 * (markers.length - markerIndex),
            ),
          ),
          slotWidth,
          markerColor,
        );
      }
    }
  }

  void _paintPin(
    Canvas canvas,
    Offset base,
    double width,
    double height,
    Color color,
  ) {
    SortingPinGlyph.paint(canvas, base, width, height, color, colors);
  }

  Color _colorForStep(int id, SortingStep step) {
    if (step.keyId == id && step.keyRaised) return SortingVisualTokens.key;
    if (step.comparingId == id) return SortingVisualTokens.compared;
    if (step.minimumId == id) return SortingVisualTokens.minimum;
    if (step.currentId == id) return SortingVisualTokens.current;
    if (step.slots[id] < step.sortedCount) return SortingVisualTokens.ordered;
    return SortingVisualTokens.neutral;
  }

  List<(String, Color)> _markersFor(int id) {
    final markers = <(String, Color)>[];
    if (current.currentId == id) {
      markers.add(('i', SortingVisualTokens.current));
    }
    if (current.comparingId == id) {
      markers.add(('j', SortingVisualTokens.compared));
    }
    if (current.minimumId == id) {
      markers.add(('MIN', SortingVisualTokens.minimum));
    }
    if (current.keyId == id && current.keyRaised) {
      markers.add(('KEY', SortingVisualTokens.key));
    }
    if (markers.isEmpty && current.slots[id] < current.sortedCount) {
      markers.add(('✓', SortingVisualTokens.ordered));
    }
    return markers;
  }

  void _paintMarkerBadge(
    Canvas canvas,
    String text,
    Offset centerTop,
    double slotWidth,
    Color color,
  ) {
    final width = math.min(slotWidth - 6, text.startsWith('gap') ? 62.0 : 50.0);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerTop.dx - width / 2, centerTop.dy, width, 18),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, Paint()..color = colors.surface);
    canvas.drawRRect(
      rect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    _paintText(
      canvas,
      text,
      Offset(centerTop.dx, centerTop.dy + 2),
      width - 6,
      color,
      11,
      FontWeight.w800,
    );
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset centerTop,
    double maxWidth,
    Color color,
    double fontSize,
    FontWeight weight,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final scale = painter.width > maxWidth ? maxWidth / painter.width : 1.0;
    canvas.save();
    canvas.translate(centerTop.dx - painter.width * scale / 2, centerTop.dy);
    canvas.scale(scale, scale);
    painter.paint(canvas, Offset.zero);
    canvas.restore();
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant _SortingPinsPainter oldDelegate) =>
      oldDelegate.previous != previous ||
      oldDelegate.current != current ||
      oldDelegate.progress != progress ||
      oldDelegate.slotWidth != slotWidth ||
      oldDelegate.colors != colors ||
      oldDelegate.scaleValues != scaleValues ||
      oldDelegate.selectionStyle != selectionStyle ||
      oldDelegate.reduceMotion != reduceMotion;
}

class SortingPinGlyph {
  const SortingPinGlyph._();

  static void paint(
    Canvas canvas,
    Offset base,
    double width,
    double height,
    Color color,
    ColorScheme colors,
  ) {
    canvas.save();
    canvas.translate(base.dx - width / 2, base.dy - height);
    // Scale proportionally to preserve SVG aspect ratio (39.54 x 114.06)
    canvas.scale(width / 39.54, height / 114.06);

    // Exact vector silhouette from assets/icons/bowling.svg
    final topHead = Path()
      ..moveTo(12.42, 24.21)
      ..lineTo(27.36, 24.21)
      ..cubicTo(27.53, 17.13, 31.78, 9.3, 27.15, 3.34)
      ..cubicTo(24.11, -0.2, 18.05, -1.32, 14.39, 1.92)
      ..cubicTo(7.42, 7.99, 11.62, 16.59, 12.42, 24.21)
      ..close();

    final upperNeck = Path()
      ..moveTo(12.58, 36.15)
      ..lineTo(26.81, 36.15)
      ..cubicTo(26.67, 33.96, 26.72, 31.61, 26.88, 29.22)
      ..lineTo(12.66, 29.22)
      ..cubicTo(12.69, 31.74, 12.66, 34.13, 12.58, 36.15)
      ..close();

    final bodyBase = Path()
      ..moveTo(28.13, 42.78)
      ..lineTo(11.73, 42.78)
      ..cubicTo(2.81, 61.82, -9.37, 80.45, 11.51, 114.06)
      ..lineTo(28.48, 114.06)
      ..cubicTo(48.81, 78.18, 36.45, 60.61, 28.13, 42.78)
      ..close();

    final redStripe1 = Path()
      ..moveTo(12.42, 24.21)
      ..lineTo(12.66, 29.22)
      ..lineTo(26.88, 29.22)
      ..lineTo(27.36, 24.21)
      ..close();

    final redStripe2 = Path()
      ..moveTo(12.58, 36.15)
      ..lineTo(11.73, 42.78)
      ..lineTo(28.13, 42.78)
      ..lineTo(26.81, 36.15)
      ..close();

    final mainPaint = Paint()..color = const Color(0xFFFCFCFF);
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * 39.54 / width;

    canvas.drawPath(topHead, mainPaint);
    canvas.drawPath(topHead, strokePaint);
    canvas.drawPath(upperNeck, mainPaint);
    canvas.drawPath(upperNeck, strokePaint);
    canvas.drawPath(bodyBase, mainPaint);
    canvas.drawPath(bodyBase, strokePaint);

    final stripePaint = Paint()..color = SortingVisualTokens.stripe;

    canvas.drawPath(redStripe1, stripePaint);
    canvas.drawPath(redStripe2, stripePaint);

    canvas.restore();
  }
}
