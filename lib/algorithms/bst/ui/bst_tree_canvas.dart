import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/bst_tree.dart';

class BstTreeCanvas extends StatefulWidget {
  final BstTree tree;
  final List<int> insertionPath;
  final List<int> traversalVisitedValues;
  final int? traversalStep;
  final int? traversalTotal;

  const BstTreeCanvas({
    super.key,
    required this.tree,
    this.insertionPath = const [],
    this.traversalVisitedValues = const [],
    this.traversalStep,
    this.traversalTotal,
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
  bool _fitWhenFirstTreeAppears = false;

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
          if (status == AnimationStatus.completed && _fitWhenFirstTreeAppears) {
            _fitWhenFirstTreeAppears = false;
            _scheduleFit();
          }
        });
  }

  @override
  void didUpdateWidget(covariant BstTreeCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tree.root != widget.tree.root) {
      _previous = _currentPositions();
      _layout = _TreeLayout.compute(widget.tree);
      final isFirstTree = oldWidget.tree.isEmpty && !widget.tree.isEmpty;
      if (MediaQuery.disableAnimationsOf(context)) {
        _transition.value = 1;
        if (isFirstTree) _scheduleFit();
        _fitWhenFirstTreeAppears = false;
      } else {
        if (widget.tree.isEmpty) {
          _fitWhenFirstTreeAppears = false;
        } else if (isFirstTree) {
          _fitWhenFirstTreeAppears = true;
        }
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
      if (mounted) _fit();
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
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (size != _viewport) {
          _viewport = size;
        }
        return Stack(
          children: [
            Positioned.fill(
              child: widget.tree.isEmpty
                  ? Center(
                      child: Semantics(
                        container: true,
                        liveRegion: true,
                        label: 'Construye tu primer árbol BST. Introduce valores en el panel izquierdo. Los menores van a la izquierda y los mayores, a la derecha. Ejemplo: 5, 3, 7, 1, 4.',
                        child: ExcludeSemantics(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.account_tree_outlined,
                                size: 30,
                                color: colors.primary.withValues(alpha: .75),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Construye tu primer árbol BST',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 310,
                                ),
                                child: Text(
                                  'Introduce valores en el panel izquierdo para ver tu árbol.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : InteractiveViewer(
                      transformationController: _camera,
                      constrained: false,
                      minScale: 0.04,
                      maxScale: 3,
                      boundaryMargin: const EdgeInsets.all(300),
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
                          final visited = widget.traversalVisitedValues;
                          final idByValue = {
                            for (final node in _layout.nodes.values)
                              node.value: node.id,
                          };
                          final traversedEdges = <String>{};
                          for (var i = 1; i < visited.length; i++) {
                            var from = idByValue[visited[i - 1]];
                            var to = idByValue[visited[i]];
                            if (from == null || to == null || from == to) {
                              continue;
                            }
                            final fromAncestors = <String>{};
                            String? ancestor = from;
                            while (ancestor != null) {
                              fromAncestors.add(ancestor);
                              ancestor = _layout.parents[ancestor];
                            }
                            while (to != null && !fromAncestors.contains(to)) {
                              traversedEdges.add(to);
                              to = _layout.parents[to];
                            }
                            while (from != null && from != to) {
                              traversedEdges.add(from);
                              from = _layout.parents[from];
                            }
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
                                      traversalEdgeIds: traversedEdges,
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
                                        visited: widget.traversalVisitedValues
                                            .contains(entry.value.value),
                                        visitNumber:
                                            visited.indexOf(entry.value.value) +
                                            1,
                                        current:
                                            widget
                                                .traversalVisitedValues
                                                .isNotEmpty &&
                                            widget
                                                    .traversalVisitedValues
                                                    .last ==
                                                entry.value.value,
                                        traversalStep: widget.traversalStep,
                                        traversalTotal: widget.traversalTotal,
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
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Alejar árbol',
                        onPressed: widget.tree.isEmpty
                            ? null
                            : () => _zoom(0.8),
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      IconButton(
                        tooltip: 'Centrar y ajustar árbol',
                        onPressed: widget.tree.isEmpty ? null : _fit,
                        icon: const Icon(Icons.center_focus_strong_rounded),
                      ),
                      IconButton(
                        tooltip: 'Acercar árbol',
                        onPressed: widget.tree.isEmpty
                            ? null
                            : () => _zoom(1.25),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
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
  final Set<String> traversalEdgeIds;
  final Color color;
  final Color activeColor;

  const _TreeEdgePainter({
    required this.positions,
    required this.parents,
    required this.nodes,
    required this.activeValues,
    required this.traversalEdgeIds,
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
      final traversed = traversalEdgeIds.contains(entry.key);
      final paint = Paint()
        ..color = traversed
            ? const Color(0xFFFFC83D)
            : highlighted
            ? activeColor
            : color.withValues(alpha: 0.55)
        ..strokeWidth = traversed
            ? 4
            : highlighted
            ? 2.8
            : 2
        ..strokeCap = StrokeCap.round;
      final direction = child - parent;
      final distance = direction.distance;
      if (distance <= 70) continue;
      final inset = direction / distance * 35;
      canvas.drawLine(parent + inset, child - inset, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TreeEdgePainter oldDelegate) =>
      oldDelegate.positions != positions ||
      oldDelegate.parents != parents ||
      oldDelegate.nodes != nodes ||
      oldDelegate.activeValues != activeValues ||
      oldDelegate.traversalEdgeIds != traversalEdgeIds ||
      oldDelegate.color != color ||
      oldDelegate.activeColor != activeColor;
}

class _TreeNodeWidget extends StatelessWidget {
  final BstNode node;
  final bool isRoot;
  final bool active;
  final bool visited;
  final int visitNumber;
  final bool current;
  final int? traversalStep;
  final int? traversalTotal;

  const _TreeNodeWidget({
    required this.node,
    required this.isRoot,
    required this.active,
    required this.visited,
    required this.visitNumber,
    required this.current,
    required this.traversalStep,
    required this.traversalTotal,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const traversalYellow = Color(0xFFFFC83D);
    return Semantics(
      label:
          'Nodo ${node.value}, frecuencia ${node.frequency}${isRoot ? ', raíz' : ''}${current
              ? ', paso $traversalStep de $traversalTotal'
              : visited
              ? ', ya visitado'
              : ''}',
      excludeSemantics: true,
      child: SizedBox(
        width: 64,
        height: 64,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: visited && !isRoot
                    ? traversalYellow.withValues(alpha: .28)
                    : isRoot
                    ? colors.primary
                    : colors.primaryContainer,
                border: Border.all(
                  color: visited ? traversalYellow : colors.primary,
                  width: current
                      ? 4
                      : active || visited
                      ? 3
                      : 1.5,
                ),
                boxShadow: current
                    ? [
                        BoxShadow(
                          color: traversalYellow.withValues(alpha: .55),
                          blurRadius: 14,
                          spreadRadius: 5,
                        ),
                      ]
                    : null,
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
            if (visited)
              Positioned(
                left: 48,
                top: -12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: traversalYellow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    current && traversalStep != null && traversalTotal != null
                        ? '$traversalStep/$traversalTotal'
                        : '$visitNumber',
                    style: TextStyle(
                      color: const Color(0xFF302400),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
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
