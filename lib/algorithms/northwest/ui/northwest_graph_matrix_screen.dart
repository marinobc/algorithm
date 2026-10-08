import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/grafo_provider.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../domain/models/grafo.dart';
import '../../../../ui/widgets/app_toast.dart';
import '../../../../ui/widgets/matrix/matrix_input_widgets.dart';
import '../../../../ui/widgets/matrix/universal_matrix_preflight_coordinator.dart';
import '../domain/models/northwest_models.dart';
import '../domain/services/northwest_graph_matrix_service.dart';
import '../domain/services/northwest_problem_extractor.dart';
import '../providers/northwest_provider.dart';
import 'config/northwest_matrix_config.dart';
import 'widgets/northwest_matrix_grid_table.dart';

class NorthwestGraphMatrixScreen extends ConsumerStatefulWidget {
  const NorthwestGraphMatrixScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NorthwestGraphMatrixScreen()),
    );
  }

  @override
  ConsumerState<NorthwestGraphMatrixScreen> createState() =>
      _NorthwestGraphMatrixScreenState();
}

class _NorthwestGraphMatrixScreenState
    extends ConsumerState<NorthwestGraphMatrixScreen> {
  static const int _maxDimension = 12;
  static const _dummyOriginId = 'nw_dummy_origin';
  static const _dummyDestinationId = 'nw_dummy_destination';

  final _originCount = TextEditingController(text: '3');
  final _destinationCount = TextEditingController(text: '4');
  final _matrixScrollController = ScrollController();

  List<TextEditingController> _originNames = [];
  List<TextEditingController> _destinationNames = [];
  List<FocusNode> _originFocusNodes = [];
  List<FocusNode> _destinationFocusNodes = [];
  List<TextEditingController> _supplies = [];
  List<TextEditingController> _demands = [];
  List<FocusNode> _supplyFocusNodes = [];
  List<FocusNode> _demandFocusNodes = [];
  List<List<TextEditingController>> _costs = [];
  List<List<FocusNode>> _cellFocusNodes = [];
  List<String> _originIds = [];
  List<String> _destinationIds = [];

  final TransportationObjective _objective = TransportationObjective.minimize;
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
    for (final fn in _originFocusNodes) {
      fn.dispose();
    }
    for (final fn in _destinationFocusNodes) {
      fn.dispose();
    }
    for (final fn in _supplyFocusNodes) {
      fn.dispose();
    }
    for (final fn in _demandFocusNodes) {
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

  void _onSupplyDemandChanged() {
    _markDirty();
    _updatePreflightBalancing();
  }

  TextEditingController _createController(
    String value, {
    bool isQuantity = false,
  }) {
    final controller = TextEditingController(text: value);
    controller.addListener(isQuantity ? _onSupplyDemandChanged : _markDirty);
    return controller;
  }

  static const NorthwestMatrixConfig _config = NorthwestMatrixConfig();

  int get _realRowCount =>
      _originIds.where((id) => !id.contains('_dummy_')).length;
  int get _realColCount =>
      _destinationIds.where((id) => !id.contains('_dummy_')).length;

  bool _isOriginFictitious(int i) =>
      i < 0 ||
      i >= _originIds.length ||
      _originIds[i].contains('_dummy_') ||
      _originNames[i].text.trim().toLowerCase().startsWith('ficticio');

  bool _isDestFictitious(int j) =>
      j < 0 ||
      j >= _destinationIds.length ||
      _destinationIds[j].contains('_dummy_') ||
      _destinationNames[j].text.trim().toLowerCase().startsWith('ficticio');

  bool _isCellFictitious(int i, int j) =>
      _isOriginFictitious(i) || _isDestFictitious(j);

  void _updatePreflightBalancing() {
    // Collect real supply and demand values
    final realSupplyList = <double?>[];
    for (var i = 0; i < _originIds.length; i++) {
      if (!_originIds[i].contains('_dummy_')) {
        final val = double.tryParse(_supplies[i].text.trim());
        realSupplyList.add(val);
      }
    }
    final realDemandList = <double?>[];
    for (var j = 0; j < _destinationIds.length; j++) {
      if (!_destinationIds[j].contains('_dummy_')) {
        final val = double.tryParse(_demands[j].text.trim());
        realDemandList.add(val);
      }
    }

    final realOriginIndices = <int>[];
    for (var i = 0; i < _originIds.length; i++) {
      if (!_originIds[i].contains('_dummy_')) realOriginIndices.add(i);
    }
    final realDestIndices = <int>[];
    for (var j = 0; j < _destinationIds.length; j++) {
      if (!_destinationIds[j].contains('_dummy_')) realDestIndices.add(j);
    }

    final rawOriginNames = realOriginIndices
        .map((i) => _originNames[i].text)
        .toList();
    final rawDestinationNames = realDestIndices
        .map((j) => _destinationNames[j].text)
        .toList();
    final rawOriginIds = realOriginIndices.map((i) => _originIds[i]).toList();
    final rawDestinationIds = realDestIndices
        .map((j) => _destinationIds[j])
        .toList();

    final preflight = UniversalMatrixPreflightCoordinator.calculateBalancing(
      config: _config,
      realOriginIds: rawOriginIds,
      realOriginNames: rawOriginNames,
      realDestinationIds: rawDestinationIds,
      realDestinationNames: rawDestinationNames,
      supplies: realSupplyList,
      demands: realDemandList,
    );

    _applyPreflightResult(preflight, realOriginIndices, realDestIndices);
  }

  void _applyPreflightResult(
    MatrixPreflightResult preflight,
    List<int> realOriginIndices,
    List<int> realDestIndices,
  ) {
    final oldOriginNames = _originNames;
    final oldDestinationNames = _destinationNames;
    final oldSupplies = _supplies;
    final oldDemands = _demands;
    final oldCosts = _costs;
    final oldOriginFocusNodes = _originFocusNodes;
    final oldDestinationFocusNodes = _destinationFocusNodes;
    final oldSupplyFocusNodes = _supplyFocusNodes;
    final oldDemandFocusNodes = _demandFocusNodes;
    final oldCellFocusNodes = _cellFocusNodes;

    // Track active focus node before preflight rebuild
    FocusNode? activeFocusNode;
    for (final fn in [
      ...oldOriginFocusNodes,
      ...oldDestinationFocusNodes,
      ...oldSupplyFocusNodes,
      ...oldDemandFocusNodes,
      ...oldCellFocusNodes.expand((r) => r),
    ]) {
      if (fn.hasFocus) {
        activeFocusNode = fn;
        break;
      }
    }

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

    _supplies = List.generate(totalRows, (i) {
      if (_originIds[i].contains('_dummy_')) {
        return _createController(
          preflight.supplyDemandDifference != null
              ? _formatOptional(preflight.supplyDemandDifference!.abs())
              : '0',
          isQuantity: true,
        );
      }
      final realIdx = i < realOriginIndices.length ? realOriginIndices[i] : -1;
      return realIdx >= 0 && realIdx < oldSupplies.length
          ? oldSupplies[realIdx]
          : _createController('', isQuantity: true);
    });

    _demands = List.generate(totalCols, (j) {
      if (_destinationIds[j].contains('_dummy_')) {
        return _createController(
          preflight.supplyDemandDifference != null
              ? _formatOptional(preflight.supplyDemandDifference!.abs())
              : '0',
          isQuantity: true,
        );
      }
      final realIdx = j < realDestIndices.length ? realDestIndices[j] : -1;
      return realIdx >= 0 && realIdx < oldDemands.length
          ? oldDemands[realIdx]
          : _createController('', isQuantity: true);
    });

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
    _supplyFocusNodes = List.generate(
      totalRows,
      (i) =>
          i < realOriginIndices.length &&
              realOriginIndices[i] < oldSupplyFocusNodes.length
          ? oldSupplyFocusNodes[realOriginIndices[i]]
          : FocusNode(),
    );
    _demandFocusNodes = List.generate(
      totalCols,
      (j) =>
          j < realDestIndices.length &&
              realDestIndices[j] < oldDemandFocusNodes.length
          ? oldDemandFocusNodes[realDestIndices[j]]
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
        return _createController('');
      }),
    );

    _cellFocusNodes = List.generate(
      totalRows,
      (i) => List.generate(totalCols, (j) {
        final oldRowIdx = i < realOriginIndices.length
            ? realOriginIndices[i]
            : -1;
        final oldColIdx = j < realDestIndices.length ? realDestIndices[j] : -1;
        if (oldRowIdx >= 0 &&
            oldColIdx >= 0 &&
            oldRowIdx < oldCellFocusNodes.length &&
            oldColIdx < oldCellFocusNodes[oldRowIdx].length) {
          return oldCellFocusNodes[oldRowIdx][oldColIdx];
        }
        return FocusNode();
      }),
    );

    // Dispose controllers and FocusNodes no longer referenced (avoids memory leaks from fictitious rows)
    final keptOriginNames = _originNames.toSet();
    for (final ctrl in oldOriginNames) {
      if (!keptOriginNames.contains(ctrl)) ctrl.dispose();
    }
    final keptDestNames = _destinationNames.toSet();
    for (final ctrl in oldDestinationNames) {
      if (!keptDestNames.contains(ctrl)) ctrl.dispose();
    }
    final keptSupplies = _supplies.toSet();
    for (final ctrl in oldSupplies) {
      if (!keptSupplies.contains(ctrl)) ctrl.dispose();
    }
    final keptDemands = _demands.toSet();
    for (final ctrl in oldDemands) {
      if (!keptDemands.contains(ctrl)) ctrl.dispose();
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
    final keptSupplyFn = _supplyFocusNodes.toSet();
    for (final fn in oldSupplyFocusNodes) {
      if (!keptSupplyFn.contains(fn)) fn.dispose();
    }
    final keptDemandFn = _demandFocusNodes.toSet();
    for (final fn in oldDemandFocusNodes) {
      if (!keptDemandFn.contains(fn)) fn.dispose();
    }
    final keptCellFn = _cellFocusNodes.expand((r) => r).toSet();
    for (final fn in oldCellFocusNodes.expand((r) => r)) {
      if (!keptCellFn.contains(fn)) fn.dispose();
    }

    setState(() {});
    if (activeFocusNode != null && activeFocusNode.canRequestFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (activeFocusNode != null && activeFocusNode.canRequestFocus) {
          activeFocusNode.requestFocus();
        }
      });
    }
  }

  void _initFromGraphOrDefaults(Grafo graph) {
    final origins = graph.nodos.values
        .where(
          (node) => node.rol == NorthwestRoles.origin || node.rol == 'origen',
        )
        .toList();
    final destinations = graph.nodos.values
        .where(
          (node) =>
              node.rol == NorthwestRoles.destination || node.rol == 'destino',
        )
        .toList();

    if (origins.isNotEmpty && destinations.isNotEmpty) {
      _originCount.text = '${origins.length}';
      _destinationCount.text = '${destinations.length}';

      final realOriginIds = origins.map((n) => n.id).toList();
      final realOriginNames = origins.map((n) => n.nombre ?? n.id).toList();
      final realDestinationIds = destinations.map((n) => n.id).toList();
      final realDestinationNames = destinations
          .map((n) => n.nombre ?? n.id)
          .toList();
      final realSupplies = origins.map((n) => n.cantidad).toList();
      final realDemands = destinations.map((n) => n.cantidad).toList();

      final preflight = UniversalMatrixPreflightCoordinator.calculateBalancing(
        config: _config,
        realOriginIds: realOriginIds,
        realOriginNames: realOriginNames,
        realDestinationIds: realDestinationIds,
        realDestinationNames: realDestinationNames,
        supplies: realSupplies,
        demands: realDemands,
      );

      final totalRows = preflight.originNames.length;
      final totalCols = preflight.destinationNames.length;

      _originIds = preflight.originIds;
      _destinationIds = preflight.destinationIds;
      _originNames = preflight.originNames
          .map((n) => _createController(n))
          .toList();
      _destinationNames = preflight.destinationNames
          .map((n) => _createController(n))
          .toList();

      _originFocusNodes = List.generate(totalRows, (_) => FocusNode());
      _destinationFocusNodes = List.generate(totalCols, (_) => FocusNode());

      _supplies = List.generate(totalRows, (i) {
        if (i < origins.length) {
          return _createController(
            _formatOptional(origins[i].cantidad),
            isQuantity: true,
          );
        }
        return _createController(
          preflight.supplyDemandDifference != null
              ? _formatOptional(preflight.supplyDemandDifference!)
              : '0',
          isQuantity: true,
        );
      });

      _demands = List.generate(totalCols, (j) {
        if (j < destinations.length) {
          return _createController(
            _formatOptional(destinations[j].cantidad),
            isQuantity: true,
          );
        }
        return _createController(
          preflight.supplyDemandDifference != null
              ? _formatOptional(preflight.supplyDemandDifference!)
              : '0',
          isQuantity: true,
        );
      });

      _supplyFocusNodes = List.generate(totalRows, (_) => FocusNode());
      _demandFocusNodes = List.generate(totalCols, (_) => FocusNode());

      _costs = List.generate(
        totalRows,
        (i) => List.generate(totalCols, (j) {
          if (i >= origins.length || j >= destinations.length) {
            return _createController('0');
          }
          final costStr = _findConnectionCost(
            graph,
            origins[i].id,
            destinations[j].id,
          );
          return _createController(costStr ?? '');
        }),
      );
      _cellFocusNodes = List.generate(
        totalRows,
        (i) => List.generate(totalCols, (_) => FocusNode()),
      );
    } else {
      _disposeMatrixControllers();
      _originNames = [];
      _destinationNames = [];
      _originFocusNodes = [];
      _destinationFocusNodes = [];
      _supplies = [];
      _demands = [];
      _supplyFocusNodes = [];
      _demandFocusNodes = [];
      _costs = [];
      _cellFocusNodes = [];
      _originIds = [];
      _destinationIds = [];
    }
    _isDirty = false;
  }

  String? _findConnectionCost(
    Grafo graph,
    String originId,
    String destinationId,
  ) {
    for (final conn in graph.conexiones.values) {
      if (conn.nodoOrigenId == originId &&
          conn.nodoDestinoId == destinationId) {
        for (final attr in conn.atributos) {
          if (attr.atributoId == 'attr_valor') return attr.valor;
        }
        if (conn.atributos.isNotEmpty) return conn.atributos.first.valor;
      }
    }
    return null;
  }

  void _resize(int rows, int columns, {bool isInitial = false}) {
    final realOriginIndices = <int>[];
    for (var i = 0; i < _originIds.length; i++) {
      if (!_originIds[i].contains('_dummy_')) realOriginIndices.add(i);
    }
    final realDestIndices = <int>[];
    for (var j = 0; j < _destinationIds.length; j++) {
      if (!_destinationIds[j].contains('_dummy_')) realDestIndices.add(j);
    }

    final realRowsCount = rows;
    final realColsCount = columns;

    final oldOriginNames = _originNames;
    final oldDestinationNames = _destinationNames;
    final oldSupplies = _supplies;
    final oldDemands = _demands;
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
          : 'nw_origin_${stamp}_$index',
    );
    final rawDestinationIds = List.generate(
      realColsCount,
      (index) => index < realDestIndices.length
          ? _destinationIds[realDestIndices[index]]
          : 'nw_destination_${stamp}_$index',
    );

    final rawSupplies = List.generate(
      realRowsCount,
      (index) => index < realOriginIndices.length
          ? double.tryParse(oldSupplies[realOriginIndices[index]].text.trim())
          : null,
    );
    final rawDemands = List.generate(
      realColsCount,
      (index) => index < realDestIndices.length
          ? double.tryParse(oldDemands[realDestIndices[index]].text.trim())
          : null,
    );

    final preflight = UniversalMatrixPreflightCoordinator.calculateBalancing(
      config: _config,
      realOriginIds: rawOriginIds,
      realOriginNames: rawOriginNames,
      realDestinationIds: rawDestinationIds,
      realDestinationNames: rawDestinationNames,
      supplies: rawSupplies,
      demands: rawDemands,
    );

    _applyPreflightResult(preflight, realOriginIndices, realDestIndices);

    setState(() {
      _originCount.text = '$realRowsCount';
      _destinationCount.text = '$realColsCount';
      _error = null;
      if (!isInitial) _isDirty = true;
    });
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
      _supplies = [];
      _demands = [];
      _costs = [];
      _originIds = [];
      _destinationIds = [];
      _error = null;
      _isDirty = true;
    });
  }

  String _originLabel(int index) {
    if (index < 26) return String.fromCharCode(65 + index);
    return 'O${index + 1}';
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

  TransportationInput? _readInput() {
    final originNames = _originNames.map((item) => item.text.trim()).toList();
    final destinationNames = _destinationNames
        .map((item) => item.text.trim())
        .toList();
    final names = [...originNames, ...destinationNames];

    if (names.any((name) => name.isEmpty)) {
      _setError('Completa todos los nombres de orígenes y destinos.');
      return null;
    }
    if (names.toSet().length != names.length) {
      _setError('Los nombres de orígenes y destinos deben ser únicos.');
      return null;
    }

    final supplies = _parseVector(
      _supplies,
      'disponibilidades',
      nonNegative: true,
    );
    final demands = _parseVector(_demands, 'demandas', nonNegative: true);
    if (supplies == null || demands == null) return null;

    final costs = <List<double?>>[];
    for (var i = 0; i < _costs.length; i++) {
      final row = <double?>[];
      for (var j = 0; j < _costs[i].length; j++) {
        final raw = _costs[i][j].text.trim();
        if (raw.isEmpty) {
          row.add(null);
          continue;
        }
        final parsed = double.tryParse(raw);
        if (parsed == null || !parsed.isFinite || parsed < 0) {
          _setError(
            'El costo en ${originNames[i]} -> ${destinationNames[j]} debe ser un número no negativo o estar vacío.',
          );
          return null;
        }
        row.add(parsed);
      }
      costs.add(row);
    }

    final supplyTotal = supplies.fold<double>(0, (sum, value) => sum + value);
    final demandTotal = demands.fold<double>(0, (sum, value) => sum + value);
    final originIds = List<String>.from(_originIds);
    final destinationIds = List<String>.from(_destinationIds);

    if (supplyTotal < demandTotal - 1e-9) {
      final difference = demandTotal - supplyTotal;
      originIds.add(_dummyOriginId);
      originNames.add(_uniqueName('Ficticio', names));
      supplies.add(difference);
      costs.add(List<double>.filled(demands.length, 0));
    } else if (supplyTotal > demandTotal + 1e-9) {
      final difference = supplyTotal - demandTotal;
      destinationIds.add(_dummyDestinationId);
      destinationNames.add(_uniqueName('Ficticio', names));
      demands.add(difference);
      for (final row in costs) {
        row.add(0);
      }
    }

    return TransportationInput(
      originIds: originIds,
      destinationIds: destinationIds,
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
          'Ingresa números válidos${nonNegative ? ' no negativos' : ''} en $label.',
        );
        return null;
      }
      result.add(value);
    }
    return result;
  }

  String _uniqueName(String base, Iterable<String> existingNames) {
    final names = existingNames.toSet();
    if (!names.contains(base)) return base;
    var suffix = 2;
    while (names.contains('$base $suffix')) {
      suffix++;
    }
    return '$base $suffix';
  }

  void _setError(String message) => setState(() => _error = message);

  Future<bool> _saveAndClose() async {
    if (_originNames.isEmpty || _destinationNames.isEmpty) {
      _setError('Crea una matriz antes de guardar.');
      return false;
    }
    final input = _readInput();
    if (input == null) return false;

    final current = ref.read(grafoProvider);
    final graph = NorthwestGraphMatrixService.buildGraphFromInput(
      current,
      input,
    );

    AppLogger.i(
      'NorthwestGraphMatrixScreen',
      'Matriz de Transporte procesada: ${graph.nodos.length} nodos, ${graph.conexiones.length} conexiones. Aplicando reemplazarGrafo...',
    );

    ref.read(northwestNotifierProvider.notifier).setActive(false);
    ref.read(grafoProvider.notifier).reemplazarGrafo(graph);

    setState(() {
      _isDirty = false;
      _canPop = true;
    });

    AppToast.show(
      context,
      'Matriz guardada en el lienzo.',
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
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Cancelar'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: const Text('Descartar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == 'discard') {
      return true;
    } else if (result == 'save') {
      return await _saveAndClose();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasMatrix = _originNames.isNotEmpty && _destinationNames.isNotEmpty;

    return PopScope(
      canPop: !_isDirty || _canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _confirmUnsavedChanges();
        if (shouldPop && context.mounted) {
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
              const Text(
                'Matriz de costos de transporte',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                                    child: NorthwestMatrixGridTable(
                                      originNames: _originNames,
                                      destinationNames: _destinationNames,
                                      originFocusNodes: _originFocusNodes,
                                      destinationFocusNodes:
                                          _destinationFocusNodes,
                                      supplies: _supplies,
                                      demands: _demands,
                                      supplyFocusNodes: _supplyFocusNodes,
                                      demandFocusNodes: _demandFocusNodes,
                                      costs: _costs,
                                      cellFocusNodes: _cellFocusNodes,
                                      originIds: _originIds,
                                      destinationIds: _destinationIds,
                                      isOriginFictitiousFn: _isOriginFictitious,
                                      isDestFictitiousFn: _isDestFictitious,
                                      isCellFictitiousFn: _isCellFictitious,
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

  static String _formatOptional(double? value) =>
      value == null ? '' : _format(value);

  static String _format(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
}
