import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/grafo_provider.dart';
import '../../../../domain/models/atributo.dart';
import '../../../../domain/models/conexion.dart';
import '../../../../domain/models/direccion.dart';
import '../../../../domain/models/grafo.dart';
import '../../../../domain/models/nodo.dart';
import '../../../../domain/services/graph_color_generator.dart';
import '../../../../ui/widgets/app_toast.dart';
import '../../../../ui/widgets/matrix/matrix_input_widgets.dart';
import '../domain/models/northwest_models.dart';
import '../domain/services/northwest_problem_extractor.dart';
import '../providers/northwest_provider.dart';

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
  List<TextEditingController> _supplies = [];
  List<TextEditingController> _demands = [];
  List<List<TextEditingController>> _costs = [];
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
      _originIds = origins.map((n) => n.id).toList();
      _destinationIds = destinations.map((n) => n.id).toList();

      _originNames = origins
          .map((n) => _createController(n.nombre ?? n.id))
          .toList();
      _destinationNames = destinations
          .map((n) => _createController(n.nombre ?? n.id))
          .toList();

      _supplies = origins
          .map((n) => _createController(_formatOptional(n.cantidad)))
          .toList();
      _demands = destinations
          .map((n) => _createController(_formatOptional(n.cantidad)))
          .toList();

      _costs = List.generate(
        origins.length,
        (i) => List.generate(destinations.length, (j) {
          final costStr = _findConnectionCost(
            graph,
            origins[i].id,
            destinations[j].id,
          );
          return _createController(costStr ?? '');
        }),
      );
    } else {
      // Do not auto insert table when empty; wait for user to create matrix.
      _disposeMatrixControllers();
      _originNames = [];
      _destinationNames = [];
      _supplies = [];
      _demands = [];
      _costs = [];
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
          : _createController(_originLabel(index)),
    );
    _destinationNames = List.generate(
      columns,
      (index) => index < oldDestinationNames.length
          ? oldDestinationNames[index]
          : _createController('D${index + 1}'),
    );
    _supplies = List.generate(
      rows,
      (index) =>
          index < oldSupplies.length ? oldSupplies[index] : _createController(),
    );
    _demands = List.generate(
      columns,
      (index) =>
          index < oldDemands.length ? oldDemands[index] : _createController(),
    );
    _costs = List.generate(
      rows,
      (i) => List.generate(
        columns,
        (j) => i < oldCosts.length && j < oldCosts[i].length
            ? oldCosts[i][j]
            : _createController(),
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
      _originCount.text = '$rows';
      _destinationCount.text = '$columns';
      _error = null;
      if (!isInitial) _isDirty = true;
    });
  }

  void _addRow() {
    if (_originNames.length >= _maxDimension) {
      _setError('El máximo de filas es $_maxDimension.');
      return;
    }
    _resize(_originNames.length + 1, _destinationNames.length);
  }

  void _removeRow() {
    if (_originNames.length <= 1) {
      _setError('Debe haber al menos 1 fila.');
      return;
    }
    _resize(_originNames.length - 1, _destinationNames.length);
  }

  void _addColumn() {
    if (_destinationNames.length >= _maxDimension) {
      _setError('El máximo de columnas es $_maxDimension.');
      return;
    }
    _resize(_originNames.length, _destinationNames.length + 1);
  }

  void _removeColumn() {
    if (_destinationNames.length <= 1) {
      _setError('Debe haber al menos 1 columna.');
      return;
    }
    _resize(_originNames.length, _destinationNames.length - 1);
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

    if (rows < _originNames.length || columns < _destinationNames.length) {
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

    final costs = <List<double>>[];
    for (var i = 0; i < _costs.length; i++) {
      final row = _parseVector(
        _costs[i],
        'costos de ${originNames[i]}',
        nonNegative: true,
      );
      if (row == null) return null;
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
    final nodes = <String, Nodo>{};
    final connections = <String, Conexion>{};
    final existingConnections = {
      for (final connection in current.conexiones.values)
        '${connection.nodoOrigenId}|${connection.nodoDestinoId}': connection,
    };

    for (var i = 0; i < input.rowCount; i++) {
      final id = input.originIds[i];
      final existing = current.nodos[id];
      final position = _positionForNewNode(
        current,
        NorthwestRoles.origin,
        i,
        180,
      );
      nodes[id] = Nodo(
        id: id,
        nombre: input.originNames[i],
        colorValue:
            existing?.colorValue ??
            GraphColorGenerator.generateMaximallyDistinctColor(
              Grafo(nodos: nodes),
            ),
        x: existing?.x ?? position.dx,
        y: existing?.y ?? position.dy,
        radius: existing?.radius ?? Nodo.defaultRadius,
        rol: NorthwestRoles.origin,
        cantidad: input.supplies[i],
      );
    }

    for (var j = 0; j < input.columnCount; j++) {
      final id = input.destinationIds[j];
      final existing = current.nodos[id];
      final position = _positionForNewNode(
        current,
        NorthwestRoles.destination,
        j,
        760,
      );
      nodes[id] = Nodo(
        id: id,
        nombre: input.destinationNames[j],
        colorValue:
            existing?.colorValue ??
            GraphColorGenerator.generateMaximallyDistinctColor(
              Grafo(nodos: nodes),
            ),
        x: existing?.x ?? position.dx,
        y: existing?.y ?? position.dy,
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

  Offset _positionForNewNode(
    Grafo graph,
    String role,
    int index,
    double fallbackX,
  ) {
    final roleNodes =
        graph.nodos.values.where((node) => node.rol == role).toList()
          ..sort((a, b) => a.y.compareTo(b.y));
    if (roleNodes.isNotEmpty) {
      final averageX =
          roleNodes.map((node) => node.x).reduce((a, b) => a + b) /
          roleNodes.length;
      final nextY =
          roleNodes.last.y +
          110 +
          (index - roleNodes.length).clamp(0, _maxDimension) * 110;
      return Offset(averageX, nextY);
    }
    final graphNodes = graph.nodos.values.toList();
    if (graphNodes.isEmpty) {
      return Offset(fallbackX, 120 + index * 110);
    }
    final averageX =
        graphNodes.map((node) => node.x).reduce((a, b) => a + b) /
        graphNodes.length;
    final averageY =
        graphNodes.map((node) => node.y).reduce((a, b) => a + b) /
        graphNodes.length;
    return Offset(
      averageX + (role == NorthwestRoles.origin ? -180 : 180),
      averageY + index * 110,
    );
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
                rowCount: _originNames.length,
                columnCount: _destinationNames.length,
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
                                    child: _buildMatrixTable(colors),
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

  Widget _buildMatrixTable(ColorScheme colors) {
    final columns = <DataColumn>[
      DataColumn(
        label: Text(
          'Origen / Destino',
          style: TextStyle(
            color: colors.onSecondaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      ...List.generate(_destinationNames.length, (j) {
        final name = _destinationNames[j].text.trim();
        final destId = j < _destinationIds.length ? _destinationIds[j] : '';
        final isFictitious =
            destId == _dummyDestinationId ||
            name == 'Ficticio' ||
            name.startsWith('Ficticio ');
        return DataColumn(
          label: SizedBox(
            width: 80,
            child: MouseRegion(
              cursor: isFictitious
                  ? SystemMouseCursors.forbidden
                  : SystemMouseCursors.text,
              child: Focus(
                canRequestFocus: !isFictitious,
                child: Builder(
                  builder: (context) {
                    final hasFocus = Focus.of(context).hasFocus;
                    return TextField(
                      controller: _destinationNames[j],
                      readOnly: isFictitious,
                      enabled: !isFictitious,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isFictitious
                            ? colors.onSurfaceVariant.withValues(alpha: 0.45)
                            : colors.onSecondaryContainer,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: hasFocus ? '' : 'Destino ${j + 1}',
                        hintStyle: TextStyle(
                          color: colors.onSecondaryContainer.withValues(
                            alpha: 0.38,
                          ),
                          fontSize: 11,
                          fontWeight: FontWeight.normal,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        fillColor: isFictitious
                            ? colors.surfaceContainerHighest.withValues(
                                alpha: 0.75,
                              )
                            : colors.secondaryContainer.withValues(alpha: 0.5),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colors.outlineVariant.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      onTap: () {
                        if (!isFictitious &&
                            _destinationNames[j].text.isNotEmpty) {
                          _destinationNames[j].selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: _destinationNames[j].text.length,
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      }),
      DataColumn(
        label: Text(
          'Disponibilidad (aᵢ)',
          style: TextStyle(
            color: colors.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ];

    final rows = <DataRow>[
      ...List.generate(_originNames.length, (i) {
        final originName = _originNames[i].text.trim();
        final originId = i < _originIds.length ? _originIds[i] : '';
        final isOriginFictitious =
            originId == _dummyOriginId ||
            originName == 'Ficticio' ||
            originName.startsWith('Ficticio ');
        return DataRow(
          color: isOriginFictitious
              ? WidgetStatePropertyAll(
                  colors.surfaceContainerHighest.withValues(alpha: 0.35),
                )
              : null,
          cells: [
            DataCell(
              SizedBox(
                width: 90,
                child: MouseRegion(
                  cursor: isOriginFictitious
                      ? SystemMouseCursors.forbidden
                      : SystemMouseCursors.text,
                  child: Focus(
                    canRequestFocus: !isOriginFictitious,
                    child: Builder(
                      builder: (context) {
                        final hasFocus = Focus.of(context).hasFocus;
                        return TextField(
                          controller: _originNames[i],
                          readOnly: isOriginFictitious,
                          enabled: !isOriginFictitious,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isOriginFictitious
                                ? colors.onSurfaceVariant.withValues(
                                    alpha: 0.45,
                                  )
                                : colors.onSurface,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: hasFocus ? '' : 'Origen ${i + 1}',
                            hintStyle: TextStyle(
                              color: colors.onSurfaceVariant.withValues(
                                alpha: 0.38,
                              ),
                              fontSize: 11,
                              fontWeight: FontWeight.normal,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                            fillColor: isOriginFictitious
                                ? colors.surfaceContainerHighest.withValues(
                                    alpha: 0.75,
                                  )
                                : colors.secondaryContainer.withValues(
                                    alpha: 0.3,
                                  ),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colors.outlineVariant.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                          ),
                          onTap: () {
                            if (!isOriginFictitious &&
                                _originNames[i].text.isNotEmpty) {
                              _originNames[i].selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: _originNames[i].text.length,
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            ...List.generate(_destinationNames.length, (j) {
              final destName = _destinationNames[j].text.trim();
              final destId = j < _destinationIds.length
                  ? _destinationIds[j]
                  : '';
              final isDestFictitious =
                  destId == _dummyDestinationId ||
                  destName == 'Ficticio' ||
                  destName.startsWith('Ficticio ');
              final isCellFictitious = isOriginFictitious || isDestFictitious;
              return DataCell(
                _buildCellInput(
                  controller: _costs[i][j],
                  hint: 'Costo',
                  readOnly: isCellFictitious,
                ),
              );
            }),
            DataCell(
              _buildCellInput(
                controller: _supplies[i],
                hint: 'Disp',
                isHighlight: true,
                readOnly: isOriginFictitious,
              ),
            ),
          ],
        );
      }),
      DataRow(
        color: WidgetStatePropertyAll(
          colors.primaryContainer.withValues(alpha: 0.4),
        ),
        cells: [
          DataCell(
            Text(
              'Demanda (bⱼ)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.onPrimaryContainer,
              ),
            ),
          ),
          ...List.generate(_destinationNames.length, (j) {
            final destName = _destinationNames[j].text.trim();
            final isDestFictitious =
                destName == 'Ficticio' || destName.startsWith('Ficticio ');
            return DataCell(
              _buildCellInput(
                controller: _demands[j],
                hint: 'Demanda',
                isHighlight: true,
                readOnly: isDestFictitious,
              ),
            );
          }),
          const DataCell(SizedBox.shrink()),
        ],
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DataTable(
        clipBehavior: Clip.antiAlias,
        headingRowColor: WidgetStatePropertyAll(colors.secondaryContainer),
        dataRowMaxHeight: 52,
        dataRowMinHeight: 48,
        horizontalMargin: 12,
        columnSpacing: 12,
        columns: columns,
        rows: rows,
      ),
    );
  }

  Widget _buildCellInput({
    required TextEditingController controller,
    String hint = '',
    bool isHighlight = false,
    bool readOnly = false,
  }) {
    return MatrixCellInput(
      controller: controller,
      hint: hint,
      isHighlight: isHighlight,
      readOnly: readOnly,
    );
  }

  static String _formatOptional(double? value) =>
      value == null ? '' : _format(value);

  static String _format(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
}
