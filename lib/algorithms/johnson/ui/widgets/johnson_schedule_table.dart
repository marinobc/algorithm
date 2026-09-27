import 'package:flutter/material.dart';

import '../../domain/models/johnson_models.dart';

class JohnsonScheduleTable extends StatelessWidget {
  final JohnsonResult result;

  const JohnsonScheduleTable({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tabla de Tiempos y Holguras por Nodo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.center,
          child: _buildNodeDataTable(colorScheme),
        ),
        const SizedBox(height: 24),
        Text(
          'Desglose de Conexiones / Actividades',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.center,
          child: _buildEdgeDataTable(colorScheme),
        ),
      ],
    );
  }

  Widget _buildNodeDataTable(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.8),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.5),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 24,
            horizontalMargin: 16,
            headingRowHeight: 42,
            dataRowMinHeight: 40,
            dataRowMaxHeight: 44,
            headingRowColor: WidgetStateProperty.all(
              colorScheme.surfaceContainerHigh,
            ),
            headingTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: colorScheme.primary,
            ),
            columns: const [
              DataColumn(label: Text('Nodo')),
              DataColumn(label: Text('Tiempo Temprano (ES)')),
              DataColumn(label: Text('Tiempo Tardío (LS)')),
              DataColumn(label: Text('Holgura (TS)')),
              DataColumn(label: Text('Estado')),
            ],
            rows: result.nodeResults.map((node) {
              final isCritical = node.isCritical;
              return DataRow(
                color: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (isCritical) {
                    return colorScheme.primaryContainer.withValues(alpha: 0.25);
                  }
                  return null;
                }),
                cells: [
                  DataCell(
                    Text(
                      node.nodeName,
                      style: TextStyle(
                        fontWeight: isCritical
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      node.earlyTime
                          .toStringAsFixed(2)
                          .replaceAll(RegExp(r'\.00$'), ''),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  DataCell(
                    Text(
                      node.lateTime
                          .toStringAsFixed(2)
                          .replaceAll(RegExp(r'\.00$'), ''),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  DataCell(
                    Text(
                      node.slack
                          .toStringAsFixed(2)
                          .replaceAll(RegExp(r'\.00$'), ''),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isCritical
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCritical
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isCritical
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isCritical ? 'Crítico' : 'No crítico',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isCritical
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEdgeDataTable(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.8),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.5),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 24,
            horizontalMargin: 16,
            headingRowHeight: 42,
            dataRowMinHeight: 40,
            dataRowMaxHeight: 44,
            headingRowColor: WidgetStateProperty.all(
              colorScheme.surfaceContainerHigh,
            ),
            headingTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: colorScheme.primary,
            ),
            columns: const [
              DataColumn(label: Text('Conexión (Origen -> Destino)')),
              DataColumn(label: Text('Duración / Peso')),
              DataColumn(label: Text('Estado en Ruta')),
            ],
            rows: result.edgeResults.map((edge) {
              final isCritical = edge.isCritical;
              final sourceNode = result.nodeResults.firstWhere(
                (n) => n.nodeId == edge.sourceId,
                orElse: () => JohnsonNodeResult(
                  nodeId: edge.sourceId,
                  nodeName: edge.sourceId,
                  earlyTime: 0,
                  lateTime: 0,
                  slack: 0,
                  isCritical: false,
                ),
              );
              final targetNode = result.nodeResults.firstWhere(
                (n) => n.nodeId == edge.targetId,
                orElse: () => JohnsonNodeResult(
                  nodeId: edge.targetId,
                  nodeName: edge.targetId,
                  earlyTime: 0,
                  lateTime: 0,
                  slack: 0,
                  isCritical: false,
                ),
              );

              return DataRow(
                color: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (isCritical) {
                    return colorScheme.errorContainer.withValues(alpha: 0.25);
                  }
                  return null;
                }),
                cells: [
                  DataCell(
                    Text(
                      '${sourceNode.nodeName} -> ${targetNode.nodeName}',
                      style: TextStyle(
                        fontWeight: isCritical
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      edge.duration
                          .toStringAsFixed(2)
                          .replaceAll(RegExp(r'\.00$'), ''),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isCritical
                            ? colorScheme.errorContainer
                            : colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isCritical ? 'Ruta Crítica' : 'Arista Normal',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isCritical
                              ? colorScheme.onErrorContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
