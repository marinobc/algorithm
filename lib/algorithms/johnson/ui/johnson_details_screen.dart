import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/theme/app_theme.dart';
import '../domain/models/johnson_models.dart';
import '../providers/johnson_provider.dart';

class JohnsonDetailsScreen extends ConsumerWidget {
  const JohnsonDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(johnsonResultProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final palette = NeumorphicPalette.of(context);

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Solución de Ruta Crítica (Johnson)')),
        body: const Center(
          child: Text('No hay solución disponible para el grafo actual.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: palette.canvasBg,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerHigh,
        elevation: 1,
        title: Row(
          children: [
            Icon(Icons.timeline_rounded, color: colorScheme.primary, size: 24),
            const SizedBox(width: 10),
            const Text(
              'Johnson',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Banner Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: colorScheme.primaryContainer.withValues(alpha: 0.85),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Duración del Proyecto',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'T = ${result.totalDuration.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')}',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface.withValues(
                                    alpha: 0.9,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Nodos Críticos: ${result.criticalNodeIds.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (result.criticalPathSequence.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Text(
                              'Secuencia de la Ruta Crítica:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Responsive Wrap Flow for Critical Path sequence
                            Wrap(
                              spacing: 6,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: List.generate(
                                result.criticalPathSequence.length * 2 - 1,
                                (index) {
                                  if (index.isOdd) {
                                    return Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 16,
                                      color: colorScheme.primary,
                                    );
                                  }
                                  final nodeName =
                                      result.criticalPathSequence[index ~/ 2];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colorScheme.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      nodeName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Node Early / Late / Slack DataTable
                  Text(
                    'Tabla de Tiempos y Holguras por Nodo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildNodeDataTable(result, colorScheme),
                  ),
                  const SizedBox(height: 24),

                  // Connections & Activities Breakdown
                  Text(
                    'Desglose de Conexiones / Actividades',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildEdgesTable(result, colorScheme),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNodeDataTable(JohnsonResult result, ColorScheme colorScheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 28,
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
          DataColumn(label: Text('Tiempo Temprano (E)')),
          DataColumn(label: Text('Tiempo Tardío (L)')),
          DataColumn(label: Text('Holgura (H)')),
          DataColumn(label: Text('Estado')),
        ],
        rows: result.nodeResults.map((nr) {
          final isCritical = nr.isCritical;
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
                  nr.nodeName,
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
                  nr.earlyTime
                      .toStringAsFixed(2)
                      .replaceAll(RegExp(r'\.00$'), ''),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              DataCell(
                Text(
                  nr.lateTime
                      .toStringAsFixed(2)
                      .replaceAll(RegExp(r'\.00$'), ''),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              DataCell(
                Text(
                  nr.slack.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), ''),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isCritical
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isCritical ? colorScheme.error : null,
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
                        ? colorScheme.errorContainer
                        : colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isCritical ? 'CRÍTICO' : 'Normal',
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
    );
  }

  Widget _buildEdgesTable(JohnsonResult result, ColorScheme colorScheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 32,
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
          DataColumn(label: Text('Conexión (Origen ➔ Destino)')),
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
                  '${sourceNode.nodeName} ➔ ${targetNode.nodeName}',
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
    );
  }
}
