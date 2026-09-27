import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/grafo_provider.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../domain/models/grafo.dart';
import '../../../../ui/widgets/app_toast.dart';
import '../../../../ui/widgets/matrix/bipartite_matrix_config.dart';
import '../../../../ui/widgets/matrix/matrix_input_widgets.dart';
import '../../../../ui/widgets/matrix/universal_matrix_preflight_coordinator.dart';
import '../domain/services/assignment_graph_matrix_service.dart';
import '../providers/assignment_provider.dart';
import 'config/assignment_matrix_config.dart';
import 'widgets/assignment_matrix_grid_table.dart';

export 'config/assignment_matrix_config.dart';

/// Dedicated matrix input and editing screen for Assignment / Hungarian method.
class AssignmentGraphMatrixScreen extends ConsumerStatefulWidget {
  final BipartiteMatrixConfig config;

  const AssignmentGraphMatrixScreen({
    super.key,
    this.config = const AssignmentMatrixConfig(),
  });

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AssignmentGraphMatrixScreen()),
    );
  }

  @override
  ConsumerState<AssignmentGraphMatrixScreen> createState() =>
      _AssignmentGraphMatrixScreenState();
}

class _AssignmentGraphMatrixScreenState
    extends ConsumerState<AssignmentGraphMatrixScreen> {
  static const int _maxDimension = 12;

  final _originCount = TextEditingController(text: '3');
  final _destinationCount = TextEditingController(text: '3');

  List<TextEditingController> _originNames = [];
  List<TextEditingController> _destinationNames = [];
  List<FocusNode> _originFocusNodes = [];
  List<FocusNode> _destinationFocusNodes = [];
  List<List<TextEditingController>> _costs = [];
  List<List<FocusNode>> _cellFocusNodes = [];
  List<String> _originIds = [];
  List<String> _destinationIds = [];

  String? _error;
  bool _isDirty = false;
  bool _canPop = false;

  @override
  void initState() {
    super.initState();
    final graph = ref.read(grafoProvider);
    _initFromGraphOrDefaults(graph);
  }

  @override
  void dispose() {
    _originCount.dispose();
    _destinationCount.dispose();
    _disposeMatrixControllers();
    super.dispose();
  }

  void _disposeMatrixControllers() {
    for (final controller in [
      ..._originNames,
      ..._destinationNames,
      ..._costs.expand((row) => row),
    ]) {
      controller.dispose();
    }
    for (final fn in _originFocusNodes) {
      fn.dispose();
    }
    for (final fn in _destinationFocusNodes) {
      fn.dispose();
    }
    for (final fn in _cellFocusNodes.expand((row) => row)) {
      fn.dispose();
    }
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() {
        _isDirty = true;
      });
    }
  }

  TextEditingController _createController([String value = '']) {
    final controller = TextEditingController(text: value);
    controller.addListener(_markDirty);
    return controller;
  }

  void _initFromGraphOrDefaults(Grafo graph) {
    final origins = graph.nodos.values
        .where((node) => node.rol == widget.config.originRole)
        .toList();
    final destinations = graph.nodos.values
        .where((node) => node.rol == widget.config.destinationRole)
        .toList();

    if (origins.isNotEmpty && destinations.isNotEmpty) {
      final preflight = UniversalMatrixPreflightCoordinator.calculateBalancing(
        config: widget.config,
        realOriginIds: origins.map((n) => n.id).toList(),
        realOriginNames: origins.map((n) => n.nombre ?? n.id).toList(),
        realDestinationIds: destinations.map((n) => n.id).toList(),
        realDestinationNames: destinations
            .map((n) => n.nombre ?? n.id)
            .toList(),
      );

      final rows = preflight.originNames.length;
      final cols = preflight.destinationNames.length;

      _originCount.text = '$rows';
      _destinationCount.text = '$cols';
      _originIds = preflight.originIds;
      _destinationIds = preflight.destinationIds;

      _originNames = preflight.originNames
          .map((name) => _createController(name))
          .toList();
      _destinationNames = preflight.destinationNames
          .map((name) => _createController(name))
          .toList();

      _originFocusNodes = List.generate(rows, (_) => FocusNode());
      _destinationFocusNodes = List.generate(cols, (_) => FocusNode());

      _costs = List.generate(
        rows,
        (i) => List.generate(cols, (j) {
          if (i >= origins.length || j >= destinations.length) {
            return _createController('0');
          }
          final costStr = AssignmentGraphMatrixService.findConnectionCost(
            graph,
            origins[i].id,
            destinations[j].id,
            widget.config.costAttributeId,
          );
          return _createController(costStr ?? '');
        }),
      );
      _cellFocusNodes = List.generate(
        rows,
        (i) => List.generate(cols, (_) => FocusNode()),
      );
    } else {
      _disposeMatrixControllers();
      _originNames = [];
      _destinationNames = [];
      _originFocusNodes = [];
      _destinationFocusNodes = [];
      _costs = [];
      _cellFocusNodes = [];
      _originIds = [];
      _destinationIds = [];
    }
    _isDirty = false;
  }

  void _resize(int rows, int columns, {bool isInitial = false}) {
    final realOriginIndices = <int>[];
    for (var i = 0; i < _originIds.length; i++) {
      if (!_originIds[i].contains('_dummy_')) {
        realOriginIndices.add(i);
      }
    }
    final realDestIndices = <int>[];
    for (var j = 0; j < _destinationIds.length; j++) {
      if (!_destinationIds[j].contains('_dummy_')) {
        realDestIndices.add(j);
      }
    }

    final realRowsCount = rows;
    final realColsCount = columns;

    final oldOriginNames = _originNames;
    final oldDestinationNames = _destinationNames;
    final oldOriginFocusNodes = _originFocusNodes;
    final oldDestinationFocusNodes = _destinationFocusNodes;
    final oldCosts = _costs;
    final stamp = DateTime.now().microsecondsSinceEpoch;

    final rawOriginNames = List.generate(
      realRowsCount,
      (index) => index < realOriginIndices.length
          ? oldOriginNames[realOriginIndices[index]].text
          : _originLabel(index),
    );
    final rawDestinationNames = List.generate(
      realColsCount,
      (index) => index < realDestIndices.length
          ? oldDestinationNames[realDestIndices[index]].text
          : 'D${index + 1}',
    );
    final rawOriginIds = List.generate(
      realRowsCount,
      (index) => index < realOriginIndices.length
          ? _originIds[realOriginIndices[index]]
          : '${widget.config.idPrefix}_origin_${stamp}_$index',
    );
    final rawDestinationIds = List.generate(
      realColsCount,
      (index) => index < realDestIndices.length
          ? _destinationIds[realDestIndices[index]]
          : '${widget.config.idPrefix}_destination_${stamp}_$index',
    );

    final preflight = UniversalMatrixPreflightCoordinator.calculateBalancing(
      config: widget.config,
      realOriginIds: rawOriginIds,
      realOriginNames: rawOriginNames,
      realDestinationIds: rawDestinationIds,
      realDestinationNames: rawDestinationNames,
    );

    final totalRows = preflight.originNames.length;
    final totalCols = preflight.destinationNames.length;

    _originNames = List.generate(totalRows, (i) {
      final realIdx = i < realOriginIndices.length ? realOriginIndices[i] : -1;
      return realIdx >= 0 && realIdx < oldOriginNames.length
          ? oldOriginNames[realIdx]
          : _createController(preflight.originNames[i]);
    });
    _destinationNames = List.generate(totalCols, (j) {
      final realIdx = j < realDestIndices.length ? realDestIndices[j] : -1;
      return realIdx >= 0 && realIdx < oldDestinationNames.length
          ? oldDestinationNames[realIdx]
          : _createController(preflight.destinationNames[j]);
    });
    _originIds = preflight.originIds;
    _destinationIds = preflight.destinationIds;

    _originFocusNodes = List.generate(
      totalRows,
      (i) =>
          i < realOriginIndices.length &&
              realOriginIndices[i] < oldOriginFocusNodes.length
          ? oldOriginFocusNodes[realOriginIndices[i]]
          : FocusNode(),
    );
    _destinationFocusNodes = List.generate(
      totalCols,
      (j) =>
          j < realDestIndices.length &&
              realDestIndices[j] < oldDestinationFocusNodes.length
          ? oldDestinationFocusNodes[realDestIndices[j]]
          : FocusNode(),
    );

    _costs = List.generate(
      totalRows,
      (i) => List.generate(totalCols, (j) {
        final isDummyRow = _originIds[i].contains('_dummy_');
        final isDummyCol = _destinationIds[j].contains('_dummy_');
        if (isDummyRow || isDummyCol) {
          return _createController('0');
        }
        final oldRowIdx = i < realOriginIndices.length
            ? realOriginIndices[i]
            : -1;
        final oldColIdx = j < realDestIndices.length ? realDestIndices[j] : -1;
        if (oldRowIdx >= 0 &&
            oldColIdx >= 0 &&
            oldRowIdx < oldCosts.length &&
            oldColIdx < oldCosts[oldRowIdx].length) {
          return oldCosts[oldRowIdx][oldColIdx];
        }
        return _createController();
      }),
    );

    final oldFocusNodes = _cellFocusNodes;
    _cellFocusNodes = List.generate(
      totalRows,
      (i) => List.generate(totalCols, (j) {
        final oldRowIdx = i < realOriginIndices.length
            ? realOriginIndices[i]
            : -1;
        final oldColIdx = j < realDestIndices.length ? realDestIndices[j] : -1;
        if (oldRowIdx >= 0 &&
            oldColIdx >= 0 &&
            oldRowIdx < oldFocusNodes.length &&
            oldColIdx < oldFocusNodes[oldRowIdx].length) {
          return oldFocusNodes[oldRowIdx][oldColIdx];
        }
        return FocusNode();
      }),
    );

    final keptOriginNames = _originNames.toSet();
    for (final ctrl in oldOriginNames) {
      if (!keptOriginNames.contains(ctrl)) ctrl.dispose();
    }
    final keptDestNames = _destinationNames.toSet();
    for (final ctrl in oldDestinationNames) {
      if (!keptDestNames.contains(ctrl)) ctrl.dispose();
    }
    final keptCosts = _costs.expand((r) => r).toSet();
    for (final ctrl in oldCosts.expand((r) => r)) {
      if (!keptCosts.contains(ctrl)) ctrl.dispose();
    }
    final keptOriginFn = _originFocusNodes.toSet();
    for (final fn in oldOriginFocusNodes) {
      if (!keptOriginFn.contains(fn)) fn.dispose();
    }
    final keptDestFn = _destinationFocusNodes.toSet();
    for (final fn in oldDestinationFocusNodes) {
      if (!keptDestFn.contains(fn)) fn.dispose();
    }
    final keptCellFn = _cellFocusNodes.expand((r) => r).toSet();
    for (final fn in oldFocusNodes.expand((r) => r)) {
      if (!keptCellFn.contains(fn)) fn.dispose();
    }

    setState(() {
      _originCount.text = '$realRowsCount';
      _destinationCount.text = '$realColsCount';
      _error = null;
      if (!isInitial) _isDirty = true;
    });
  }

  int get _realRowCount =>
      _originIds.where((id) => !id.contains('_dummy_')).length;
  int get _realColCount =>
      _destinationIds.where((id) => !id.contains('_dummy_')).length;

  String _originLabel(int index) {
    if (index < 26) return String.fromCharCode(65 + index);
    return 'O${index + 1}';
  }

  void _addRow() {
    final currentReal = _realRowCount;
    if (currentReal >= _maxDimension) {
      _setError('El máximo de filas es $_maxDimension.');
      return;
    }
    _resize(currentReal + 1, _realColCount);
  }

  void _removeRow() {
    final currentReal = _realRowCount;
    if (currentReal <= 1) {
      _setError('Debe haber al menos 1 fila.');
      return;
    }
    _resize(currentReal - 1, _realColCount);
  }

  void _addColumn() {
    final currentReal = _realColCount;
    if (currentReal >= _maxDimension) {
      _setError('El máximo de columnas es $_maxDimension.');
      return;
    }
    _resize(_realRowCount, currentReal + 1);
  }

  void _removeColumn() {
    final currentReal = _realColCount;
    if (currentReal <= 1) {
      _setError('Debe haber al menos 1 columna.');
      return;
    }
    _resize(_realRowCount, currentReal - 1);
  }

  Future<void> _clearMatrix() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vaciar matriz'),
        content: const Text(
          'Se eliminarán todos los valores y datos de la matriz actual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _disposeMatrixControllers();
      _originNames = [];
      _destinationNames = [];
      _costs = [];
      _originIds = [];
      _destinationIds = [];
      _error = null;
      _isDirty = true;
    });
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

    if (rows < _realRowCount || columns < _realColCount) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reducir matriz'),
          content: const Text(
            'Se eliminarán los datos de las filas o columnas sobrantes.',
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

  void _setError(String message) {
    setState(() {
      _error = message;
    });
  }

  Future<bool> _saveAndClose() async {
    if (_originNames.isEmpty || _destinationNames.isEmpty) {
      _setError('Primero debes crear la matriz.');
      return false;
    }

    final originNames = _originNames.map((item) => item.text.trim()).toList();
    final destinationNames = _destinationNames
        .map((item) => item.text.trim())
        .toList();

    if (originNames.any((name) => name.isEmpty) ||
        destinationNames.any((name) => name.isEmpty)) {
      _setError('Completa todos los nombres de orígenes y destinos.');
      return false;
    }

    final costs = <List<double?>>[];
    for (var i = 0; i < _originNames.length; i++) {
      final row = <double?>[];
      for (var j = 0; j < _destinationNames.length; j++) {
        final raw = _costs[i][j].text.trim();
        if (raw.isEmpty) {
          row.add(null);
          continue;
        }
        final parsed = double.tryParse(raw);
        if (parsed == null || !parsed.isFinite || parsed < 0) {
          _setError(
            'El costo en ${originNames[i]} -> ${destinationNames[j]} debe ser un número no negativo o estar vacío (sin conexión).',
          );
          return false;
        }
        row.add(parsed);
      }
      costs.add(row);
    }

    final current = ref.read(grafoProvider);
    final input = AssignmentMatrixInput(
      originIds: _originIds,
      destinationIds: _destinationIds,
      originNames: originNames,
      destinationNames: destinationNames,
      costs: costs,
      originRole: widget.config.originRole,
      destinationRole: widget.config.destinationRole,
      defaultOriginColor: widget.config.defaultOriginColor,
      defaultDestinationColor: widget.config.defaultDestinationColor,
      costAttributeId: widget.config.costAttributeId,
      defaultTypeAlgorithm: widget.config.defaultTypeAlgorithm,
      idPrefix: widget.config.idPrefix,
    );

    final graph = AssignmentGraphMatrixService.buildGraphFromInput(
      current,
      input,
    );

    AppLogger.i(
      'AssignmentGraphMatrixScreen',
      'Matriz de Asignación procesada: ${graph.nodos.length} nodos, ${graph.conexiones.length} conexiones. Aplicando reemplazarGrafo...',
    );

    ref.read(transportationNotifierProvider.notifier).setActive(false);
    ref.read(grafoProvider.notifier).reemplazarGrafo(graph);

    setState(() {
      _isDirty = false;
      _canPop = true;
    });

    AppToast.show(
      context,
      'Matriz de asignación guardada en el lienzo.',
      icon: Icons.check_circle_rounded,
    );

    Navigator.of(context).pop();
    return true;
  }

  Future<bool> _confirmUnsavedChanges() async {
    if (!_isDirty) return true;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Descartar cambios sin guardar?'),
        content: const Text(
          'Has modificado los datos de la matriz. Si sales ahora, se perderán las ediciones.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('stay'),
            child: const Text('Seguir editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop('leave'),
            child: const Text('Descartar y salir'),
          ),
        ],
      ),
    );
    return result == 'leave';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasMatrix = _originNames.isNotEmpty && _destinationNames.isNotEmpty;

    return PopScope(
      canPop: _canPop || !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _confirmUnsavedChanges();
        if (shouldLeave && context.mounted) {
          setState(() {
            _canPop = true;
          });
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.config.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                hasMatrix
                    ? 'Edita los datos o ajusta filas/columnas'
                    : 'Ingresa las dimensiones para crear la matriz',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
          actions: [
            if (hasMatrix)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Vaciar matriz',
                  onPressed: _clearMatrix,
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              MatrixDimensionBar(
                hasMatrix: hasMatrix,
                rowCount: _realRowCount,
                columnCount: _realColCount,
                maxDimension: _maxDimension,
                rowsInputController: _originCount,
                colsInputController: _destinationCount,
                onAddRow: _addRow,
                onRemoveRow: _removeRow,
                onAddColumn: _addColumn,
                onRemoveColumn: _removeColumn,
                onApplyDimensions: _applyDimensions,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: colors.error, fontSize: 12),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    color: colors.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: colors.outlineVariant),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Center(
                        child: hasMatrix
                            ? SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: AssignmentMatrixGridTable(
                                      config: widget.config,
                                      originNames: _originNames,
                                      destinationNames: _destinationNames,
                                      originFocusNodes: _originFocusNodes,
                                      destinationFocusNodes:
                                          _destinationFocusNodes,
                                      costs: _costs,
                                      cellFocusNodes: _cellFocusNodes,
                                      originIds: _originIds,
                                      destinationIds: _destinationIds,
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.table_rows_rounded,
                                    size: 48,
                                    color: colors.onSurfaceVariant.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No hay matriz generada',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ingresa las filas y columnas arriba y presiona "Crear Matriz".',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(top: BorderSide(color: colors.outlineVariant)),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: MediaQuery.sizeOf(context).width > 600
                        ? 240
                        : double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saveAndClose,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Guardar en el lienzo'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
