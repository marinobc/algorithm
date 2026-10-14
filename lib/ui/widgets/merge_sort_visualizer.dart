import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/services/sorting_steps.dart';
import 'sorting_pin_visualizer.dart';
import 'sorting_visual_tokens.dart';

class MergeSortVisualizer extends StatefulWidget {
  final List<int> values;
  final SortingStep previous;
  final SortingStep current;
  final Animation<double> progress;
  final bool followPlayback;

  const MergeSortVisualizer({
    super.key,
    required this.values,
    required this.previous,
    required this.current,
    required this.progress,
    this.followPlayback = false,
  });

  @override
  State<MergeSortVisualizer> createState() => _MergeSortVisualizerState();
}

class _MergeSortVisualizerState extends State<MergeSortVisualizer> {
  final _scrollController = ScrollController();
  double _slotWidth = 58;
  double _viewportWidth = 0;

  @override
  void initState() {
    super.initState();
    widget.progress.addListener(_followMovement);
  }

  @override
  void didUpdateWidget(covariant MergeSortVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      oldWidget.progress.removeListener(_followMovement);
      widget.progress.addListener(_followMovement);
    }
    if (!identical(oldWidget.values, widget.values)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    } else if (widget.followPlayback &&
        (oldWidget.current != widget.current || !oldWidget.followPlayback)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _followActive());
    }
  }

  double _focusPosition(SortingStep step) {
    final state = step.mergeState!;
    final leftId = step.currentId;
    final rightId = step.comparingId;
    final leftIndex = leftId == null ? -1 : state.leftIds.indexOf(leftId);
    final rightIndex = rightId == null ? -1 : state.rightIds.indexOf(rightId);
    final leftPosition = leftIndex < 0 ? null : state.start + leftIndex;
    final rightPosition = rightIndex < 0 ? null : state.middle + rightIndex;

    if (step.phase == SortingPhase.mergeComparing &&
        leftPosition != null &&
        rightPosition != null) {
      final pairWidth = (rightPosition - leftPosition + 1) * _slotWidth;
      return pairWidth <= _viewportWidth * 0.75
          ? (leftPosition + rightPosition) / 2
          : rightPosition.toDouble();
    }
    if (step.phase == SortingPhase.mergeWriting &&
        state.selectedId != null &&
        state.outputIds.isNotEmpty) {
      final sourceIndex = state.leftIds.indexOf(state.selectedId!);
      final source = sourceIndex >= 0
          ? state.start + sourceIndex
          : state.middle + state.rightIds.indexOf(state.selectedId!);
      final target = state.start + state.outputIds.length - 1;
      return source + (target - source) * widget.progress.value;
    }
    if (step.phase == SortingPhase.mergeFocus) {
      return switch (state.stage) {
        SortingMergeStage.left => state.rootMiddle / 2 - 0.5,
        SortingMergeStage.right =>
          (state.rootMiddle + widget.values.length) / 2 - 0.5,
        _ => (widget.values.length - 1) / 2,
      };
    }
    if (state.stage == SortingMergeStage.result) return 0;
    return (state.start + state.end - 1) / 2;
  }

  void _followMovement() {
    if (widget.current.phase == SortingPhase.mergeWriting) _followActive();
  }

  void _followActive() {
    if (!mounted || !widget.followPlayback || !_scrollController.hasClients) {
      return;
    }
    if (widget.current.phase == SortingPhase.ready) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) return;
    final focusX = 16 + (_focusPosition(widget.current) + 0.5) * _slotWidth;
    if (focusX >= position.pixels + _viewportWidth * 0.25 &&
        focusX <= position.pixels + _viewportWidth * 0.75) {
      return;
    }
    final destination = (focusX - _viewportWidth / 2).clamp(
      0.0,
      position.maxScrollExtent,
    );
    if (MediaQuery.disableAnimationsOf(context) ||
        widget.current.phase == SortingPhase.mergeWriting) {
      _scrollController.jumpTo(destination);
    } else {
      _scrollController.animateTo(
        destination,
        duration: Duration(
          milliseconds: (widget.current.durationMs * 0.7).round().clamp(
            60,
            240,
          ),
        ),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    widget.progress.removeListener(_followMovement);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.current.mergeState!;
    final colors = Theme.of(context).colorScheme;
    const phases = [
      (SortingMergeStage.division, 'División'),
      (SortingMergeStage.left, 'Izquierda'),
      (SortingMergeStage.right, 'Derecha'),
      (SortingMergeStage.fusion, 'Fusión'),
      (SortingMergeStage.result, 'Resultado'),
    ];
    Widget phaseIndicator(int index) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(right: 5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: state.stage == phases[index].$1
                ? colors.primary
                : colors.outline,
          ),
        ),
        Text(
          phases[index].$2,
          style: TextStyle(
            fontSize: 12,
            fontWeight: state.stage == phases[index].$1
                ? FontWeight.w800
                : FontWeight.w500,
            color: state.stage == phases[index].$1
                ? colors.primary
                : colors.onSurfaceVariant,
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 520) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Wrap(
                  spacing: 14,
                  runSpacing: 7,
                  children: [
                    for (var index = 0; index < phases.length; index++)
                      phaseIndicator(index),
                  ],
                ),
              );
            }
            return SizedBox(
              height: 42,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    for (var index = 0; index < phases.length; index++) ...[
                      if (index > 0)
                        Container(
                          width: 18,
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          color: colors.outlineVariant,
                        ),
                      phaseIndicator(index),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        if (state.stage != SortingMergeStage.ready &&
            state.stage != SortingMergeStage.result)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Mitad izquierda',
                    style: _laneStyle(
                      colors,
                      state.stage == SortingMergeStage.left,
                      state.leftReady,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Mitad derecha',
                    textAlign: TextAlign.right,
                    style: _laneStyle(
                      colors,
                      state.stage == SortingMergeStage.right,
                      state.rightReady,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final count = math.max(widget.values.length, 1);
              final width = math.max(constraints.maxWidth, count * 58.0 + 32);
              _slotWidth = (width - 32) / count;
              _viewportWidth = constraints.maxWidth;
              final hasOverflow = width > constraints.maxWidth + 1;
              return Scrollbar(
                controller: _scrollController,
                thumbVisibility: hasOverflow,
                trackVisibility: hasOverflow,
                interactive: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: AnimatedBuilder(
                    animation: widget.progress,
                    builder: (context, _) => CustomPaint(
                      size: Size(width, constraints.maxHeight),
                      painter: _MergePainter(
                        values: widget.values,
                        previous: widget.previous,
                        current: widget.current,
                        progress: MediaQuery.disableAnimationsOf(context)
                            ? 1
                            : Curves.easeInOutCubic.transform(
                                widget.progress.value,
                              ),
                        slotWidth: _slotWidth,
                        colors: colors,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  TextStyle _laneStyle(ColorScheme colors, bool active, bool ready) =>
      TextStyle(
        fontSize: 12,
        fontWeight: active || ready ? FontWeight.w700 : FontWeight.w500,
        color: ready
            ? SortingVisualTokens.internallyOrdered
            : active
            ? colors.primary
            : colors.onSurfaceVariant,
      );
}

class _MergePainter extends CustomPainter {
  final List<int> values;
  final SortingStep previous;
  final SortingStep current;
  final double progress;
  final double slotWidth;
  final ColorScheme colors;
  late final int maxAbsolute = values.fold<int>(
    0,
    (maximum, value) => math.max(maximum, value.abs()),
  );
  late final int minPositive = values
      .map((value) => value.abs())
      .where((value) => value > 0)
      .fold<int>(maxAbsolute == 0 ? 1 : maxAbsolute, math.min);

  _MergePainter({
    required this.values,
    required this.previous,
    required this.current,
    required this.progress,
    required this.slotWidth,
    required this.colors,
  });

  SortingMergeState get state => current.mergeState!;
  SortingMergeState get before => previous.mergeState!;
  double x(int position) => 16 + (position + 0.5) * slotWidth;
  double mainX(int position) =>
      x(position) + (position < state.rootMiddle ? -8 : 8);

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final topY = switch (state.stage) {
      SortingMergeStage.division => h * 0.58,
      SortingMergeStage.fusion => h * 0.37,
      _ => h * 0.28,
    };
    final localY = h * 0.59;
    final outputY = state.stage == SortingMergeStage.fusion
        ? h * 0.84
        : h * 0.88;
    final rootPinHeight = switch (state.stage) {
      SortingMergeStage.division => h * 0.32,
      SortingMergeStage.fusion => h * 0.25,
      _ => h * 0.19,
    };
    final localPinHeight = h * 0.18;
    final moving =
        current.phase == SortingPhase.mergeWriting &&
        state.selectedId != null &&
        progress < 1;
    final baseLine = Paint()
      ..color = colors.outlineVariant
      ..strokeWidth = 1;

    if (state.stage == SortingMergeStage.ready) {
      _label(
        canvas,
        'Conjunto original',
        size.width / 2,
        h * 0.12,
        colors.onSurface,
        13,
        FontWeight.w700,
      );
      canvas.drawLine(
        Offset(12, h * 0.76),
        Offset(size.width - 12, h * 0.76),
        baseLine,
      );
      for (var i = 0; i < values.length; i++) {
        _pin(
          canvas,
          i,
          Offset(x(i), h * 0.76),
          h * 0.42,
          SortingVisualTokens.neutral,
        );
      }
      return;
    }

    if (state.stage == SortingMergeStage.result) {
      _label(
        canvas,
        'Conjunto ordenado',
        size.width / 2,
        h * 0.12,
        colors.onSurface,
        14,
        FontWeight.w800,
      );
      canvas.drawLine(
        Offset(12, h * 0.76),
        Offset(size.width - 12, h * 0.76),
        baseLine,
      );
      final ids = state.outputIds;
      for (var i = 0; i < ids.length; i++) {
        final from = Offset(x(i), outputY);
        final to = Offset(x(i), h * 0.76);
        _pin(
          canvas,
          ids[i],
          Offset.lerp(from, to, progress)!,
          h * 0.42,
          SortingVisualTokens.ordered,
        );
      }
      return;
    }

    final mainLeft = state.rootLeftIds;
    final mainRight = state.rootRightIds;
    final splitX = 16 + state.rootMiddle * slotWidth;
    canvas.drawLine(Offset(12, topY), Offset(size.width - 12, topY), baseLine);
    canvas.drawLine(
      Offset(splitX, h * 0.05),
      Offset(splitX, topY + 20),
      baseLine,
    );
    for (var i = 0; i < mainLeft.length; i++) {
      _mainPin(
        canvas,
        mainLeft[i],
        i,
        topY,
        rootPinHeight,
        isLeft: true,
        moving: moving,
      );
    }
    for (var i = 0; i < mainRight.length; i++) {
      _mainPin(
        canvas,
        mainRight[i],
        state.rootMiddle + i,
        topY,
        rootPinHeight,
        isLeft: false,
        moving: moving,
      );
    }
    if (state.stage == SortingMergeStage.division) {
      _label(
        canvas,
        'Dos mitades pendientes de ordenar',
        size.width / 2,
        h * 0.76,
        colors.onSurfaceVariant,
        13,
        FontWeight.w600,
      );
      return;
    }

    if (current.phase == SortingPhase.mergeFocus) {
      final caption = state.stage == SortingMergeStage.left
          ? 'Procesando la mitad izquierda'
          : state.stage == SortingMergeStage.right
          ? 'Procesando la mitad derecha'
          : 'Ambas mitades listas para fusionar';
      _label(
        canvas,
        caption,
        size.width / 2,
        h * 0.44,
        colors.onSurfaceVariant,
        13,
        FontWeight.w600,
      );
      return;
    }

    if (state.stage != SortingMergeStage.fusion) {
      _label(
        canvas,
        'Tramo ${state.start + 1}–${state.end}: submitades',
        size.width / 2,
        h * 0.39,
        colors.onSurface,
        12,
        FontWeight.w700,
      );
      canvas.drawLine(
        Offset(12, localY),
        Offset(size.width - 12, localY),
        baseLine,
      );
      canvas.drawLine(
        Offset(16 + state.middle * slotWidth, h * 0.44),
        Offset(16 + state.middle * slotWidth, localY + 14),
        baseLine,
      );
      for (var i = 0; i < state.leftIds.length; i++) {
        _sourcePin(
          canvas,
          state.leftIds[i],
          state.start + i,
          i < state.leftConsumed,
          localY,
          localPinHeight,
          moving,
        );
      }
      for (var i = 0; i < state.rightIds.length; i++) {
        _sourcePin(
          canvas,
          state.rightIds[i],
          state.middle + i,
          i < state.rightConsumed,
          localY,
          localPinHeight,
          moving,
        );
      }
    }

    final outputLabel = state.stage == SortingMergeStage.fusion
        ? 'Salida: fusión final'
        : 'Salida del tramo ${state.start + 1}–${state.end}';
    _label(
      canvas,
      outputLabel,
      size.width / 2,
      state.stage == SortingMergeStage.fusion ? h * 0.51 : h * 0.65,
      colors.onSurface,
      12,
      FontWeight.w700,
    );
    canvas.drawLine(
      Offset(12, outputY),
      Offset(size.width - 12, outputY),
      baseLine,
    );
    for (var i = 0; i < state.outputIds.length; i++) {
      final id = state.outputIds[i];
      if (moving && id == state.selectedId && i == state.outputIds.length - 1) {
        continue;
      }
      _pin(
        canvas,
        id,
        Offset(x(state.start + i), outputY),
        state.stage == SortingMergeStage.fusion ? h * 0.25 : localPinHeight,
        SortingVisualTokens.current,
      );
    }
    if (moving) {
      final id = state.selectedId!;
      final leftIndex = state.leftIds.indexOf(id);
      final sourcePosition = leftIndex >= 0
          ? state.start + leftIndex
          : state.middle + state.rightIds.indexOf(id);
      final sourceY = state.stage == SortingMergeStage.fusion ? topY : localY;
      final from = Offset(
        state.stage == SortingMergeStage.fusion
            ? mainX(sourcePosition)
            : x(sourcePosition),
        sourceY,
      );
      final to = Offset(x(state.start + state.outputIds.length - 1), outputY);
      _pin(
        canvas,
        id,
        Offset.lerp(from, to, progress)!,
        state.stage == SortingMergeStage.fusion ? h * 0.25 : localPinHeight,
        SortingVisualTokens.current,
      );
    }
  }

  void _mainPin(
    Canvas canvas,
    int id,
    int position,
    double y,
    double height, {
    required bool isLeft,
    required bool moving,
  }) {
    final sameTop =
        before.stage != SortingMergeStage.ready &&
        before.stage != SortingMergeStage.result;
    final oldIds = isLeft ? before.rootLeftIds : before.rootRightIds;
    final oldIndex = oldIds.indexOf(id);
    final oldPosition = oldIndex < 0
        ? position
        : oldIndex + (isLeft ? 0 : state.rootMiddle);
    final canvasHeight =
        y /
        (state.stage == SortingMergeStage.division
            ? 0.58
            : state.stage == SortingMergeStage.fusion
            ? 0.37
            : 0.28);
    final fromY =
        canvasHeight *
        switch (before.stage) {
          SortingMergeStage.ready => 0.76,
          SortingMergeStage.division => 0.58,
          SortingMergeStage.fusion => 0.37,
          _ => 0.28,
        };
    final from = sameTop
        ? Offset(mainX(oldPosition), fromY)
        : Offset(x(position), fromY);
    final to = Offset(mainX(position), y);
    final consumed =
        state.stage == SortingMergeStage.fusion &&
        (isLeft
            ? state.leftIds.indexOf(id) < state.leftConsumed
            : state.rightIds.indexOf(id) < state.rightConsumed);
    if (moving && id == state.selectedId) return;
    final active = isLeft
        ? state.stage == SortingMergeStage.left
        : state.stage == SortingMergeStage.right;
    final completed = isLeft ? state.leftReady : state.rightReady;
    final comparing =
        state.stage == SortingMergeStage.fusion &&
        current.phase == SortingPhase.mergeComparing &&
        (current.currentId == id || current.comparingId == id);
    final color = comparing
        ? SortingVisualTokens.compared
        : completed
        ? SortingVisualTokens.internallyOrdered
        : active
        ? SortingVisualTokens.current
        : SortingVisualTokens.neutral;
    _pin(
      canvas,
      id,
      Offset.lerp(from, to, progress)!,
      height,
      color,
      opacity: consumed ? 0.5 : 1,
    );
    if (comparing) {
      _label(
        canvas,
        isLeft ? 'A' : 'B',
        to.dx,
        y - height - 15,
        SortingVisualTokens.compared,
        11,
        FontWeight.w800,
      );
    }
  }

  void _sourcePin(
    Canvas canvas,
    int id,
    int position,
    bool consumed,
    double y,
    double height,
    bool moving,
  ) {
    if (moving && id == state.selectedId) return;
    final comparing =
        current.phase == SortingPhase.mergeComparing &&
        (current.currentId == id || current.comparingId == id);
    _pin(
      canvas,
      id,
      Offset(x(position), y),
      height,
      comparing ? SortingVisualTokens.compared : SortingVisualTokens.neutral,
      opacity: consumed ? 0.5 : 1,
    );
    if (comparing) {
      _label(
        canvas,
        id == current.currentId ? 'A' : 'B',
        x(position),
        y - height - 15,
        SortingVisualTokens.compared,
        11,
        FontWeight.w800,
      );
    }
  }

  void _pin(
    Canvas canvas,
    int id,
    Offset base,
    double maxHeight,
    Color color, {
    double opacity = 1,
  }) {
    if (id < 0 || id >= values.length) return;
    final height =
        math.min(maxHeight, (slotWidth - 12) / SortingVisualTokens.pinAspect) *
        SortingVisualTokens.relativeHeight(
          values[id],
          maxAbsolute,
          minPositive,
        );
    final width = height * SortingVisualTokens.pinAspect;
    if (opacity < 1) {
      canvas.saveLayer(
        null,
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
    }
    SortingPinGlyph.paint(canvas, base, width, height, color, colors);
    _label(
      canvas,
      values[id].toString(),
      base.dx,
      base.dy + 8,
      colors.onSurface,
      12,
      FontWeight.w700,
      maxWidth: slotWidth - 4,
    );
    if (opacity < 1) canvas.restore();
  }

  void _label(
    Canvas canvas,
    String text,
    double xPos,
    double yPos,
    Color color,
    double size,
    FontWeight weight, {
    double? maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final allowed =
        maxWidth ?? math.max(60, canvas.getDestinationClipBounds().width - 24);
    final scale = painter.width > allowed ? allowed / painter.width : 1.0;
    canvas.save();
    canvas.translate(xPos - painter.width * scale / 2, yPos);
    canvas.scale(scale, scale);
    painter.paint(canvas, Offset.zero);
    canvas.restore();
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant _MergePainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.previous != previous ||
      oldDelegate.current != current ||
      oldDelegate.progress != progress ||
      oldDelegate.slotWidth != slotWidth ||
      oldDelegate.colors != colors;
}
