import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/grafo_provider.dart';
import '../../../../domain/models/atributo.dart';
import '../../../../domain/models/conexion.dart';
import '../../../../domain/models/direccion.dart';
import '../../../../domain/models/grafo.dart';
import '../../../../domain/models/nodo.dart';
import '../../../../ui/widgets/app_toast.dart';
import '../../../../ui/widgets/matrix/bipartite_matrix_config.dart';
import '../../../../ui/widgets/matrix/matrix_input_widgets.dart';
import '../domain/policy/assignment_graph_policy.dart';
import '../providers/assignment_provider.dart';

class AssignmentMatrixConfig implements BipartiteMatrixConfig {
  const AssignmentMatrixConfig();

  @override
  String get title => 'Matriz de costos de asignación';

  @override
  String get subtitle => 'Bipartita: Orígenes (Filas) × Destinos (Columnas)';

  @override
  String get originHeaderTitle => 'Origen / Destino';

  @override
  String get destinationHeaderTitle => 'Destino';

  @override
  String get originRole => AssignmentRoles.origin;

  @override
  String get destinationRole => AssignmentRoles.destination;

  @override
  int get defaultOriginColor => AssignmentRoles.originColor;

  @override
  int get defaultDestinationColor => AssignmentRoles.destinationColor;

  @override
  String get costAttributeId => 'attr_valor';

  @override
  String get costCellHint => 'Costo';

  @override
  String get defaultTypeAlgorithm => 'assignment';

  @override
  bool get hasSuppliesAndDemands => false;

  @override
  bool get hasFictitiousBalancing => false;

  @override
  String get idPrefix => 'asg';
}

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
  List<List<TextEditingController>> _costs = [];
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
      // Do not auto insert table when empty; wait for user to input dimensions
      _disposeMatrixControllers();
      _originNames = [];
      _destinationNames = [];
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
          if (attr.atributoId == widget.config.costAttributeId) {
            return attr.valor;
          }
        }
        if (conn.atributos.isNotEmpty) return conn.atributos.first.valor;
      }
    }
    return null;
  }

  void _resize(int rows, int columns, {bool isInitial = false}) {
    final oldOriginNames = _originNames;
    final oldDestinationNames = _destinationNames;
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
          : '${widget.config.idPrefix}_origin_${stamp}_$index',
    );
    _destinationIds = List.generate(
      columns,
      (index) => index < _destinationIds.length
          ? _destinationIds[index]
          : '${widget.config.idPrefix}_destination_${stamp}_$index',
    );

    setState(() {
      _originCount.text = '$rows';
      _destinationCount.text = '$columns';
      _error = null;
      if (!isInitial) _isDirty = true;
    });
  }

  String _originLabel(int index) {
    if (index < 26) return String.fromCharCode(65 + index);
    return 'O${index + 1}';
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

    final costs = <List<double>>[];
    for (var i = 0; i < _originNames.length; i++) {
      final row = <double>[];
      for (var j = 0; j < _destinationNames.length; j++) {
        final raw = _costs[i][j].text.trim();
        final parsed = double.tryParse(raw);
        if (parsed == null || !parsed.isFinite || parsed < 0) {
          _setError(
            'El costo en ${originNames[i]} -> ${destinationNames[j]} debe ser un número no negativo.',
          );
          return false;
        }
        row.add(parsed);
      }
      costs.add(row);
    }

    final current = ref.read(grafoProvider);
    final nodes = <String, Nodo>{};
    final connections = <String, Conexion>{};

    final existingConnections = <String, Conexion>{};
    for (final conn in current.conexiones.values) {
      existingConnections['${conn.nodoOrigenId}|${conn.nodoDestinoId}'] = conn;
    }

    for (var i = 0; i < _originNames.length; i++) {
      final id = _originIds[i];
      final previous = current.nodos[id];
      final pos = previous != null
          ? Offset(previous.x, previous.y)
          : _positionForNewNode(current, widget.config.originRole, i, 120);
      nodes[id] = Nodo(
        id: id,
        nombre: originNames[i],
        colorValue: previous?.colorValue ?? widget.config.defaultOriginColor,
        x: pos.dx,
        y: pos.dy,
        rol: widget.config.originRole,
      );
    }

    for (var j = 0; j < _destinationNames.length; j++) {
      final id = _destinationIds[j];
      final previous = current.nodos[id];
      final pos = previous != null
          ? Offset(previous.x, previous.y)
          : _positionForNewNode(current, widget.config.destinationRole, j, 480);
      nodes[id] = Nodo(
        id: id,
        nombre: destinationNames[j],
        colorValue:
            previous?.colorValue ?? widget.config.defaultDestinationColor,
        x: pos.dx,
        y: pos.dy,
        rol: widget.config.destinationRole,
      );
    }

    final stamp = DateTime.now().microsecondsSinceEpoch;
    for (var i = 0; i < _originNames.length; i++) {
      for (var j = 0; j < _destinationNames.length; j++) {
        final originId = _originIds[i];
        final destinationId = _destinationIds[j];
        final existing = existingConnections['$originId|$destinationId'];
        final id =
            existing?.id ?? '${widget.config.idPrefix}_conn_${stamp}_${i}_$j';
        connections[id] = Conexion(
          id: id,
          nodoOrigenId: originId,
          nodoDestinoId: destinationId,
          colorValue: existing?.colorValue ?? nodes[originId]!.colorValue,
          direccion: Direccion.unidireccional,
          atributos: [
            AtributoValor(
              atributoId: widget.config.costAttributeId,
              valor: _format(costs[i][j]),
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
      tipoAlgoritmo: widget.config.defaultTypeAlgorithm,
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
      averageX + (role == widget.config.originRole ? -180 : 180),
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
          widget.config.originHeaderTitle,
          style: TextStyle(
            color: colors.onSecondaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      ...List.generate(_destinationNames.length, (j) {
        return DataColumn(
          label: SizedBox(
            width: 80,
            child: Focus(
              child: Builder(
                builder: (context) {
                  final hasFocus = Focus.of(context).hasFocus;
                  return TextField(
                    controller: _destinationNames[j],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: colors.onSecondaryContainer,
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
                      fillColor: colors.secondaryContainer.withValues(
                        alpha: 0.5,
                      ),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onTap: () {
                      if (_destinationNames[j].text.isNotEmpty) {
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
        );
      }),
    ];

    final rows = <DataRow>[
      ...List.generate(_originNames.length, (i) {
        return DataRow(
          cells: [
            DataCell(
              SizedBox(
                width: 90,
                child: Focus(
                  child: Builder(
                    builder: (context) {
                      final hasFocus = Focus.of(context).hasFocus;
                      return TextField(
                        controller: _originNames[i],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: colors.onSurface,
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
                          fillColor: colors.secondaryContainer.withValues(
                            alpha: 0.3,
                          ),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onTap: () {
                          if (_originNames[i].text.isNotEmpty) {
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
            ...List.generate(_destinationNames.length, (j) {
              return DataCell(
                MatrixCellInput(
                  controller: _costs[i][j],
                  hint: widget.config.costCellHint,
                ),
              );
            }),
          ],
        );
      }),
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

  static String _format(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
}
