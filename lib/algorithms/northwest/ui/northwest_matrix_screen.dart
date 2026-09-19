import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/grafo_provider.dart';
import '../../../../domain/models/atributo.dart';
import '../../../../domain/models/conexion.dart';
import '../../../../domain/models/direccion.dart';
import '../../../../domain/models/grafo.dart';
import '../../../../domain/models/nodo.dart';
import '../../../../domain/services/graph_color_generator.dart';
import '../../../../ui/widgets/algorithm_optimize_action.dart';
import '../domain/models/northwest_models.dart';
import '../domain/services/northwest_problem_extractor.dart';
import '../providers/northwest_provider.dart';

class NorthwestMatrixScreen extends ConsumerStatefulWidget {
  const NorthwestMatrixScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const NorthwestMatrixScreen()));
  }

  @override
  ConsumerState<NorthwestMatrixScreen> createState() =>
      _NorthwestMatrixScreenState();
}

class _NorthwestMatrixScreenState extends ConsumerState<NorthwestMatrixScreen> {
  static const int _maxDimension = 12;
  final _originCount = TextEditingController(text: '3');
  final _destinationCount = TextEditingController(text: '4');
  final _matrixScrollController = ScrollController();
  List<TextEditingController> _originNames = [];
  List<TextEditingController> _destinationNames = [];
  List<TextEditingController> _supplies = [];
  List<TextEditingController> _demands = [];
  List<List<TextEditingController>> _costs = [];
  List<String> _originIds = [];
  List<String> _destinationIds = [];
  TransportationObjective _objective = TransportationObjective.minimize;
  String? _error;
  bool _matrixReady = false;

  @override
  void initState() {
    super.initState();
    final problem = ref.read(northwestProblemProvider);
    if (problem != null) _loadProblem(problem);
  }

  void _loadProblem(TransportationInput problem) {
    _originCount.text = '${problem.rowCount}';
    _destinationCount.text = '${problem.columnCount}';
    _originIds = List.from(problem.originIds);
    _destinationIds = List.from(problem.destinationIds);
    _originNames = problem.originNames.map(_controller).toList();
    _destinationNames = problem.destinationNames.map(_controller).toList();
    _supplies = problem.supplies
        .map((value) => _controller(_format(value)))
        .toList();
    _demands = problem.demands
        .map((value) => _controller(_format(value)))
        .toList();
    _costs = problem.costs
        .map((row) => row.map((value) => _controller(_format(value))).toList())
        .toList();
    _objective = problem.objective;
    _matrixReady = true;
  }

  TextEditingController _controller([String value = '']) =>
      TextEditingController(text: value);

  @override
  void dispose() {
    _originCount.dispose();
    _destinationCount.dispose();
    _matrixScrollController.dispose();
    _disposeMatrixControllers();
    super.dispose();
  }

  void _disposeMatrixControllers() {
    for (final controller in [
      ..._originNames,
      ..._destinationNames,
      ..._supplies,
      ..._demands,
      ..._costs.expand((row) => row),
    ]) {
      controller.dispose();
    }
  }

  Future<void> _applyDimensions() async {
    final rows = int.tryParse(_originCount.text.trim());
    final columns = int.tryParse(_destinationCount.text.trim());
    if (rows == null ||
        columns == null ||
        rows < 1 ||
        columns < 1 ||
        rows > _maxDimension ||
        columns > _maxDimension) {
      setState(() {
        _error = 'Usa dimensiones entre 1 y $_maxDimension.';
      });
      return;
    }
    if (_matrixReady &&
        (rows < _originNames.length || columns < _destinationNames.length)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reducir matriz'),
          content: const Text(
            'Se eliminaran los datos de las filas o columnas que ya no existan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    _resize(rows, columns);
  }

  void _resize(int rows, int columns) {
    final oldOriginNames = _originNames;
    final oldDestinationNames = _destinationNames;
    final oldSupplies = _supplies;
    final oldDemands = _demands;
    final oldCosts = _costs;
    final stamp = DateTime.now().microsecondsSinceEpoch;

    _originNames = List.generate(
      rows,
      (index) => index < oldOriginNames.length
          ? oldOriginNames[index]
          : _controller(_originLabel(index)),
    );
    _destinationNames = List.generate(
      columns,
      (index) => index < oldDestinationNames.length
          ? oldDestinationNames[index]
          : _controller('D${index + 1}'),
    );
    _supplies = List.generate(
      rows,
      (index) =>
          index < oldSupplies.length ? oldSupplies[index] : _controller(),
    );
    _demands = List.generate(
      columns,
      (index) => index < oldDemands.length ? oldDemands[index] : _controller(),
    );
    _costs = List.generate(
      rows,
      (i) => List.generate(
        columns,
        (j) => i < oldCosts.length && j < oldCosts[i].length
            ? oldCosts[i][j]
            : _controller(),
      ),
    );
    _originIds = List.generate(
      rows,
      (index) => index < _originIds.length
          ? _originIds[index]
          : 'nw_origin_${stamp}_$index',
    );
    _destinationIds = List.generate(
      columns,
      (index) => index < _destinationIds.length
          ? _destinationIds[index]
          : 'nw_destination_${stamp}_$index',
    );
    setState(() {
      _matrixReady = true;
      _error = null;
    });
  }

  String _originLabel(int index) {
    if (index < 26) return String.fromCharCode(65 + index);
    return 'O${index + 1}';
  }

  TransportationInput? _readInput() {
    final originNames = _originNames.map((item) => item.text.trim()).toList();
    final destinationNames = _destinationNames
        .map((item) => item.text.trim())
        .toList();
    final names = [...originNames, ...destinationNames];
    if (names.any((name) => name.isEmpty)) {
      _setError('Completa todos los nombres.');
      return null;
    }
    if (names.toSet().length != names.length) {
      _setError('Los nombres de origenes y destinos no pueden repetirse.');
      return null;
    }

    final supplies = _parseVector(_supplies, 'ofertas', nonNegative: true);
    final demands = _parseVector(_demands, 'demandas', nonNegative: true);
    if (supplies == null || demands == null) return null;
    final costs = <List<double>>[];
    for (var i = 0; i < _costs.length; i++) {
      final row = _parseVector(_costs[i], 'costos de ${originNames[i]}');
      if (row == null) return null;
      costs.add(row);
    }
    final supplyTotal = supplies.fold<double>(0, (sum, value) => sum + value);
    final demandTotal = demands.fold<double>(0, (sum, value) => sum + value);
    if ((supplyTotal - demandTotal).abs() > 1e-9) {
      _setError(
        'Problema desequilibrado. Oferta: ${_format(supplyTotal)}, '
        'demanda: ${_format(demandTotal)}, diferencia: '
        '${_format((supplyTotal - demandTotal).abs())}.',
      );
      return null;
    }
    return TransportationInput(
      originIds: List.from(_originIds),
      destinationIds: List.from(_destinationIds),
      originNames: originNames,
      destinationNames: destinationNames,
      costs: costs,
      supplies: supplies,
      demands: demands,
      objective: _objective,
    );
  }

  List<double>? _parseVector(
    List<TextEditingController> controllers,
    String label, {
    bool nonNegative = false,
  }) {
    final result = <double>[];
    for (final controller in controllers) {
      final value = double.tryParse(controller.text.trim());
      if (value == null || !value.isFinite || (nonNegative && value < 0)) {
        _setError(
          'Completa $label con numeros finitos${nonNegative ? ' no negativos' : ''}.',
        );
        return null;
      }
      result.add(value);
    }
    return result;
  }

  void _setError(String message) => setState(() => _error = message);

  Future<void> _save({bool optimize = false}) async {
    final input = _readInput();
    if (input == null) return;
    final current = ref.read(grafoProvider);
    final nodes = <String, Nodo>{};
    final connections = <String, Conexion>{};
    final existingConnections = {
      for (final connection in current.conexiones.values)
        '${connection.nodoOrigenId}|${connection.nodoDestinoId}': connection,
    };

    for (var i = 0; i < input.rowCount; i++) {
      final id = input.originIds[i];
      final existing = current.nodos[id];
      nodes[id] = Nodo(
        id: id,
        nombre: input.originNames[i],
        colorValue:
            existing?.colorValue ??
            GraphColorGenerator.generateMaximallyDistinctColor(
              Grafo(nodos: nodes),
            ),
        x: existing?.x ?? 180,
        y: existing?.y ?? 120 + i * 110,
        radius: existing?.radius ?? Nodo.defaultRadius,
        rol: NorthwestRoles.origin,
        cantidad: input.supplies[i],
      );
    }
    for (var j = 0; j < input.columnCount; j++) {
      final id = input.destinationIds[j];
      final existing = current.nodos[id];
      nodes[id] = Nodo(
        id: id,
        nombre: input.destinationNames[j],
        colorValue:
            existing?.colorValue ??
            GraphColorGenerator.generateMaximallyDistinctColor(
              Grafo(nodos: nodes),
            ),
        x: existing?.x ?? 760,
        y: existing?.y ?? 120 + j * 110,
        radius: existing?.radius ?? Nodo.defaultRadius,
        rol: NorthwestRoles.destination,
        cantidad: input.demands[j],
      );
    }
    final stamp = DateTime.now().microsecondsSinceEpoch;
    for (var i = 0; i < input.rowCount; i++) {
      for (var j = 0; j < input.columnCount; j++) {
        final originId = input.originIds[i];
        final destinationId = input.destinationIds[j];
        final existing = existingConnections['$originId|$destinationId'];
        final id = existing?.id ?? 'nw_connection_${stamp}_${i}_$j';
        connections[id] = Conexion(
          id: id,
          nodoOrigenId: originId,
          nodoDestinoId: destinationId,
          colorValue: existing?.colorValue ?? nodes[originId]!.colorValue,
          direccion: Direccion.unidireccional,
          atributos: [
            AtributoValor(
              atributoId: 'attr_valor',
              valor: _format(input.costs[i][j]),
            ),
          ],
          curvatura: existing?.curvatura,
          loopAngle: existing?.loopAngle,
          offsetControlX: existing?.offsetControlX,
          offsetControlY: existing?.offsetControlY,
        );
      }
    }
    final graph = Grafo(
      nodos: nodes,
      conexiones: connections,
      atributosGlobales: current.atributosGlobales,
      tipoAlgoritmo: 'northwest',
      metadata: {
        NorthwestMetadata.originOrder: input.originIds.join(','),
        NorthwestMetadata.destinationOrder: input.destinationIds.join(','),
        NorthwestMetadata.objective: input.objective.name,
      },
    );
    ref.read(northwestNotifierProvider.notifier).setActive(false);
    ref.read(grafoProvider.notifier).reemplazarGrafo(graph);
    if (optimize) {
      final didOptimize = await runActiveAlgorithm(context, ref);
      if (!didOptimize) return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matriz de transporte'),
        actions: [
          if (_matrixReady)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Guardar'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _save(optimize: true),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Optimizar'),
                ),
                const SizedBox(width: 12),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildDimensionBar(colors),
            if (_error != null)
              Container(
                width: double.infinity,
                color: colors.errorContainer,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: colors.onErrorContainer),
                ),
              ),
            Expanded(
              child: _matrixReady
                  ? _buildMatrix(colors)
                  : _buildInitialState(colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDimensionBar(ColorScheme colors) {
    return Container(
      width: double.infinity,
      color: colors.surfaceContainerLow,
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(width: 130, child: _numberField(_originCount, 'Origenes')),
          const Icon(Icons.close_rounded, size: 18),
          SizedBox(
            width: 130,
            child: _numberField(_destinationCount, 'Destinos'),
          ),
          FilledButton.tonalIcon(
            onPressed: _applyDimensions,
            icon: const Icon(Icons.grid_view_rounded),
            label: Text(_matrixReady ? 'Aplicar dimensiones' : 'Crear matriz'),
          ),
          if (_matrixReady)
            SegmentedButton<TransportationObjective>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: TransportationObjective.minimize,
                  icon: Icon(Icons.trending_down_rounded),
                  label: Text('Minimizar'),
                ),
                ButtonSegment(
                  value: TransportationObjective.maximize,
                  icon: Icon(Icons.trending_up_rounded),
                  label: Text('Maximizar'),
                ),
              ],
              selected: {_objective},
              onSelectionChanged: (value) =>
                  setState(() => _objective = value.first),
            ),
        ],
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, isDense: true),
    );
  }

  Widget _buildInitialState(ColorScheme colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.table_chart_outlined, size: 54, color: colors.primary),
            const SizedBox(height: 16),
            Text(
              'Define las dimensiones del problema',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Luego podras ingresar nombres, costos, ofertas y demandas.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrix(ColorScheme colors) {
    final totalSupply = _sumControllers(_supplies);
    final totalDemand = _sumControllers(_demands);
    return Scrollbar(
      controller: _matrixScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _matrixScrollController,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _headerCell('Origen', 130, colors),
                  for (final controller in _destinationNames)
                    _nameCell(controller, 110, colors),
                  _headerCell('Oferta', 110, colors),
                ],
              ),
              for (var i = 0; i < _originNames.length; i++)
                Row(
                  children: [
                    _nameCell(_originNames[i], 130, colors),
                    for (var j = 0; j < _destinationNames.length; j++)
                      _valueCell(_costs[i][j], 110, colors),
                    _valueCell(_supplies[i], 110, colors, emphasized: true),
                  ],
                ),
              Row(
                children: [
                  _headerCell('Demanda', 130, colors),
                  for (final controller in _demands)
                    _valueCell(controller, 110, colors, emphasized: true),
                  _headerCell(
                    '${_format(totalSupply)} / ${_format(totalDemand)}',
                    110,
                    colors,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Total oferta: ${_format(totalSupply)}   '
                'Total demanda: ${_format(totalDemand)}',
                style: TextStyle(
                  color: (totalSupply - totalDemand).abs() <= 1e-9
                      ? colors.primary
                      : colors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCell(String text, double width, ColorScheme colors) {
    return Container(
      width: width,
      height: 58,
      margin: const EdgeInsets.all(2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _nameCell(
    TextEditingController controller,
    double width,
    ColorScheme colors,
  ) {
    return _cell(
      controller,
      width,
      colors.secondaryContainer.withValues(alpha: .55),
      TextInputType.text,
    );
  }

  Widget _valueCell(
    TextEditingController controller,
    double width,
    ColorScheme colors, {
    bool emphasized = false,
  }) {
    return _cell(
      controller,
      width,
      emphasized
          ? colors.tertiaryContainer.withValues(alpha: .65)
          : colors.surfaceContainerHigh,
      const TextInputType.numberWithOptions(decimal: true, signed: true),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _cell(
    TextEditingController controller,
    double width,
    Color background,
    TextInputType keyboardType, {
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      width: width,
      height: 58,
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlign: TextAlign.center,
        onChanged: onChanged,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  double _sumControllers(List<TextEditingController> controllers) => controllers
      .map((controller) => double.tryParse(controller.text.trim()) ?? 0)
      .fold(0, (sum, value) => sum + value);

  static String _format(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
}
