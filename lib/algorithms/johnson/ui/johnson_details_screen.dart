import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/theme/app_theme.dart';
import '../providers/johnson_provider.dart';
import 'widgets/johnson_schedule_table.dart';
import 'widgets/johnson_step_by_step_widget.dart';

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

                  // Node Early / Late / Slack & Edge DataTables
                  JohnsonScheduleTable(result: result),
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
                        _showSteps
                            ? 'Ocultar paso a paso matemático'
                            : 'Mostrar paso a paso matemático (Algoritmo de Johnson)',
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
                            child: JohnsonStepByStepWidget(result: result),
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
}
