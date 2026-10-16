import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/services/sorting_steps.dart';
import 'sorting_visual_tokens.dart';

double _shellTravel(double progress) =>
    Curves.easeInOut.transform(((progress - 0.2) / 0.6).clamp(0.0, 1.0));

double _shellLift(double progress) {
  if (progress < 0.2) {
    return Curves.easeInOut.transform(progress / 0.2);
  }
  if (progress > 0.8) {
    return Curves.easeInOut.transform((1 - progress) / 0.2);
  }
  return 1;
}

class SortingPinVisualizer extends StatefulWidget {
  final List<int> values;
  final SortingStep previous;
  final SortingStep current;
  final Animation<double> progress;
  final bool followPlayback;
  final bool selectionStyle;
  final bool shellStyle;
  final List<int>? scaleValues;

  const SortingPinVisualizer({
    super.key,
    required this.values,
    required this.previous,
    required this.current,
    required this.progress,
    this.followPlayback = false,
    this.selectionStyle = false,
    this.shellStyle = false,
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
  void initState() {
    super.initState();
    widget.progress.addListener(_followShellMovement);
  }

  @override
  void didUpdateWidget(covariant SortingPinVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      oldWidget.progress.removeListener(_followShellMovement);
      widget.progress.addListener(_followShellMovement);
    }
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

  void _followShellMovement() {
    if (widget.shellStyle && widget.current.phase == SortingPhase.swapping) {
      _followCurrent();
    }
  }

  void _followCurrent() {
    if (!mounted || !widget.followPlayback || !_scrollController.hasClients) {
      return;
    }
    final step = widget.current;
    if (step.gap != null &&
        (step.phase == SortingPhase.gap || step.phase == SortingPhase.sorted)) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
        );
      }
      return;
    }
    final id = switch (step.phase) {
      SortingPhase.comparing ||
      SortingPhase.swapping ||
      SortingPhase.current when step.gap != null => step.currentId,
      SortingPhase.comparing || SortingPhase.shifting => step.comparingId,
      SortingPhase.minimum || SortingPhase.swapping => step.minimumId,
      SortingPhase.key || SortingPhase.inserting => step.keyId,
      SortingPhase.current => step.currentId,
      _ => null,
    };
    var slot = id != null
        ? step.slots[id]
        : step.sortedCount > 0
        ? (step.sortedCount - 1).toDouble()
        : null;
    if (step.gap != null && step.comparingId != null && slot != null) {
      final other = step.slots[step.comparingId!];
      if ((slot - other).abs() * _slotWidth <= _viewportWidth * 0.75) {
        slot = (slot + other) / 2;
      } else if (step.phase == SortingPhase.swapping && id != null) {
        final from = widget.previous.slots[id];
        final progress = MediaQuery.disableAnimationsOf(context)
            ? 1.0
            : Curves.easeInOutCubic.transform(widget.progress.value);
        slot = from + (slot - from) * _shellTravel(progress);
      }
    }
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
    if (MediaQuery.disableAnimationsOf(context) ||
        (widget.shellStyle && step.phase == SortingPhase.swapping)) {
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
    widget.progress.removeListener(_followShellMovement);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final slotWidth = (constraints.maxWidth / widget.values.length).clamp(
          SortingVisualTokens.compactSlotWidth,
          112.0,
        );
        final contentWidth = math.max(
          constraints.maxWidth,
          slotWidth * widget.values.length,
        );
        _viewportWidth = constraints.maxWidth;
        _slotWidth = contentWidth / widget.values.length;
        final hasOverflow = contentWidth > constraints.maxWidth + 1;
        return Stack(
          children: [
            Scrollbar(
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
                      viewportWidth: _viewportWidth,
                      colors: colors,
                      selectionStyle: widget.selectionStyle,
                      shellStyle: widget.shellStyle,
                      reduceMotion: MediaQuery.disableAnimationsOf(context),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.current.gap != null) _shellStatus(colors),
          ],
        );
      },
    );
  }

  Widget _shellStatus(ColorScheme colors) {
    final step = widget.current;
    final gap = step.gap!;
    final rightId = step.currentId;
    final leftId = step.comparingId;
    final hasPair = rightId != null && leftId != null;
    final rightPosition = hasPair
        ? step.slots[step.phase == SortingPhase.swapping ? leftId : rightId]
                  .round() +
              1
        : 0;
    final leftPosition = hasPair
        ? step.slots[step.phase == SortingPhase.swapping ? rightId : leftId]
                  .round() +
              1
        : 0;
    final group = hasPair ? (rightPosition - 1) % gap + 1 : 0;
    final pairs = math.min(gap, widget.values.length - gap);
    final singles = gap - pairs;
    final phase = switch (step.phase) {
      SortingPhase.gap => 'Inicio de pasada',
      SortingPhase.swapping => 'Intercambio real',
      SortingPhase.current => 'Sin intercambio',
      SortingPhase.sorted when gap == 1 => 'Ordenado',
      SortingPhase.sorted => 'Pasada completa',
      _ => 'Comparando',
    };
    final summary = switch (step.phase) {
      SortingPhase.gap when widget.values.length <= 2 * gap =>
        '$gap subsecuencias intercaladas: $pairs pares y $singles individuales.',
      SortingPhase.gap =>
        '$gap subsecuencias; cada grupo reúne posiciones separadas por $gap.',
      SortingPhase.sorted when gap == 1 =>
        'La única subsecuencia y el arreglo completo están ordenados.',
      SortingPhase.sorted =>
        'Las $gap subsecuencias están h-ordenadas; el arreglo completo aún no.',
      SortingPhase.swapping =>
        '${widget.values[rightId!]} va a la posición $leftPosition; ${widget.values[leftId!]} va a la $rightPosition.',
      SortingPhase.current =>
        'Permanecen en sus posiciones: no hubo intercambio.',
      _ => 'Se comparan a distancia $gap; aún no se conoce el resultado.',
    };
    final phaseColor = switch (step.phase) {
      SortingPhase.swapping => SortingVisualTokens.current,
      SortingPhase.current ||
      SortingPhase.sorted => SortingVisualTokens.ordered,
      _ => colors.primary,
    };
    return Positioned(
      top: 8,
      left: 12,
      right: 12,
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 690),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerLowest,
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.22),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'PASADA  h = $gap',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          phase,
                          style: TextStyle(
                            color: phaseColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (hasPair)
                          Text(
                            'Subsecuencia $group de $gap',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (hasPair)
                      Wrap(
                        spacing: 12,
                        runSpacing: 2,
                        children: [
                          Text(
                            'j-h · pos. $leftPosition · ${widget.values[leftId]}',
                            style: TextStyle(
                              color: SortingVisualTokens.compared,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'distancia $gap',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            'j · pos. $rightPosition · ${widget.values[rightId]}',
                            style: TextStyle(
                              color: SortingVisualTokens.current,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    if (hasPair) const SizedBox(height: 2),
                    Text(
                      summary,
                      softWrap: true,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
  final double viewportWidth;
  final ColorScheme colors;
  final bool selectionStyle;
  final bool shellStyle;
  final bool reduceMotion;

  const _SortingPinsPainter({
    required this.values,
    required this.scaleValues,
    required this.previous,
    required this.current,
    required this.progress,
    required this.slotWidth,
    required this.viewportWidth,
    required this.colors,
    required this.selectionStyle,
    required this.shellStyle,
    required this.reduceMotion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shellGap = current.gap;
    final baseY = shellStyle
        ? math.min(size.height * 0.68, size.height - 70)
        : size.height * 0.79;
    final keyY = size.height * 0.22;
    final maxHeight = math.min(
      size.height * (shellStyle ? 0.32 : 0.42),
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

    if (shellGap != null) {
      _paintShellGuides(canvas, size, baseY, shellGap, curvedProgress);
    }

    for (var id = 0; id < values.length; id++) {
      final previousX = (previous.slots[id] + 0.5) * slotWidth;
      final currentX = (current.slots[id] + 0.5) * slotWidth;
      final x = _animatedX(id, curvedProgress);

      final wasRaised = previous.keyId == id && previous.keyRaised;
      final isRaised = current.keyId == id && current.keyRaised;
      final raisedProgress =
          (wasRaised ? 1.0 : 0.0) +
          ((isRaised ? 1.0 : 0.0) - (wasRaised ? 1.0 : 0.0)) * curvedProgress;
      final fullHeight =
          maxHeight *
          (shellStyle
              ? _shellRelativeHeight(values[id], maxAbsolute, minPositive)
              : SortingVisualTokens.relativeHeight(
                  values[id],
                  maxAbsolute,
                  minPositive,
                ));
      final compactHeight = math.min(fullHeight * 0.55, size.height * 0.15);
      final rawPinHeight =
          fullHeight + (compactHeight - fullHeight) * raisedProgress;
      final swapping =
          current.phase == SortingPhase.swapping &&
          previous.slots[id] != current.slots[id];
      final shellLift = shellStyle && swapping
          ? _shellLift(curvedProgress)
          : 0.0;
      final peakScale = maxHeight <= 0
          ? 0.62
          : ((baseY - maxHeight - 64) / maxHeight).clamp(0.35, 0.62);
      final pinHeight = rawPinHeight * (1 - (1 - peakScale) * shellLift);
      final pinWidth = pinHeight * SortingVisualTokens.pinAspect;
      final pinBaseY = baseY + (keyY - baseY) * raisedProgress;
      final swapLift = shellStyle
          ? shellLift * (maxHeight + 8)
          : swapping && currentX < previousX
          ? math.sin(curvedProgress * math.pi) *
                math.min(40.0, size.height * 0.1)
          : 0.0;
      final prevColor = _colorForStep(id, previous);
      final currColor = _colorForStep(id, current);
      final color = shellGap == null
          ? Color.lerp(prevColor, currColor, curvedProgress) ?? currColor
          : Color.lerp(
                  _shellColor(id, previous, shellGap),
                  _shellColor(id, current, shellGap),
                  curvedProgress,
                ) ??
                currColor;

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
              shellStyle ? 54 : 3,
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

  double _animatedX(int id, double curvedProgress) {
    final from = (previous.slots[id] + 0.5) * slotWidth;
    final to = (current.slots[id] + 0.5) * slotWidth;
    final crossing =
        shellStyle && current.phase == SortingPhase.swapping && from != to;
    final travel = crossing ? _shellTravel(curvedProgress) : curvedProgress;
    final lane = crossing
        ? (to < from ? -1 : 1) *
              math.sin(travel * math.pi) *
              math.min(slotWidth * 0.28, 24.0)
        : 0.0;
    return from + (to - from) * travel + lane;
  }

  double _shellRelativeHeight(int value, int maximum, int minimumPositive) {
    if (maximum == 0) return 0.38;
    final magnitude = value.abs();
    final ratio = maximum > minimumPositive * 20
        ? math.log(1 + magnitude) / math.log(1 + maximum)
        : magnitude / maximum;
    return 0.38 + 0.62 * math.sqrt(ratio);
  }

  void _paintShellGuides(
    Canvas canvas,
    Size size,
    double baseY,
    int gap,
    double curvedProgress,
  ) {
    final activeGroup = _activeShellGroup(gap);
    final isCompletePass = current.phase == SortingPhase.sorted;
    final isPassStart = current.phase == SortingPhase.gap;
    for (var position = 0; position < values.length; position++) {
      final group = position % gap;
      final active = activeGroup != null && group == activeGroup;
      final groupColor = isCompletePass && gap == 1
          ? SortingVisualTokens.ordered
          : active
          ? SortingVisualTokens.current
          : colors.outlineVariant;
      final x = (position + 0.5) * slotWidth;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, baseY + 35),
            width: math.min(slotWidth * (active ? 0.58 : 0.34), 22),
            height: active ? 4 : 2,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = groupColor,
      );
      _paintText(
        canvas,
        '${position + 1}',
        Offset(x, baseY + 24),
        slotWidth - 4,
        colors.onSurfaceVariant,
        10,
        FontWeight.w600,
      );
    }

    if (isPassStart) {
      if (gap * slotWidth <= viewportWidth * 0.75) {
        final relationCount = math.min(4, math.min(gap, values.length - gap));
        for (var group = 0; group < relationCount; group++) {
          _shellRelation(
            canvas,
            (group + 0.5) * slotWidth,
            (group + gap + 0.5) * slotWidth,
            baseY + 45 + group * 3,
            colors.primary,
            opacity: curvedProgress * 0.42,
          );
        }
      }
      return;
    }

    if (isCompletePass) return;

    final rightId = current.currentId;
    final leftId = current.comparingId;
    if (rightId == null || leftId == null) return;
    final rightX = _animatedX(rightId, curvedProgress);
    final leftX = _animatedX(leftId, curvedProgress);
    final color = switch (current.phase) {
      SortingPhase.swapping => SortingVisualTokens.current,
      SortingPhase.current => SortingVisualTokens.ordered,
      _ => SortingVisualTokens.compared,
    };
    _shellRelation(
      canvas,
      rightX,
      leftX,
      baseY + 45,
      color,
      drawLine: (rightX - leftX).abs() <= viewportWidth * 0.85,
    );
  }

  void _shellRelation(
    Canvas canvas,
    double fromX,
    double toX,
    double y,
    Color color, {
    double opacity = 1,
    bool drawLine = true,
  }) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = 1.6;
    if (drawLine) {
      canvas.drawLine(Offset(fromX, y), Offset(toX, y), paint);
    }
    canvas.drawCircle(Offset(fromX, y), 3, paint);
    canvas.drawCircle(Offset(toX, y), 3, paint);
  }

  int? _activeShellGroup(int gap) {
    final id = current.currentId;
    if (id == null || current.comparingId == null) return null;
    return current.slots[id].round() % gap;
  }

  bool _isInactiveShellGroup(int id, int gap) {
    final activeGroup = _activeShellGroup(gap);
    return activeGroup != null &&
        current.slots[id].round() % gap != activeGroup;
  }

  Color _shellColor(int id, SortingStep step, int gap) {
    if (step.gap == null) return SortingVisualTokens.neutral;
    if (step.phase == SortingPhase.sorted && gap == 1) {
      return SortingVisualTokens.ordered;
    }
    if (step.currentId == id) return SortingVisualTokens.current;
    if (step.comparingId == id) return SortingVisualTokens.compared;
    if (!_isInactiveShellGroup(id, gap) && _activeShellGroup(gap) != null) {
      return Color.lerp(
        SortingVisualTokens.neutral,
        SortingVisualTokens.current,
        0.48,
      )!;
    }
    return SortingVisualTokens.neutral;
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
    if (current.gap != null) {
      if (current.currentId == id) {
        markers.add(('j', SortingVisualTokens.current));
      }
      if (current.comparingId == id) {
        markers.add(('j-h', SortingVisualTokens.compared));
      }
      return markers;
    }
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
      oldDelegate.viewportWidth != viewportWidth ||
      oldDelegate.colors != colors ||
      oldDelegate.scaleValues != scaleValues ||
      oldDelegate.selectionStyle != selectionStyle ||
      oldDelegate.shellStyle != shellStyle ||
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
