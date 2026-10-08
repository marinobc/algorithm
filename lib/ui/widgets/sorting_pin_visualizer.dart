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
    final pinWidth = (slotWidth * 0.58).clamp(12.0, 48.0);
    final maxPinHeight = math.min(size.height - 106, pinWidth * 4.2);
    final maxAbsolute = values.fold<int>(
      0,
      (maxValue, value) => math.max(maxValue, value.abs()),
    );
    final positive = values.map((value) => value.abs()).where((v) => v > 0);
    final minPositive = positive.isEmpty ? 1 : positive.reduce(math.min);
    final useLog = maxAbsolute > minPositive * 20;

    final baselinePaint = Paint()
      ..color = colors.outlineVariant
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, baseY), Offset(size.width, baseY), baselinePaint);
    if (current.sortedCount > 0) {
      canvas.drawLine(
        Offset(0, baseY + 3),
        Offset(current.sortedCount * slotWidth, baseY + 3),
        Paint()
          ..color = colors.secondary
          ..strokeWidth = 3,
      );
    }

    for (var id = 0; id < values.length; id++) {
      final previousX = (previous.slots[id] + 0.5) * slotWidth;
      final currentX = (current.slots[id] + 0.5) * slotWidth;
      final x = previousX + (currentX - previousX) * progress;
      final wasRaised = previous.keyId == id && previous.keyRaised;
      final isRaised = current.keyId == id && current.keyRaised;
      final lift =
          ((wasRaised ? 1.0 : 0.0) +
              ((isRaised ? 1.0 : 0.0) - (wasRaised ? 1.0 : 0.0)) * progress) *
          28;
      final ratio = maxAbsolute == 0
          ? 0.0
          : useLog
          ? math.log(1 + values[id].abs()) / math.log(1 + maxAbsolute)
          : values[id].abs() / maxAbsolute;
      final pinHeight = maxPinHeight * (0.3 + 0.7 * ratio);
      final color = _colorFor(id);
      _paintPin(canvas, Offset(x, baseY - lift), pinWidth, pinHeight, color);

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
          Offset(x, math.max(4, baseY - pinHeight - lift - 17)),
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
    canvas.scale(width, height);
    final silhouette = Path()
      ..moveTo(0.5, 0)
      ..cubicTo(0.31, 0, 0.28, 0.12, 0.31, 0.19)
      ..cubicTo(0.34, 0.28, 0.43, 0.33, 0.37, 0.4)
      ..cubicTo(0.31, 0.49, 0.17, 0.57, 0.15, 0.81)
      ..quadraticBezierTo(0.13, 0.94, 0.17, 1)
      ..lineTo(0.83, 1)
      ..quadraticBezierTo(0.87, 0.94, 0.85, 0.81)
      ..cubicTo(0.83, 0.57, 0.69, 0.49, 0.63, 0.4)
      ..cubicTo(0.57, 0.33, 0.66, 0.28, 0.69, 0.19)
      ..cubicTo(0.72, 0.12, 0.69, 0, 0.5, 0)
      ..close();
    canvas.drawPath(silhouette, Paint()..color = color);
    canvas.drawPath(
      silhouette,
      Paint()
        ..color = colors.onSurface.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.025,
    );
    final stripeColor = color == colors.error
        ? colors.onError.withValues(alpha: 0.85)
        : colors.error.withValues(alpha: 0.85);
    for (final y in [0.27, 0.32]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.36, y, 0.28, 0.025),
          const Radius.circular(0.01),
        ),
        Paint()..color = stripeColor,
      );
    }
    canvas.restore();
  }

  Color _colorFor(int id) {
    if (current.keyId == id) return colors.tertiary;
    if (current.comparingId == id) return colors.error;
    if (current.minimumId == id) return colors.primary;
    if (current.currentId == id) return colors.primary;
    if (current.slots[id] < current.sortedCount) return colors.secondary;
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
