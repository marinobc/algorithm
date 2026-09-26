import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/math_rich_text.dart';
import '../domain/models/johnson_models.dart';
import '../providers/johnson_provider.dart';

class JohnsonDetailsScreen extends ConsumerStatefulWidget {
  const JohnsonDetailsScreen({super.key});

  @override
  ConsumerState<JohnsonDetailsScreen> createState() =>
      _JohnsonDetailsScreenState();
}

class _JohnsonDetailsScreenState extends ConsumerState<JohnsonDetailsScreen> {
  bool _showSteps = false;

  @override
  Widget build(BuildContext context) {
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
              'Johnson / Ruta Crítica (CPM)',
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
                  Align(
                    alignment: Alignment.center,
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
                  Align(
                    alignment: Alignment.center,
                    child: _buildEdgeDataTable(result, colorScheme),
                  ),
                  const SizedBox(height: 24),

                  // Step-by-Step Toggle Button inside Solution View
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _showSteps = !_showSteps;
                        });
                      },
                      icon: Icon(
                        _showSteps
                            ? Icons.expand_less_rounded
                            : Icons.auto_awesome_rounded,
                      ),
                      label: Text(
                        _showSteps ? 'Ocultar paso a paso matemático' : 'Mostrar paso a paso matemático (Algoritmo de Johnson)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOut,
                    child: _showSteps
                        ? Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: _JohnsonStepByStep(result: result),
                          )
                        : const SizedBox.shrink(),
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

  Widget _buildEdgeDataTable(JohnsonResult result, ColorScheme colorScheme) {
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

class _JohnsonStepByStep extends StatelessWidget {
  final JohnsonResult result;

  const _JohnsonStepByStep({required this.result});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resolución Paso a Paso — Algoritmo de Johnson / CPM',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: colors.primary, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'El algoritmo realiza dos pasadas topológicas (adelante y atrás) para determinar tiempos límites y holguras.',
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 14),

        // Step 1: Forward Pass
        _buildStepCard(
          context: context,
          stepNumber: 1,
          title: 'Pasada Hacia Adelante (Tiempos Tempranos ES/EF)',
          formula: r'ES_j = \max_{(i,j)} (EF_i), \quad EF_j = ES_j + t_j',
          description: 'Comienza en el nodo inicial con ES = 0. Para cada nodo posterior j, su tiempo temprano de inicio ES_j es el máximo tiempo de finalización temprana EF de todos sus predecesores.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tiempos Tempranos Obtenidos:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.nodeResults.map((node) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colors.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '${node.nodeName}: ES=${node.earlyTime.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Step 2: Backward Pass
        _buildStepCard(
          context: context,
          stepNumber: 2,
          title: 'Pasada Hacia Atrás (Tiempos Tardíos LS/LF)',
          formula: r'LF_i = \min_{(i,j)} (LS_j), \quad LS_i = LF_i - t_i',
          description: 'Inicia desde el nodo final fijando LF igual a la duración total del proyecto. Recorre el grafo en sentido inverso fijando para cada nodo i el mínimo LS de sus sucesores.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tiempos Tardíos Obtenidos:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.nodeResults.map((node) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colors.tertiaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colors.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '${node.nodeName}: LS=${node.lateTime.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Step 3: Slacks & Critical Path
        _buildStepCard(
          context: context,
          stepNumber: 3,
          title: 'Cálculo de Holguras y Selección de Ruta Crítica',
          formula: r'TS_i = LS_i - ES_i = LF_i - EF_i = 0',
          description: 'La holgura total TS_i indica el tiempo que se puede retrasar una actividad sin demorar la fecha final del proyecto. Los nodos con TS_i = 0 forman la Ruta Crítica.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nodos en la Ruta Crítica (TS = 0):',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.nodeResults.where((n) => n.isCritical).map((
                  node,
                ) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colors.errorContainer,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colors.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '${node.nodeName} (Holgura: 0.0)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.onErrorContainer,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard({
    required BuildContext context,
    required int stepNumber,
    required String title,
    required String formula,
    required String description,
    required Widget child,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: CircleAvatar(
          radius: 15,
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          child: Text(
            '$stepNumber',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(description, style: const TextStyle(fontSize: 12)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
            ),
            child: MathRichText(
              text: r'$$' + formula + r'$$',
              baseStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
