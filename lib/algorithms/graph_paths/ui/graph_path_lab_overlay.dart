import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/direccion.dart';
import '../../../domain/models/grafo.dart';
import '../../../application/providers/grafo_provider.dart';
import '../../core/algorithm_registry.dart';
import '../domain/graph_path_solver.dart';
import '../providers/graph_path_run_provider.dart';
import 'graph_path_colors.dart';

const _dijkstraAccent = GraphPathColors.dijkstraAccent;
const _kruskalAccent = GraphPathColors.kruskalAccent;

String _number(double value) {
  if (!value.isFinite) return value.isNegative ? '−∞' : '∞';
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _nodeLabel(Grafo graph, String? id) =>
    id == null ? '—' : (graph.nodos[id]?.nombre ?? id);

String _edgeLabel(Grafo graph, String id) {
  final edge = graph.conexiones[id];
  if (edge == null) return id;
  final symbol = edge.direccion == Direccion.ninguna ? '–' : '→';
  final weight =
      edge.atributos
          .where((a) => a.atributoId == 'attr_valor')
          .map((a) => a.valor)
          .firstOrNull ??
      '?';
  return '${_nodeLabel(graph, edge.nodoOrigenId)} $symbol ${_nodeLabel(graph, edge.nodoDestinoId)}  ($weight)';
}

/// Algorithm results float over the shared GraphCanvas; no graph editing occurs here.
class GraphPathLabOverlay extends ConsumerStatefulWidget {
  const GraphPathLabOverlay({super.key});

  @override
  ConsumerState<GraphPathLabOverlay> createState() =>
      _GraphPathLabOverlayState();
}

class _GraphPathLabOverlayState extends ConsumerState<GraphPathLabOverlay> {
  Timer? _timer;
  bool _playing = false;
  bool _detailsExpanded = false;
  double _speed = 1;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
    if (_playing && mounted) setState(() => _playing = false);
  }

  void _play() {
    final state = ref.read(graphPathRunProvider);
    final length = state.computation?.steps.length ?? 0;
    if (length < 2) return;
    if (state.stepIndex >= length - 1) {
      ref.read(graphPathRunProvider.notifier).seek(0);
    }
    _timer?.cancel();
    setState(() => _playing = true);
    _timer = Timer.periodic(Duration(milliseconds: (900 / _speed).round()), (
      _,
    ) {
      final now = ref.read(graphPathRunProvider);
      final count = now.computation?.steps.length ?? 0;
      if (count == 0 || now.stepIndex >= count - 1) {
        _pause();
        return;
      }
      ref.read(graphPathRunProvider.notifier).seek(now.stepIndex + 1);
    });
  }

  void _seek(int index) {
    _pause();
    ref.read(graphPathRunProvider.notifier).seek(index);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GraphPathRunState>(graphPathRunProvider, (previous, next) {
      if (previous?.computation != null && next.computation == null) {
        _pause();
      }
    });
    if (ref.watch(graphPathRunProvider).computation == null) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 1120;
        final availableHeight = constraints.maxHeight - (desktop ? 32 : 94);
        return Stack(
          children: [
            Positioned(
              right: desktop ? 16 : 8,
              left: desktop ? null : 8,
              width: desktop ? 324 : null,
              top: desktop ? 16 : null,
              bottom: desktop ? null : 72,
              height: min(
                _detailsExpanded
                    ? (desktop ? 540.0 : constraints.maxHeight * .65)
                    : 320.0,
                availableHeight,
              ),
              child: _GraphPathResultPanel(
                playing: _playing,
                detailsExpanded: _detailsExpanded,
                onToggleDetails: () =>
                    setState(() => _detailsExpanded = !_detailsExpanded),
                speed: _speed,
                onPlayPause: _playing ? _pause : _play,
                onSeek: _seek,
                onSpeed: (speed) {
                  _pause();
                  setState(() => _speed = speed);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GraphPathResultPanel extends ConsumerWidget {
  final bool playing;
  final bool detailsExpanded;
  final VoidCallback onToggleDetails;
  final double speed;
  final VoidCallback onPlayPause;
  final ValueChanged<int> onSeek;
  final ValueChanged<double> onSpeed;

  const _GraphPathResultPanel({
    required this.playing,
    required this.detailsExpanded,
    required this.onToggleDetails,
    required this.speed,
    required this.onPlayPause,
    required this.onSeek,
    required this.onSpeed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graph = ref.watch(grafoProvider);
    final state = ref.watch(graphPathRunProvider);
    final run = state.computation;
    final step = state.currentStep;
    final colors = Theme.of(context).colorScheme;
    final kruskal =
        ref.watch(activeAlgorithmProvider)?.id == AlgorithmRegistry.kruskalId;
    return _panel(
      context,
      title: 'Estado y explicación',
      icon: Icons.analytics_outlined,
      accent: kruskal ? _kruskalAccent : _dijkstraAccent,
      trailing: IconButton(
        tooltip: detailsExpanded
            ? 'Mostrar menos detalles'
            : 'Mostrar más detalles',
        onPressed: onToggleDetails,
        icon: Icon(
          detailsExpanded
              ? Icons.close_fullscreen_rounded
              : Icons.open_in_full_rounded,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
        children: [
          if (state.error != null) _notice(context, state.error!),
          if (run == null && state.error == null)
            Text(
              'Construye un grafo, configura el método y pulsa Calcular. Aquí aparecerán las decisiones paso a paso.',
              style: TextStyle(height: 1.5, color: colors.onSurfaceVariant),
            ),
          if (run != null && step != null) ...[
            Text(
              run.method,
              style: TextStyle(
                color: kruskal ? _kruskalAccent : _dijkstraAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              run.summary,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (!run.exact) ...[
              const SizedBox(height: 6),
              _notice(
                context,
                'Búsqueda incompleta: el valor mostrado es solo el mejor conocido, no un máximo demostrado.',
              ),
            ],
            const SizedBox(height: 14),
            Text(
              'Paso ${state.stepIndex + 1} de ${run.steps.length}',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            Slider(
              value: state.stepIndex.toDouble(),
              min: 0,
              max: max(1, run.steps.length - 1).toDouble(),
              onChanged: run.steps.length > 1
                  ? (value) => onSeek(value.round())
                  : null,
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 1,
              children: [
                IconButton(
                  tooltip: 'Reiniciar',
                  onPressed: () => onSeek(0),
                  icon: const Icon(Icons.restart_alt_rounded),
                ),
                IconButton(
                  tooltip: 'Paso anterior',
                  onPressed: state.stepIndex > 0
                      ? () => onSeek(state.stepIndex - 1)
                      : null,
                  icon: const Icon(Icons.skip_previous_rounded),
                ),
                IconButton.filled(
                  tooltip: playing ? 'Pausar' : 'Reproducir',
                  onPressed: run.steps.length > 1 ? onPlayPause : null,
                  icon: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                ),
                IconButton(
                  tooltip: 'Paso siguiente',
                  onPressed: state.stepIndex < run.steps.length - 1
                      ? () => onSeek(state.stepIndex + 1)
                      : null,
                  icon: const Icon(Icons.skip_next_rounded),
                ),
                PopupMenuButton<double>(
                  tooltip: 'Velocidad',
                  initialValue: speed,
                  onSelected: onSpeed,
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: .5, child: Text('0.5×')),
                    PopupMenuItem(value: 1, child: Text('1×')),
                    PopupMenuItem(value: 2, child: Text('2×')),
                    PopupMenuItem(value: 4, child: Text('4×')),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 12,
                    ),
                    child: Text('${_number(speed)}×'),
                  ),
                ),
              ],
            ),
            const Divider(),
            Text(
              step.title,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              step.explanation,
              style: TextStyle(height: 1.5, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Chip(label: Text('${step.examinedEdges} aristas examinadas')),
                if (!kruskal)
                  Chip(label: Text('${step.comparisons} comparaciones')),
                if (kruskal)
                  Chip(
                    label: Text(
                      'Peso acumulado ${_number(step.accumulatedWeight)}',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (kruskal)
              _kruskalStatus(context, graph, run, step)
            else
              _pathStatus(context, ref, graph, state, run, step),
          ],
        ],
      ),
    );
  }

  Widget _pathStatus(
    BuildContext context,
    WidgetRef ref,
    Grafo graph,
    GraphPathRunState state,
    GraphComputation run,
    GraphAlgorithmStep step,
  ) {
    final colors = Theme.of(context).colorScheme;
    final ids = graph.nodos.keys.toList()
      ..sort((a, b) => _nodeLabel(graph, a).compareTo(_nodeLabel(graph, b)));
    final isLast = state.stepIndex == run.steps.length - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (step.distances.isNotEmpty) ...[
          Text(
            'Distancias y predecesores',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          for (final id in ids)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 55,
                    child: Text(
                      _nodeLabel(graph, id),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _number(step.distances[id] ?? double.infinity),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '← ${_nodeLabel(graph, step.predecessors[id])}',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  if (step.settledNodes.contains(id))
                    const Padding(
                      padding: EdgeInsets.only(left: 5),
                      child: Icon(
                        Icons.check_circle,
                        color: _dijkstraAccent,
                        size: 15,
                      ),
                    ),
                ],
              ),
            ),
        ],
        if (isLast && run.pathNodeIds.isNotEmpty) ...[
          const Divider(),
          Text(
            'Camino: ${run.pathNodeIds.map((id) => _nodeLabel(graph, id)).join(' → ')}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (run.alternatives.length > 1) ...[
            const SizedBox(height: 6),
            Text(
              'Caminos óptimos encontrados${run.alternativesTruncated ? ' (lista limitada)' : ''}:',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                ChoiceChip(
                  label: const Text('Principal'),
                  selected: state.alternativeIndex == -1,
                  onSelected: (_) => ref
                      .read(graphPathRunProvider.notifier)
                      .selectAlternative(-1),
                ),
                for (var i = 0; i < run.alternatives.length; i++)
                  ChoiceChip(
                    label: Text(
                      run.alternatives[i].nodeIds
                          .map((id) => _nodeLabel(graph, id))
                          .join('→'),
                    ),
                    selected: state.alternativeIndex == i,
                    onSelected: (_) => ref
                        .read(graphPathRunProvider.notifier)
                        .selectAlternative(i),
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _kruskalStatus(
    BuildContext context,
    Grafo graph,
    GraphComputation run,
    GraphAlgorithmStep step,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aristas por peso',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        for (var i = 0; i < run.orderedEdgeIds.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 27,
                  child: Text(
                    '${i + 1}.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
                Expanded(
                  child: Text(
                    _edgeLabel(graph, run.orderedEdgeIds[i]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  step.acceptedEdges.contains(run.orderedEdgeIds[i])
                      ? Icons.check_circle_rounded
                      : step.rejectedEdges.contains(run.orderedEdgeIds[i])
                      ? Icons.cancel_rounded
                      : step.currentEdgeId == run.orderedEdgeIds[i]
                      ? Icons.visibility_rounded
                      : Icons.radio_button_unchecked,
                  size: 17,
                  color: step.acceptedEdges.contains(run.orderedEdgeIds[i])
                      ? Colors.green.shade700
                      : step.rejectedEdges.contains(run.orderedEdgeIds[i])
                      ? colors.error
                      : _kruskalAccent,
                ),
              ],
            ),
          ),
        const Divider(),
        Text(
          'Componentes',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            for (final node in graph.nodos.values)
              Chip(
                label: Text(
                  '${node.nombre ?? node.id}: ${step.components[node.id] ?? '—'}',
                ),
              ),
          ],
        ),
      ],
    );
  }
}

Widget _panel(
  BuildContext context, {
  required String title,
  required IconData icon,
  required Widget child,
  required Color accent,
  Widget? trailing,
}) {
  final colors = Theme.of(context).colorScheme;
  return Material(
    color: colors.surface,
    elevation: 6,
    shadowColor: accent.withValues(alpha: .18),
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: accent.withValues(alpha: .25)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
            color: accent.withValues(alpha: .14),
            child: Row(
              children: [
                Icon(icon, size: 19, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    ),
  );
}

Widget _notice(BuildContext context, String text) => Container(
  padding: const EdgeInsets.all(10),
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.errorContainer,
    borderRadius: BorderRadius.circular(10),
  ),
  child: Text(
    text,
    style: TextStyle(
      color: Theme.of(context).colorScheme.onErrorContainer,
      height: 1.4,
    ),
  ),
);
