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
  double _slotWidth = SortingVisualTokens.compactSlotWidth;
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
        if (state.stage != SortingMergeStage.ready &&
            state.stage != SortingMergeStage.result)
          LayoutBuilder(
            builder: (context, constraints) => Padding(
              padding: const EdgeInsets.fromLTRB(12, 1, 12, 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 34,
                    child: Text(
                      switch (widget.current.phase) {
                        SortingPhase.mergeCopying =>
                          'Copiando posiciones ${state.start + 1}–${state.end} a aux[]',
                        SortingPhase.mergeComparing =>
                          'Comparando ${widget.values[widget.current.currentId!]} con ${widget.values[widget.current.comparingId!]}',
                        SortingPhase.mergeWriting =>
                          'Escribiendo ${widget.values[state.selectedId!]} en a[${state.k! + 1}]',
                        SortingPhase.merged =>
                          'Posiciones ${state.start + 1}–${state.end} ordenadas internamente',
                        _ =>
                          'Procesando posiciones ${state.start + 1}–${state.end}',
                      },
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    height: constraints.maxWidth < 540 ? 48 : 30,
                    child: Wrap(
                      spacing: 11,
                      runSpacing: 2,
                      children: [
                        Text(
                          'lo ${state.start + 1} · mid ${state.middle} · hi ${state.end}',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        if (state.i != null)
                          Text(
                            state.i! < state.middle
                                ? 'i ${state.i! + 1} · izquierda'
                                : 'i · agotada',
                            style: const TextStyle(
                              color: SortingVisualTokens.current,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (state.j != null)
                          Text(
                            state.j! < state.end
                                ? 'j ${state.j! + 1} · derecha'
                                : 'j · agotada',
                            style: const TextStyle(
                              color: SortingVisualTokens.compared,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (state.k != null && state.k! < state.end)
                          Text(
                            'k ${state.k! + 1} · destino',
                            style: const TextStyle(
                              color: SortingVisualTokens.minimum,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible:
                        widget.current.phase == SortingPhase.mergeComparing ||
                        widget.current.phase == SortingPhase.mergeWriting,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: Text(
                      'En a[], las posiciones pendientes conservan su valor anterior.',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final count = math.max(widget.values.length, 1);
              final width = math.max(
                constraints.maxWidth,
                count * SortingVisualTokens.compactSlotWidth + 32,
              );
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
                        bottomInset: hasOverflow ? 46 : 20,
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
  final double bottomInset;
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
    required this.bottomInset,
  });

  SortingMergeState get state => current.mergeState!;
  SortingMergeState get before => previous.mergeState!;
  double x(int position) => 16 + (position + 0.5) * slotWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final h = math.max(0.0, size.height - bottomInset);
    final topY = h * 0.22;
    final localY = h * 0.55;
    final outputY = h * 0.89;
    final contextPinHeight = h * 0.11;
    final localPinHeight = h * 0.11;
    final outputPinHeight = h * 0.11;
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
          h * 0.45,
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
          h * 0.45,
          SortingVisualTokens.ordered,
        );
      }
      return;
    }

    _label(
      canvas,
      'a[] · arreglo principal / contexto',
      size.width / 2,
      h * 0.025,
      colors.onSurface,
      12,
      FontWeight.w700,
    );
    final activeStart = state.start;
    final activeEnd = state.end;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          16 + activeStart * slotWidth,
          h * 0.10,
          16 + activeEnd * slotWidth,
          topY + 14,
        ),
        const Radius.circular(4),
      ),
      Paint()
        ..color = colors.primary.withValues(alpha: 0.34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawLine(Offset(12, topY), Offset(size.width - 12, topY), baseLine);
    final visibleArray = moving ? before.arrayIds : state.arrayIds;
    for (var position = 0; position < visibleArray.length; position++) {
      _pin(
        canvas,
        visibleArray[position],
        Offset(x(position), topY),
        contextPinHeight,
        position >= activeStart && position < activeEnd
            ? SortingVisualTokens.current
            : SortingVisualTokens.neutral,
        opacity: position >= activeStart && position < activeEnd ? 1 : 0.65,
      );
    }
    final splitX = 16 + state.middle * slotWidth;
    canvas.drawLine(
      Offset(splitX, h * 0.10),
      Offset(splitX, topY + 12),
      Paint()..color = colors.primary.withValues(alpha: 0.28),
    );
    if (state.stage == SortingMergeStage.division) {
      _label(
        canvas,
        'Mitades separadas: izquierda y derecha aún pendientes',
        size.width / 2,
        h * 0.65,
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
        h * 0.63,
        colors.onSurfaceVariant,
        13,
        FontWeight.w600,
      );
      return;
    }

    _label(
      canvas,
      current.phase == SortingPhase.splitting
          ? 'a[] · submitades del tramo ${state.start + 1}–${state.end}'
          : 'aux[] · copia temporal para fusionar',
      size.width / 2,
      h * 0.34,
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
      Offset(splitX, h * 0.38),
      Offset(splitX, localY + 14),
      Paint()..color = colors.primary.withValues(alpha: 0.28),
    );
    for (var i = 0; i < state.leftIds.length; i++) {
      _sourcePin(
        canvas,
        state.leftIds[i],
        state.start + i,
        i < state.leftConsumed,
        localY,
        localPinHeight,
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
      );
    }
    if (current.phase == SortingPhase.splitting) return;

    final completedWrites = state.outputIds.length - (moving ? 1 : 0);
    final outputLabel =
        'a[] · tramo ampliado ${state.start + 1}–${state.end} · $completedWrites de ${state.end - state.start} escrituras visibles';
    _label(
      canvas,
      outputLabel,
      size.width / 2,
      h * 0.68,
      colors.onSurface,
      12,
      FontWeight.w700,
    );
    canvas.drawLine(
      Offset(12, outputY),
      Offset(size.width - 12, outputY),
      baseLine,
    );
    for (var i = state.start; i < state.end; i++) {
      final written = i - state.start < state.outputIds.length;
      final targetMoving = moving && i == state.k;
      final id = visibleArray[i];
      _pin(
        canvas,
        id,
        Offset(x(i), outputY),
        outputPinHeight,
        written && !targetMoving
            ? SortingVisualTokens.current
            : SortingVisualTokens.neutral,
        opacity: written && !targetMoving ? 1 : 0.55,
      );
      canvas.drawLine(
        Offset(x(i) - slotWidth * 0.22, outputY + 24),
        Offset(x(i) + slotWidth * 0.22, outputY + 24),
        Paint()
          ..color = written && !targetMoving
              ? SortingVisualTokens.current
              : colors.outlineVariant,
      );
    }
    if (state.k != null && state.k! < state.end) {
      _label(
        canvas,
        'k',
        x(state.k!),
        outputY + 30,
        SortingVisualTokens.minimum,
        12,
        FontWeight.w800,
        maxWidth: slotWidth - 4,
      );
    }
    if (moving) {
      final id = state.selectedId!;
      final leftIndex = state.leftIds.indexOf(id);
      final sourcePosition = leftIndex >= 0
          ? state.start + leftIndex
          : state.middle + state.rightIds.indexOf(id);
      final from = Offset(x(sourcePosition), localY);
      final to = Offset(x(state.start + state.outputIds.length - 1), outputY);
      _pin(
        canvas,
        id,
        Offset.lerp(from, to, progress)!,
        outputPinHeight,
        SortingVisualTokens.current,
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
  ) {
    final comparing =
        current.phase == SortingPhase.mergeComparing &&
        (current.currentId == id || current.comparingId == id);
    final copying = current.phase == SortingPhase.mergeCopying;
    final sourceReady = current.phase != SortingPhase.splitting;
    _pin(
      canvas,
      id,
      Offset(x(position), y),
      height,
      current.currentId == id && comparing
          ? SortingVisualTokens.current
          : current.comparingId == id && comparing
          ? SortingVisualTokens.compared
          : SortingVisualTokens.neutral,
      opacity: copying
          ? math.max(0.1, progress)
          : consumed
          ? 0.55
          : sourceReady
          ? 1
          : 0.75,
    );
    final pinWidth =
        math.min(height, (slotWidth - 12) / SortingVisualTokens.pinAspect) *
        SortingVisualTokens.relativeHeight(
          values[id],
          maxAbsolute,
          minPositive,
        ) *
        SortingVisualTokens.pinAspect;
    if (state.i == position && position < state.middle && sourceReady) {
      canvas.drawLine(
        Offset(x(position) - pinWidth / 2 - 3, y - 12),
        Offset(x(position) - pinWidth / 2 - 3, y - 2),
        Paint()
          ..color = SortingVisualTokens.current
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }
    if (state.j == position && position < state.end && sourceReady) {
      canvas.drawLine(
        Offset(x(position) + pinWidth / 2 + 3, y - 12),
        Offset(x(position) + pinWidth / 2 + 3, y - 2),
        Paint()
          ..color = SortingVisualTokens.compared
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
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
      oldDelegate.colors != colors ||
      oldDelegate.bottomInset != bottomInset;
}
