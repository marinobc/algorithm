import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/services/sorting_steps.dart';

class SortingPinVisualizer extends StatefulWidget {
  final List<int> values;
  final SortingStep previous;
  final SortingStep current;
  final Animation<double> progress;
  final bool followPlayback;

  const SortingPinVisualizer({
    super.key,
    required this.values,
    required this.previous,
    required this.current,
    required this.progress,
    this.followPlayback = false,
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
    _scrollController.animateTo(
      destination,
      duration: duration,
      curve: Curves.easeInOut,
    );
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
          25.0,
          82.0,
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
                  previous: widget.previous,
                  current: widget.current,
                  progress: widget.progress.value,
                  slotWidth: _slotWidth,
                  colors: colors,
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
  final SortingStep previous;
  final SortingStep current;
  final double progress;
  final double slotWidth;
  final ColorScheme colors;

  const _SortingPinsPainter({
    required this.values,
    required this.previous,
    required this.current,
    required this.progress,
    required this.slotWidth,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final baseY = size.height - 38;
    final maxAbsolute = values.fold<int>(
      0,
      (maxValue, value) => math.max(maxValue, value.abs()),
    );
    final positive = values.map((value) => value.abs()).where((v) => v > 0);
    final minPositive = positive.isEmpty ? 1 : positive.reduce(math.min);
    final useLog = maxAbsolute > minPositive * 20;

    // Apply Flutter Animation skill: Curves.easeInOutCubic for smooth physics translation
    final curvedProgress = Curves.easeInOutCubic.transform(progress);

    final baselinePaint = Paint()
      ..color = colors.outlineVariant
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, baseY), Offset(size.width, baseY), baselinePaint);
    if (current.sortedCount > 0) {
      final prevSorted = previous.sortedCount.toDouble();
      final currSorted = current.sortedCount.toDouble();
      final animSorted =
          prevSorted + (currSorted - prevSorted) * curvedProgress;
      canvas.drawLine(
        Offset(0, baseY + 3),
        Offset(animSorted * slotWidth, baseY + 3),
        Paint()
          ..color = colors.secondary
          ..strokeWidth = 3,
      );
    }

    for (var id = 0; id < values.length; id++) {
      final previousX = (previous.slots[id] + 0.5) * slotWidth;
      final currentX = (current.slots[id] + 0.5) * slotWidth;
      // Physics-driven spatial interpolation
      final x = previousX + (currentX - previousX) * curvedProgress;

      final wasRaised = previous.keyId == id && previous.keyRaised;
      final isRaised = current.keyId == id && current.keyRaised;
      final liftProgress =
          (wasRaised ? 1.0 : 0.0) +
          ((isRaised ? 1.0 : 0.0) - (wasRaised ? 1.0 : 0.0)) * curvedProgress;

      // Calculate parabolic arc lift (up-and-over motion) when a pin changes horizontal slot position
      final deltaSlots = (current.slots[id] - previous.slots[id]).abs();
      final arcHeight = deltaSlots > 0
          ? math.sin(curvedProgress * math.pi) *
                math.min(42.0, deltaSlots * 22.0)
          : 0.0;

      final totalLift = (liftProgress * 28) + arcHeight;

      final ratio = maxAbsolute == 0
          ? 0.0
          : useLog
          ? math.log(1 + values[id].abs()) / math.log(1 + maxAbsolute)
          : values[id].abs() / maxAbsolute;

      // Scale height and width proportionally according to bowling.svg aspect ratio (39.54 / 114.06)
      final maxAvailableHeight = math.min(size.height - 106, slotWidth * 2.88);
      final pinHeight = maxAvailableHeight * (0.35 + 0.65 * ratio);
      final pinWidth = pinHeight * (39.54 / 114.06);

      // Smooth color morphing between previous and current step states using Color.lerp
      final prevColor = _colorForStep(id, previous);
      final currColor = _colorForStep(id, current);
      final color =
          Color.lerp(prevColor, currColor, curvedProgress) ?? currColor;

      _paintPin(
        canvas,
        Offset(x, baseY - totalLift),
        pinWidth,
        pinHeight,
        color,
      );

      _paintText(
        canvas,
        values[id].toString(),
        Offset(x, baseY + 11),
        slotWidth - 3,
        colors.onSurface,
        math.min(12, slotWidth * 0.38),
        FontWeight.w600,
      );
      final marker = _markerFor(id);
      if (marker.isNotEmpty) {
        _paintText(
          canvas,
          marker,
          Offset(x, math.max(4, baseY - pinHeight - totalLift - 17)),
          slotWidth - 2,
          color,
          math.min(11, slotWidth * 0.34),
          FontWeight.w800,
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

    final mainPaint = Paint()..color = color;
    final strokePaint = Paint()
      ..color = colors.onSurface.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(topHead, mainPaint);
    canvas.drawPath(topHead, strokePaint);
    canvas.drawPath(upperNeck, mainPaint);
    canvas.drawPath(upperNeck, strokePaint);
    canvas.drawPath(bodyBase, mainPaint);
    canvas.drawPath(bodyBase, strokePaint);

    final stripeColor = color == colors.error
        ? colors.onError.withValues(alpha: 0.9)
        : colors.error.withValues(alpha: 0.9);
    final stripePaint = Paint()..color = stripeColor;

    canvas.drawPath(redStripe1, stripePaint);
    canvas.drawPath(redStripe2, stripePaint);

    canvas.restore();
  }

  Color _colorForStep(int id, SortingStep step) {
    if (step.keyId == id) return colors.tertiary;
    if (step.comparingId == id) return colors.error;
    if (step.minimumId == id) return colors.primary;
    if (step.currentId == id) return colors.primary;
    if (step.slots[id] < step.sortedCount) return colors.secondary;
    return const Color(0xFFF8F7FB);
  }

  String _markerFor(int id) {
    final markers = <String>[];
    if (current.currentId == id) markers.add('i');
    if (current.comparingId == id) markers.add('j');
    if (current.minimumId == id) markers.add('MIN');
    if (current.keyId == id) markers.add('KEY');
    return markers.join(' ');
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
      oldDelegate.colors != colors;
}
