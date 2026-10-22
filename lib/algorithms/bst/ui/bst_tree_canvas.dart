import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/bst_tree.dart';

class BstTreeCanvas extends StatefulWidget {
  final BstTree tree;
  final List<int> insertionPath;

  const BstTreeCanvas({
    super.key,
    required this.tree,
    this.insertionPath = const [],
  });

  @override
  State<BstTreeCanvas> createState() => _BstTreeCanvasState();
}

class _BstTreeCanvasState extends State<BstTreeCanvas>
    with SingleTickerProviderStateMixin {
  final TransformationController _camera = TransformationController();
  late final AnimationController _transition;
  late _TreeLayout _layout;
  Map<String, Offset> _previous = const {};
  Size _viewport = Size.zero;
  bool _autoFit = true;

  @override
  void initState() {
    super.initState();
    _layout = _TreeLayout.compute(widget.tree);
    _transition =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 220),
          value: 1,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && _autoFit) _scheduleFit();
        });
    _scheduleFit();
  }

  @override
  void didUpdateWidget(covariant BstTreeCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tree.root != widget.tree.root) {
      _previous = _currentPositions();
      _layout = _TreeLayout.compute(widget.tree);
      if (MediaQuery.disableAnimationsOf(context)) {
        _transition.value = 1;
        if (_autoFit) _scheduleFit();
      } else {
        _transition.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _transition.dispose();
    _camera.dispose();
    super.dispose();
  }

  Map<String, Offset> _currentPositions() {
    final result = <String, Offset>{};
    for (final entry in _layout.positions.entries) {
      final target = entry.value;
      final start = _previous[entry.key] ?? target;
      result[entry.key] = Offset.lerp(start, target, _transition.value)!;
    }
    return result;
  }

  void _scheduleFit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _autoFit) _fit();
    });
  }

  void _fit() {
    if (_viewport.isEmpty) return;
    final scale = math
        .min(
          1.0,
          math.min(
            (_viewport.width - 40) / _layout.size.width,
            (_viewport.height - 40) / _layout.size.height,
          ),
        )
        .clamp(0.04, 3.0);
    final x = (_viewport.width - _layout.size.width * scale) / 2;
    final y = (_viewport.height - _layout.size.height * scale) / 2;
    _camera.value = _matrix(scale, x, y);
    _autoFit = true;
  }

  Matrix4 _matrix(double scale, double x, double y) => Matrix4.identity()
    ..setEntry(0, 0, scale)
    ..setEntry(1, 1, scale)
    ..setEntry(0, 3, x)
    ..setEntry(1, 3, y);

  void _zoom(double factor) {
    final old = _camera.value;
    final scale = old.getMaxScaleOnAxis();
    final next = (scale * factor).clamp(0.04, 3.0);
    final ratio = next / scale;
    final center = Offset(_viewport.width / 2, _viewport.height / 2);
    final x = center.dx - (center.dx - old.entry(0, 3)) * ratio;
    final y = center.dy - (center.dy - old.entry(1, 3)) * ratio;
    _camera.value = _matrix(next, x, y);
    _autoFit = false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (size != _viewport) {
          _viewport = size;
          _scheduleFit();
        }
        return Stack(
          children: [
            Positioned.fill(
              child: widget.tree.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.account_tree_outlined,
                            size: 46,
                            color: colors.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tu árbol aparecerá aquí',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    )
                  : InteractiveViewer(
                      transformationController: _camera,
                      constrained: false,
                      minScale: 0.04,
                      maxScale: 3,
                      boundaryMargin: const EdgeInsets.all(300),
                      onInteractionStart: (_) => _autoFit = false,
                      child: AnimatedBuilder(
                        animation: _transition,
                        builder: (context, child) {
                          final positions = <String, Offset>{};
                          for (final entry in _layout.positions.entries) {
                            final start =
                                _previous[entry.key] ??
                                _layout.positions[_layout.parents[entry.key]] ??
                                entry.value.translate(0, -40);
                            positions[entry.key] = Offset.lerp(
                              start,
                              entry.value,
                              Curves.easeOutCubic.transform(_transition.value),
                            )!;
                          }
                          return SizedBox(
                            width: _layout.size.width,
                            height: _layout.size.height,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _TreeEdgePainter(
                                      positions: positions,
                                      parents: _layout.parents,
                                      color: colors.outline,
                                      activeColor: colors.primary,
                                      activeValues: widget.insertionPath
                                          .toSet(),
                                      nodes: _layout.nodes,
                                    ),
                                  ),
                                ),
                                for (final entry in _layout.nodes.entries)
                                  Positioned(
                                    key: ValueKey(entry.key),
                                    left: positions[entry.key]!.dx - 32,
                                    top: positions[entry.key]!.dy - 32,
                                    child: Opacity(
                                      opacity: _previous.containsKey(entry.key)
                                          ? 1
                                          : _transition.value,
                                      child: _TreeNodeWidget(
                                        node: entry.value,
                                        isRoot:
                                            entry.key == widget.tree.root?.id,
                                        active: widget.insertionPath.contains(
                                          entry.value.value,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Material(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Alejar árbol',
                      onPressed: () => _zoom(0.8),
                      icon: const Icon(Icons.remove_rounded),
                    ),
                    IconButton(
                      tooltip: 'Centrar y ajustar árbol',
                      onPressed: _fit,
                      icon: const Icon(Icons.center_focus_strong_rounded),
                    ),
                    IconButton(
                      tooltip: 'Acercar árbol',
                      onPressed: () => _zoom(1.25),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TreeLayout {
  final Size size;
  final Map<String, Offset> positions;
  final Map<String, String> parents;
  final Map<String, BstNode> nodes;

  const _TreeLayout(this.size, this.positions, this.parents, this.nodes);

  static _TreeLayout compute(BstTree tree) {
    final positions = <String, Offset>{};
    final parents = <String, String>{};
    final nodes = <String, BstNode>{};
    var rank = 0;
    var maxDepth = 0;
    void visit(BstNode? node, int depth, String? parent) {
      if (node == null) return;
      visit(node.left, depth + 1, node.id);
      nodes[node.id] = node;
      if (parent != null) parents[node.id] = parent;
      positions[node.id] = Offset(64 + rank * 88.0, 68 + depth * 106.0);
      rank++;
      maxDepth = math.max(maxDepth, depth);
      visit(node.right, depth + 1, node.id);
    }

    visit(tree.root, 0, null);
    final width = math.max(560.0, rank * 88.0 + 40);
    final offset = (width - (rank * 88.0 + 40)) / 2;
    for (final entry in positions.entries.toList()) {
      positions[entry.key] = entry.value.translate(offset, 0);
    }
    return _TreeLayout(
      Size(width, math.max(340.0, (maxDepth + 1) * 106.0 + 48)),
      positions,
      parents,
      nodes,
    );
  }
}

class _TreeEdgePainter extends CustomPainter {
  final Map<String, Offset> positions;
  final Map<String, String> parents;
  final Map<String, BstNode> nodes;
  final Set<int> activeValues;
  final Color color;
  final Color activeColor;

  const _TreeEdgePainter({
    required this.positions,
    required this.parents,
    required this.nodes,
    required this.activeValues,
    required this.color,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final entry in parents.entries) {
      final parent = positions[entry.value]!;
      final child = positions[entry.key]!;
      final highlighted =
          activeValues.contains(nodes[entry.value]!.value) &&
          activeValues.contains(nodes[entry.key]!.value);
      final paint = Paint()
        ..color = highlighted ? activeColor : color.withValues(alpha: 0.55)
        ..strokeWidth = highlighted ? 2.8 : 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(parent.translate(0, 27), child.translate(0, -27), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TreeEdgePainter oldDelegate) =>
      oldDelegate.positions != positions ||
      oldDelegate.activeValues != activeValues ||
      oldDelegate.color != color;
}

class _TreeNodeWidget extends StatelessWidget {
  final BstNode node;
  final bool isRoot;
  final bool active;

  const _TreeNodeWidget({
    required this.node,
    required this.isRoot,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label:
          'Nodo ${node.value}, frecuencia ${node.frequency}${isRoot ? ', raíz' : ''}',
      child: SizedBox(
        width: 64,
        height: 64,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRoot ? colors.primary : colors.primaryContainer,
                border: Border.all(
                  color: active ? colors.tertiary : colors.primary,
                  width: active ? 3 : 1.5,
                ),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${node.value}',
                    style: TextStyle(
                      color: isRoot
                          ? colors.onPrimary
                          : colors.onPrimaryContainer,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            if (node.frequency > 1)
              Positioned(
                right: -12,
                bottom: -7,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.tertiaryContainer,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.tertiary),
                  ),
                  child: Text(
                    '×${node.frequency}',
                    style: TextStyle(
                      color: colors.onTertiaryContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
