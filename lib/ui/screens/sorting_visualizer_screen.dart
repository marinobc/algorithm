import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../algorithms/core/algorithm_registry.dart';
import '../../application/providers/edicion_provider.dart';
import '../../application/providers/grafo_provider.dart';
import '../../domain/services/sorting_steps.dart';
import '../../domain/services/sorting_registry.dart';
import '../../domain/services/sorting_set_storage_service.dart';
import '../dialogs/sorting_set_dialogs.dart';
import '../dialogs/sorting_usage_dialog.dart';
import '../widgets/sorting_pin_visualizer.dart';
import '../widgets/merge_sort_visualizer.dart';
import '../widgets/sorting_visual_tokens.dart';
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
  final _selectedChipKey = GlobalKey();
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
  late BaseSortingAlgorithm _algorithm;
  List<int>? _originalValues;
  double _selectorWidth = 0;

  String get _title => _algorithm.name;
  String _phaseLabel(SortingPhase phase) => _algorithm.formatPhase(phase);

  @override
  void initState() {
    super.initState();
    _algorithm = widget.algorithm;
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
  void didUpdateWidget(covariant SortingVisualizerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.algorithm.id != widget.algorithm.id) {
      _selectAlgorithm(widget.algorithm);
    }
  }

  void _selectAlgorithm(BaseSortingAlgorithm algorithm) {
    if (_algorithm.id == algorithm.id) return;
    _stopPlayback();
    _motion.value = 1;
    setState(() {
      _algorithm = algorithm;
      _timeline = _originalValues == null
          ? null
          : algorithm.buildTimeline(_originalValues!);
      _stepIndex = 0;
      _fromIndex = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSelectedChip());
  }

  void _showSelectedChip() {
    final selectedContext = _selectedChipKey.currentContext;
    if (!mounted || selectedContext == null) return;
    Scrollable.ensureVisible(
      selectedContext,
      alignment: 0.5,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
    );
  }

  void _invalidateTimeline() {
    _stopPlayback();
    _motion.value = 1;
    setState(() {
      _originalValues = null;
      _timeline = null;
      _stepIndex = 0;
      _fromIndex = 0;
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
    if (parsed == null || parsed < 1) {
      setState(() => _quantityError = 'Ingresa una cantidad mayor que cero.');
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
      _originalValues = null;
      _stepIndex = 0;
      _fromIndex = 0;
      _inputMode = _InputMode.manual;
    });
  }

  void _loadValues(List<int> values) {
    _stopPlayback();
    _motion.value = 1;
    setState(() {
      _originalValues = List<int>.unmodifiable(values);
      _timeline = _algorithm.buildTimeline(_originalValues!);
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

  Future<void> _newSet() async {
    if (_originalValues != null ||
        _valueControllers.any((controller) => controller.text.isNotEmpty)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nuevo conjunto'),
          content: const Text(
            'Los números actuales se quitarán del laboratorio. Guarda el conjunto si quieres reutilizarlo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Nuevo'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    _stopPlayback();
    _motion.value = 1;
    for (final controller in _valueControllers) {
      controller.dispose();
    }
    _valueControllers.clear();
    _quantityController.text = '8';
    setState(() {
      _quantity = null;
      _quantityError = null;
      _invalidValues.clear();
      _inputMode = _InputMode.manual;
      _originalValues = null;
      _timeline = null;
      _stepIndex = 0;
      _fromIndex = 0;
    });
  }

  Future<void> _saveSet() async {
    final values = _originalValues;
    if (values == null) return;
    final name = await SortingSetDialogs.askName(context);
    if (name == null || !mounted) return;
    try {
      final saved = await SortingSetStorageService.save(name, values);
      if (mounted) _showSetMessage('"${saved.name}" guardado.');
    } catch (_) {
      if (mounted) _showSetMessage('No se pudo guardar el conjunto.');
    }
  }

  Future<void> _loadSet() async {
    final saved = await SortingSetDialogs.load(context);
    if (saved == null || !mounted) return;
    if (saved.values.isEmpty) {
      _showSetMessage('El conjunto guardado no contiene números.');
      return;
    }
    _stopPlayback();
    _motion.value = 1;
    for (final controller in _valueControllers) {
      controller.dispose();
    }
    _valueControllers
      ..clear()
      ..addAll(
        saved.values.map(
          (value) => TextEditingController(text: value.toString()),
        ),
      );
    _quantityController.text = saved.values.length.toString();
    setState(() {
      _quantity = saved.values.length;
      _quantityError = null;
      _invalidValues.clear();
      _inputMode = _InputMode.manual;
      _originalValues = List<int>.unmodifiable(saved.values);
      _timeline = _algorithm.buildTimeline(_originalValues!);
      _stepIndex = 0;
      _fromIndex = 0;
    });
    _showSetMessage('"${saved.name}" cargado.');
  }

  void _showSetMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _toolbarAction({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required bool compact,
  }) => compact
      ? IconButton(
          tooltip: label,
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          visualDensity: VisualDensity.compact,
        )
      : Padding(
          padding: const EdgeInsets.only(right: 6),
          child: OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
        );

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

  Widget _algorithmSelector() {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLowest,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (_selectorWidth != constraints.maxWidth) {
            _selectorWidth = constraints.maxWidth;
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _showSelectedChip(),
            );
          }
          return SizedBox(
            height: 62,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  for (final algorithm in SortingRegistry.registeredAlgorithms)
                    Padding(
                      key: _algorithm.id == algorithm.id
                          ? _selectedChipKey
                          : null,
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        key: Key('sorting-${algorithm.id}'),
                        label: Text(algorithm.name),
                        selected: _algorithm.id == algorithm.id,
                        showCheckmark: false,
                        selectedColor: colors.primaryContainer,
                        side: BorderSide(
                          color: _algorithm.id == algorithm.id
                              ? colors.primary
                              : colors.outlineVariant,
                        ),
                        labelStyle: TextStyle(
                          fontWeight: _algorithm.id == algorithm.id
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _algorithm.id == algorithm.id
                              ? colors.onPrimaryContainer
                              : colors.onSurfaceVariant,
                        ),
                        onSelected: (_) => _selectAlgorithm(algorithm),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final compactToolbar = MediaQuery.sizeOf(context).width < 760;
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
          _toolbarAction(
            label: 'Nuevo',
            icon: Icons.note_add_outlined,
            onPressed: _newSet,
            compact: compactToolbar,
          ),
          _toolbarAction(
            label: 'Cargar',
            icon: Icons.folder_open_outlined,
            onPressed: _loadSet,
            compact: compactToolbar,
          ),
          _toolbarAction(
            label: 'Guardar',
            icon: Icons.save_outlined,
            onPressed: _originalValues == null ? null : _saveSet,
            compact: compactToolbar,
          ),
          compactToolbar
              ? IconButton(
                  tooltip: 'Guía de uso',
                  onPressed: () => SortingUsageDialog.show(context, _algorithm),
                  icon: const Icon(Icons.help_outline_rounded, size: 20),
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  visualDensity: VisualDensity.compact,
                )
              : OutlinedButton.icon(
                  onPressed: () => SortingUsageDialog.show(context, _algorithm),
                  icon: const Icon(Icons.help_outline_rounded, size: 19),
                  label: const Text('Guía de uso'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
          if (!compactToolbar) const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Ir a la página principal',
            onPressed: _goHome,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          _algorithmSelector(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => _labLayout(constraints),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labLayout(BoxConstraints constraints) {
    final colors = Theme.of(context).colorScheme;
    if (constraints.maxWidth >= 1080 && constraints.maxHeight >= 540) {
      return ColoredBox(
        color: colors.surface,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 256, child: _selectionSide(_inputPanel())),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: _visualPanel(),
              ),
            ),
            SizedBox(width: 232, child: _selectionSide(_informationPanel())),
          ],
        ),
      );
    }
    if (constraints.maxWidth >= 700) {
      return SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    height: 640,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 240,
                          child: _selectionSide(_inputPanel()),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: _visualPanel()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _selectionSide(_informationPanel()),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _selectionSide(_inputPanel(scrollable: false)),
                const SizedBox(height: 16),
                SizedBox(
                  height: _algorithm.id == 'merge'
                      ? (constraints.maxWidth < 600 ? 620 : 650)
                      : (constraints.maxWidth < 600 ? 500 : 570),
                  child: _visualPanel(),
                ),
                const SizedBox(height: 16),
                _selectionSide(_informationPanel()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectionSide(Widget child) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }

  Widget _inputPanel({bool scrollable = true}) {
    final colors = Theme.of(context).colorScheme;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _panelHeading('Datos de entrada', Icons.tune_rounded),
        const SizedBox(height: 18),
        Text(
          'Cantidad de números',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _quantityController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Elementos',
            errorText: _quantityError,
            isDense: true,
            filled: true,
            fillColor: colors.surface,
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
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
        ),
        if (_quantity != null) ...[
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 18),
          Text(
            'Forma de ingreso',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          SegmentedButton<_InputMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: _InputMode.manual, label: Text('Manual')),
              ButtonSegment(value: _InputMode.random, label: Text('Aleatoria')),
            ],
            selected: {_inputMode},
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
            onSelectionChanged: (selection) {
              _stopPlayback();
              setState(() {
                _inputMode = selection.first;
                _originalValues = null;
                _timeline = null;
                _stepIndex = 0;
                _fromIndex = 0;
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
                          filled: true,
                          fillColor: colors.surface,
                        ),
                        onChanged: (_) {
                          _invalidateTimeline();
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
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ] else
            FilledButton.icon(
              onPressed: _generateRandom,
              icon: const Icon(Icons.shuffle_rounded),
              label: const Text('Generar números'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
            ),
        ],
      ],
    );
    return scrollable ? SingleChildScrollView(child: content) : content;
  }

  Widget _visualPanel() => _selectionVisualPanel();

  Widget _selectionVisualPanel() {
    final colors = Theme.of(context).colorScheme;
    final timeline = _timeline;
    final step = timeline?.steps[_stepIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _panelHeading('Visualización', Icons.sort_rounded)),
            if (timeline != null)
              Text(
                '${timeline.values.length} elementos',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: timeline == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Indica la cantidad y carga los números para comenzar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ),
                    )
                  : _algorithm.id == 'merge'
                  ? MergeSortVisualizer(
                      values: timeline.values,
                      previous: timeline.steps[_fromIndex],
                      current: step!,
                      progress: _motion,
                      followPlayback: true,
                    )
                  : SortingPinVisualizer(
                      values: timeline.values,
                      previous: timeline.steps[_fromIndex],
                      current: step!,
                      progress: _motion,
                      followPlayback: _playing || _algorithm.id == 'shell',
                      selectionStyle: _algorithm.id == 'selection',
                      shellStyle: _algorithm.id == 'shell',
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(minHeight: 50),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.08),
            border: Border(left: BorderSide(color: colors.primary, width: 3)),
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
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        if (timeline != null) ...[
          const SizedBox(height: 8),
          Slider(
            value: _stepIndex.toDouble(),
            max: (timeline.steps.length - 1).toDouble(),
            semanticFormatterCallback: (value) =>
                'Paso de animación ${value.round() + 1} de ${timeline.steps.length}',
            onChanged: (value) => _seek(value.round()),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
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
                Icon(
                  Icons.speed_rounded,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
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
                    if (value == null) return;
                    setState(() => _speed = value);
                    if (_algorithm.id == 'merge' && _motion.isAnimating) {
                      final fraction = _motion.value;
                      _motion.stop();
                      _motion.duration = Duration(
                        milliseconds: max(
                          50,
                          (_timeline!.steps[_stepIndex].durationMs / value)
                              .round(),
                        ),
                      );
                      _motion.forward(from: fraction);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _informationPanel() => _selectionInformationPanel();

  Widget _selectionInformationPanel() {
    final colors = Theme.of(context).colorScheme;
    final timeline = _timeline;
    final step = timeline?.steps[_stepIndex];
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _panelHeading('Estado y complejidad', Icons.analytics_outlined),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
          const SizedBox(height: 18),
          _stat(
            'Paso de animación',
            timeline == null
                ? '0'
                : '${_stepIndex + 1} / ${timeline.steps.length}',
          ),
          _stat('Comparaciones', '${step?.comparisons ?? 0}'),
          if (_algorithm.id == 'selection' || _algorithm.id == 'shell')
            _stat('Intercambios', '${step?.movements ?? 0}'),
          if (_algorithm.id == 'insertion') ...[
            _stat('Desplazamientos', '${step?.movements ?? 0}'),
            _stat('Inserciones', '${step?.insertions ?? 0}'),
          ],
          if (_algorithm.id == 'shell') _stat('Gap', '${step?.gap ?? '—'}'),
          if (_algorithm.id == 'merge') ...[
            _stat('Copias a aux[]', '${step?.auxCopies ?? 0}'),
            _stat('Escrituras en a[]', '${step?.writes ?? 0}'),
          ],
          const Divider(height: 32),
          Text('Complejidad', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            switch (_algorithm.id) {
              'selection' => 'n(n - 1) / 2',
              'insertion' => 'n² / 4',
              'shell' => 'Θ(n³ᐟ²)',
              _ => 'Θ(n log n)',
            },
            style: TextStyle(
              color: colors.primary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (_algorithm.id == 'selection') ...[
            const SizedBox(height: 4),
            Text('≈ n² / 2', style: TextStyle(color: colors.onSurfaceVariant)),
          ],
          const SizedBox(height: 6),
          Text(switch (_algorithm.id) {
            'selection' => 'O(n²) · comparaciones fijas',
            'insertion' => 'Promedio aproximado · peor caso O(n²)',
            'shell' => 'Incrementos: 1, 4, 13, …',
            _ => 'Espacio auxiliar: Θ(n)',
          }, style: TextStyle(color: colors.onSurfaceVariant)),
          const Divider(height: 32),
          Text('Indicadores', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          if (_algorithm.id == 'selection') ...[
            _selectionIndicator(
              'i',
              'posición actual',
              SortingVisualTokens.current,
            ),
            _selectionIndicator(
              'j',
              'elemento inspeccionado',
              SortingVisualTokens.compared,
            ),
            _selectionIndicator(
              'MIN',
              'menor encontrado',
              SortingVisualTokens.minimum,
            ),
            _selectionIndicator(
              '✓',
              'posición definitiva',
              SortingVisualTokens.ordered,
            ),
          ],
          if (_algorithm.id == 'insertion') ...[
            _selectionIndicator(
              'KEY',
              'clave extraída',
              SortingVisualTokens.key,
            ),
            _selectionIndicator(
              'j',
              'elemento comparado',
              SortingVisualTokens.compared,
            ),
            _selectionIndicator(
              '✓',
              'prefijo ordenado',
              SortingVisualTokens.ordered,
            ),
          ],
          if (_algorithm.id == 'shell') ...[
            _selectionIndicator(
              'j',
              'posición actual',
              SortingVisualTokens.current,
            ),
            _selectionIndicator(
              'j-h',
              'posición a distancia h',
              SortingVisualTokens.compared,
            ),
            _selectionIndicator(
              '↔',
              'intercambio real',
              SortingVisualTokens.current,
            ),
            _selectionIndicator(
              'h',
              'distancia de la pasada',
              SortingVisualTokens.compared,
            ),
          ],
          if (_algorithm.id == 'merge') ...[
            _selectionIndicator(
              'i/j',
              'punteros en aux[]',
              SortingVisualTokens.compared,
            ),
            _selectionIndicator(
              '●',
              'mitad ordenada internamente',
              SortingVisualTokens.internallyOrdered,
            ),
            _selectionIndicator(
              '●',
              'salida parcial',
              SortingVisualTokens.current,
            ),
            _selectionIndicator(
              '✓',
              'resultado completo',
              SortingVisualTokens.ordered,
            ),
          ],
        ],
      ),
    );
  }

  Widget _selectionIndicator(String marker, String label, Color color) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: dark ? 0.28 : 0.12),
              border: Border.all(color: color.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              marker,
              style: TextStyle(
                color: dark ? Colors.white : color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
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
