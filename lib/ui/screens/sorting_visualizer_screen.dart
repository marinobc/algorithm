import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../algorithms/core/algorithm_registry.dart';
import '../../application/providers/edicion_provider.dart';
import '../../application/providers/grafo_provider.dart';
import '../../domain/services/sorting_steps.dart';
import '../dialogs/sorting_usage_dialog.dart';
import '../widgets/sorting_pin_visualizer.dart';
import 'welcome_explanation_screen.dart';

import '../../domain/services/base_sorting_algorithm.dart';

enum _InputMode { manual, random }

class SortingVisualizerScreen extends ConsumerStatefulWidget {
  final BaseSortingAlgorithm algorithm;

  const SortingVisualizerScreen({super.key, required this.algorithm});

  @override
  ConsumerState<SortingVisualizerScreen> createState() =>
      _SortingVisualizerScreenState();
}

class _SortingVisualizerScreenState
    extends ConsumerState<SortingVisualizerScreen>
    with SingleTickerProviderStateMixin {
  final _quantityController = TextEditingController(text: '8');
  final _random = Random();
  final List<TextEditingController> _valueControllers = [];
  final Set<int> _invalidValues = {};
  late final AnimationController _motion;

  int? _quantity;
  String? _quantityError;
  _InputMode _inputMode = _InputMode.manual;
  SortingTimeline? _timeline;
  int _stepIndex = 0;
  int _fromIndex = 0;
  double _speed = 1;
  bool _playing = false;

  String get _title => widget.algorithm.name;

  String _phaseLabel(SortingPhase phase) => widget.algorithm.formatPhase(phase);

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(vsync: this, value: 1)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && _playing && mounted) {
          if (_timeline != null && _stepIndex < _timeline!.steps.length - 1) {
            _advance();
          } else {
            setState(() => _playing = false);
          }
        }
      });
  }

  @override
  void dispose() {
    _motion.dispose();
    _quantityController.dispose();
    for (final controller in _valueControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _confirmQuantity() {
    final parsed = int.tryParse(_quantityController.text.trim());
    if (parsed == null || parsed < 1 || parsed > 60) {
      setState(() => _quantityError = 'Ingresa una cantidad entre 1 y 60.');
      return;
    }
    _stopPlayback();
    for (final controller in _valueControllers) {
      controller.dispose();
    }
    _valueControllers.clear();
    _valueControllers.addAll(
      List.generate(parsed, (_) => TextEditingController()),
    );
    setState(() {
      _quantity = parsed;
      _quantityError = null;
      _invalidValues.clear();
      _timeline = null;
      _stepIndex = 0;
      _fromIndex = 0;
      _inputMode = _InputMode.manual;
    });
  }

  void _loadValues(List<int> values) {
    _stopPlayback();
    _motion.value = 1;
    setState(() {
      _timeline = widget.algorithm.buildTimeline(values);
      _stepIndex = 0;
      _fromIndex = 0;
    });
  }

  void _applyManualValues() {
    final values = <int>[];
    final invalid = <int>{};
    for (var i = 0; i < _valueControllers.length; i++) {
      final parsed = int.tryParse(_valueControllers[i].text.trim());
      if (parsed == null || parsed < -1000000000 || parsed > 1000000000) {
        invalid.add(i);
      } else {
        values.add(parsed);
      }
    }
    if (invalid.isNotEmpty) {
      setState(() {
        _invalidValues
          ..clear()
          ..addAll(invalid);
      });
      return;
    }
    setState(() => _invalidValues.clear());
    _loadValues(values);
  }

  void _generateRandom() {
    final count = _quantity;
    if (count == null) return;
    _loadValues(List.generate(count, (_) => 5 + _random.nextInt(95)));
  }

  void _stopPlayback() {
    _motion.stop();
    _playing = false;
  }

  void _advance() {
    final timeline = _timeline;
    if (timeline == null || _stepIndex >= timeline.steps.length - 1) {
      if (_playing) setState(() => _playing = false);
      return;
    }
    setState(() {
      _fromIndex = _stepIndex;
      _stepIndex++;
    });
    _motion.duration = Duration(
      milliseconds: max(
        50,
        (timeline.steps[_stepIndex].durationMs / _speed).round(),
      ),
    );
    _motion.forward(from: 0);
  }

  void _togglePlayback() {
    if (_timeline == null) return;
    if (_playing) {
      setState(() => _playing = false);
      _motion.stop();
      return;
    }
    if (_stepIndex >= _timeline!.steps.length - 1 && _motion.value == 1) {
      _restart();
    }
    setState(() => _playing = true);
    if (_motion.value < 1) {
      _motion.forward();
    } else {
      _advance();
    }
  }

  void _nextStep() {
    if (_timeline == null) return;
    setState(() => _playing = false);
    if (_motion.value < 1) {
      _motion.forward();
    } else {
      _advance();
    }
  }

  void _previousStep() {
    if (_timeline == null) return;
    final target = _motion.value < 1 ? _fromIndex : max(0, _stepIndex - 1);
    _stopPlayback();
    _motion.value = 1;
    setState(() {
      _stepIndex = target;
      _fromIndex = target;
    });
  }

  void _restart() {
    _stopPlayback();
    _motion.value = 1;
    setState(() {
      _stepIndex = 0;
      _fromIndex = 0;
    });
  }

  void _seek(int index) {
    _stopPlayback();
    _motion.value = 1;
    setState(() {
      _stepIndex = index;
      _fromIndex = index;
    });
  }

  void _goHome() {
    ref.read(grafoProvider.notifier).limpiarGrafo();
    ref.read(loadedGraphItemProvider.notifier).setLoadedItem(null);
    ref.read(activeAlgorithmProvider.notifier).clear();
    ref.read(estadoEdicionProvider.notifier).desmarcarCambiosSinGuardar();
    ref.read(estadoEdicionProvider.notifier).deseleccionar();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeExplanationScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surfaceContainerHigh,
        title: Text(
          _title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: MediaQuery.sizeOf(context).width < 430 ? 17 : 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => SortingUsageDialog.show(context, widget.algorithm),
            icon: const Icon(Icons.help_outline_rounded, size: 19),
            label: const Text('Guía de uso'),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Ir a la página principal',
            onPressed: _goHome,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          if (width >= 1080 && constraints.maxHeight >= 510) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 270, child: _inputPanel()),
                  const VerticalDivider(width: 25),
                  Expanded(child: _visualPanel()),
                  const VerticalDivider(width: 25),
                  SizedBox(width: 250, child: _informationPanel()),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _inputPanel(scrollable: false),
                      const Divider(height: 26),
                      SizedBox(height: 460, child: _visualPanel()),
                      const Divider(height: 26),
                      _informationPanel(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _inputPanel({bool scrollable = true}) {
    final colors = Theme.of(context).colorScheme;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _panelHeading('Datos de entrada', Icons.tune_rounded),
        const SizedBox(height: 6),
        Text(
          'Cantidad de números',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _quantityController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Elementos',
            errorText: _quantityError,
            isDense: true,
          ),
          onChanged: (_) {
            if (_quantityError != null) setState(() => _quantityError = null);
          },
          onSubmitted: (_) => _confirmQuantity(),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _confirmQuantity,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Continuar'),
        ),
        if (_quantity != null) ...[
          const SizedBox(height: 20),
          Text(
            'Forma de ingreso',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          SegmentedButton<_InputMode>(
            segments: const [
              ButtonSegment(
                value: _InputMode.manual,
                icon: Icon(Icons.edit_outlined),
                label: Text('Manual'),
              ),
              ButtonSegment(
                value: _InputMode.random,
                icon: Icon(Icons.shuffle_rounded),
                label: Text('Aleatoria'),
              ),
            ],
            selected: {_inputMode},
            onSelectionChanged: (selection) {
              _stopPlayback();
              setState(() {
                _inputMode = selection.first;
                _timeline = null;
                _invalidValues.clear();
              });
            },
          ),
          const SizedBox(height: 16),
          if (_inputMode == _InputMode.manual) ...[
            Text(
              'Introduce $_quantity valores',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _valueControllers.length; i++)
                    SizedBox(
                      width: (constraints.maxWidth - 8) / 2,
                      child: TextField(
                        controller: _valueControllers[i],
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: true,
                        ),
                        decoration: InputDecoration(
                          labelText: '#${i + 1}',
                          errorText: _invalidValues.contains(i)
                              ? 'Número inválido'
                              : null,
                          isDense: true,
                        ),
                        onChanged: (_) {
                          if (_invalidValues.contains(i)) {
                            setState(() => _invalidValues.remove(i));
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _applyManualValues,
              icon: const Icon(Icons.playlist_add_check_rounded),
              label: const Text('Visualizar números'),
            ),
          ] else
            FilledButton.icon(
              onPressed: _generateRandom,
              icon: const Icon(Icons.shuffle_rounded),
              label: const Text('Generar números'),
            ),
        ],
      ],
    );
    return scrollable ? SingleChildScrollView(child: content) : content;
  }

  Widget _visualPanel() {
    final colors = Theme.of(context).colorScheme;
    final timeline = _timeline;
    final step = timeline?.steps[_stepIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _panelHeading('Visualización', Icons.bar_chart_rounded),
            ),
            if (timeline != null)
              Text(
                '${timeline.values.length} elementos',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: timeline == null
                ? Center(
                    child: Text(
                      'Indica la cantidad y carga los números para comenzar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  )
                : SortingPinVisualizer(
                    values: timeline.values,
                    previous: timeline.steps[_fromIndex],
                    current: step!,
                    progress: _motion,
                    followPlayback: _playing,
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                step?.phase == SortingPhase.finished
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline_rounded,
                size: 19,
                color: colors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  step?.message ?? 'Prepara un conjunto de números.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (timeline != null) ...[
          Slider(
            value: _stepIndex.toDouble(),
            max: (timeline.steps.length - 1).toDouble(),
            onChanged: (value) => _seek(value.round()),
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Reiniciar',
                onPressed: _restart,
                icon: const Icon(Icons.restart_alt_rounded),
              ),
              IconButton(
                tooltip: 'Paso anterior',
                onPressed: _stepIndex > 0 ? _previousStep : null,
                icon: const Icon(Icons.skip_previous_rounded),
              ),
              IconButton.filled(
                tooltip: _playing ? 'Pausar' : 'Reproducir',
                onPressed: _togglePlayback,
                icon: Icon(
                  _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
              ),
              IconButton(
                tooltip: 'Siguiente paso',
                onPressed: _stepIndex < timeline.steps.length - 1
                    ? _nextStep
                    : null,
                icon: const Icon(Icons.skip_next_rounded),
              ),
              const Spacer(),
              const Icon(Icons.speed_rounded, size: 18),
              const SizedBox(width: 4),
              DropdownButton<double>(
                value: _speed,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 0.5, child: Text('0.5x')),
                  DropdownMenuItem(value: 1, child: Text('1x')),
                  DropdownMenuItem(value: 2, child: Text('2x')),
                  DropdownMenuItem(value: 4, child: Text('4x')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _speed = value);
                },
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _informationPanel() {
    final colors = Theme.of(context).colorScheme;
    final timeline = _timeline;
    final step = timeline?.steps[_stepIndex];
    final isSelection = widget.algorithm.id == 'selection';
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelHeading('Estado y complejidad', Icons.analytics_outlined),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              step == null ? 'LISTO' : _phaseLabel(step.phase),
              style: TextStyle(
                color: colors.onPrimaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _stat(
            'Paso',
            timeline == null
                ? '0'
                : '${_stepIndex + 1} / ${timeline.steps.length}',
          ),
          _stat('Comparaciones', '${step?.comparisons ?? 0}'),
          _stat(
            isSelection ? 'Intercambios' : 'Desplazamientos',
            '${step?.movements ?? 0}',
          ),
          if (!isSelection) _stat('Inserciones', '${step?.insertions ?? 0}'),
          const Divider(height: 32),
          Text('Complejidad', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            isSelection ? 'n(n - 1) / 2' : 'n² / 4',
            style: TextStyle(
              color: colors.primary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isSelection) ...[
            const SizedBox(height: 4),
            Text('≈ n² / 2', style: TextStyle(color: colors.onSurfaceVariant)),
          ],
          const SizedBox(height: 6),
          Text('O(n²)', style: TextStyle(color: colors.onSurfaceVariant)),
          const Divider(height: 32),
          Text('Indicadores', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            isSelection
                ? 'i · posición actual\nj · elemento inspeccionado\nMIN · menor encontrado'
                : 'KEY · elemento clave\nj · elemento comparado\nLínea inferior · región ordenada',
            style: TextStyle(color: colors.onSurfaceVariant, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _panelHeading(String title, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 19, color: colors.primary),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}
