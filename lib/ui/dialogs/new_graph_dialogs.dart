import 'package:flutter/material.dart';

import '../../domain/models/grafo.dart';
import '../../domain/services/graph_table_import_service.dart';

enum NewGraphMode { visualDesign, adjacencyMatrix }

Future<NewGraphMode?> showNewGraphModeDialog(BuildContext context) {
  return showDialog<NewGraphMode>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Crear nuevo grafo'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ModeTile(
              icon: Icons.gesture_rounded,
              title: 'Diseño visual',
              subtitle: 'Crea y conecta nodos directamente en el lienzo.',
              onTap: () => Navigator.pop(context, NewGraphMode.visualDesign),
            ),
            const SizedBox(height: 12),
            _ModeTile(
              icon: Icons.table_chart_outlined,
              title: 'Construcción desde tabla',
              subtitle: 'Define una matriz y genera automáticamente el grafo.',
              onTap: () => Navigator.pop(context, NewGraphMode.adjacencyMatrix),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    ),
  );
}

class _ModeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.primary, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

Future<Grafo?> showAdjacencyMatrixImportDialog(BuildContext context) {
  return showDialog<Grafo>(
    context: context,
    builder: (_) => const _AdjacencyMatrixImportDialog(),
  );
}

class _AdjacencyMatrixImportDialog extends StatefulWidget {
  const _AdjacencyMatrixImportDialog();

  @override
  State<_AdjacencyMatrixImportDialog> createState() =>
      _AdjacencyMatrixImportDialogState();
}

class _AdjacencyMatrixImportDialogState
    extends State<_AdjacencyMatrixImportDialog> {
  final _rowCountController = TextEditingController(text: '2');
  final _columnCountController = TextEditingController(text: '3');
  List<TextEditingController> _rowNames = [];
  List<TextEditingController> _columnNames = [];
  List<List<TextEditingController>> _cells = [];
  String? _error;
  bool _tableGenerated = false;

  @override
  void dispose() {
    _rowCountController.dispose();
    _columnCountController.dispose();
    _disposeTableControllers();
    super.dispose();
  }

  void _disposeTableControllers() {
    for (final controller in _rowNames) {
      controller.dispose();
    }
    for (final controller in _columnNames) {
      controller.dispose();
    }
    for (final row in _cells) {
      for (final controller in row) {
        controller.dispose();
      }
    }
  }

  void _generateTable() {
    final rows = int.tryParse(_rowCountController.text.trim());
    final columns = int.tryParse(_columnCountController.text.trim());
    if (rows == null || columns == null || rows < 1 || columns < 1) {
      setState(() => _error = 'Ingresa cantidades válidas mayores que cero.');
      return;
    }
    if (rows > 10 || columns > 10) {
      setState(() => _error = 'La tabla admite hasta 10 filas y 10 columnas.');
      return;
    }

    _disposeTableControllers();
    setState(() {
      _rowNames = List.generate(
        rows,
        (index) => TextEditingController(text: 'Origen ${index + 1}'),
      );
      _columnNames = List.generate(
        columns,
        (index) => TextEditingController(text: 'Destino ${index + 1}'),
      );
      _cells = List.generate(
        rows,
        (_) => List.generate(columns, (_) => TextEditingController()),
      );
      _error = null;
      _tableGenerated = true;
    });
  }

  void _createGraph() {
    try {
      final values = _cells.map((row) {
        return row.map((controller) {
          final raw = controller.text.trim().replaceAll(',', '.');
          if (raw.isEmpty || raw == '0') return null;
          final value = double.tryParse(raw);
          if (value == null) {
            throw GraphTableImportException(
              '"${controller.text}" no es un número válido.',
            );
          }
          return value;
        }).toList();
      }).toList();
      final graph = GraphTableImportService.fromCostMatrix(
        rowNames: _rowNames.map((controller) => controller.text).toList(),
        columnNames: _columnNames.map((controller) => controller.text).toList(),
        values: values,
      );
      Navigator.pop(context, graph);
    } on GraphTableImportException catch (error) {
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    return AlertDialog(
      title: const Text('Construir grafo desde una tabla'),
      content: SizedBox(
        width: width < 760 ? width * 0.88 : 720,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Indica las dimensiones de la tabla. Cada fila será un nodo de origen y cada columna un nodo de destino.',
                style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final fieldWidth = constraints.maxWidth < 520
                      ? (constraints.maxWidth - 12) / 2
                      : 170.0;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: fieldWidth,
                        child: TextField(
                          controller: _rowCountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Filas',
                            prefixIcon: Icon(Icons.table_rows_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: TextField(
                          controller: _columnCountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Columnas',
                            prefixIcon: Icon(Icons.view_column_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _generateTable,
                        icon: const Icon(Icons.grid_on_rounded),
                        label: const Text('Crear tabla'),
                      ),
                    ],
                  );
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: TextStyle(color: colors.error)),
              ],
              if (_tableGenerated) ...[
                const SizedBox(height: 20),
                Text(
                  'Edita los nombres e ingresa los costos o pesos. Usa 0 o deja vacío para omitir una conexión.',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.outlineVariant),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowHeight: 64,
                      dataRowMinHeight: 64,
                      dataRowMaxHeight: 64,
                      columns: [
                        const DataColumn(label: Text('Origen / Destino')),
                        for (final controller in _columnNames)
                          DataColumn(
                            label: _tableField(controller, isName: true),
                          ),
                      ],
                      rows: [
                        for (var row = 0; row < _rowNames.length; row++)
                          DataRow(
                            cells: [
                              DataCell(
                                _tableField(_rowNames[row], isName: true),
                              ),
                              for (
                                var column = 0;
                                column < _columnNames.length;
                                column++
                              )
                                DataCell(_tableField(_cells[row][column])),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _tableGenerated ? _createGraph : null,
          icon: const Icon(Icons.auto_fix_high_rounded),
          label: const Text('Generar grafo'),
        ),
      ],
    );
  }

  Widget _tableField(TextEditingController controller, {bool isName = false}) {
    return SizedBox(
      width: isName ? 112 : 72,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: isName
            ? TextInputType.text
            : const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          hintText: isName ? 'Nombre' : '0',
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
