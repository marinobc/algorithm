import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../algorithms/assignment/providers/assignment_provider.dart';
import '../../algorithms/core/algorithm_registry.dart';
import '../../application/providers/grafo_invalido_provider.dart';
import '../../application/providers/grafo_provider.dart';

/// Navigation Drawer component for GraphEditorScreen.
class AppDrawer extends ConsumerWidget {
  final String titleText;
  final VoidCallback onVaciarGrafo;
  final VoidCallback onCargarGraph;
  final VoidCallback onSaveGraph;
  final ValueChanged<String?> onSelectAlgorithm;
  final VoidCallback onOpenMatrix;
  final VoidCallback onOpenAIChat;
  final VoidCallback onSaveJpg;
  final VoidCallback onOpenTutorial;
  final VoidCallback onOpenConfig;

  const AppDrawer({
    super.key,
    required this.titleText,
    required this.onVaciarGrafo,
    required this.onCargarGraph,
    required this.onSaveGraph,
    required this.onSelectAlgorithm,
    required this.onOpenMatrix,
    required this.onOpenAIChat,
    required this.onSaveJpg,
    required this.onOpenTutorial,
    required this.onOpenConfig,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final graph = ref.watch(grafoProvider);

    return Drawer(
      backgroundColor: colorScheme.surfaceContainerLow,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: colorScheme.surfaceContainerHigh,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.hub_rounded,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          titleText,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        tooltip: 'Cerrar Menú',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Chip(
                        label: Text('${graph.nodos.length} Nodos'),
                        avatar: Icon(
                          Icons.circle,
                          size: 12,
                          color: colorScheme.primary,
                        ),
                      ),
                      Chip(
                        label: Text('${graph.conexiones.length} Aristas'),
                        avatar: Icon(
                          Icons.alt_route,
                          size: 14,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.delete_sweep_outlined,
                      color: colorScheme.primary,
                    ),
                    title: const Text('Vaciar'),
                    onTap: () {
                      Navigator.of(context).pop();
                      onVaciarGrafo();
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.folder_open_rounded,
                      color: colorScheme.primary,
                    ),
                    title: const Text('Cargar'),
                    onTap: () {
                      Navigator.of(context).pop();
                      onCargarGraph();
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.save_outlined,
                      color: colorScheme.primary,
                    ),
                    title: const Text('Guardar'),
                    onTap: () {
                      Navigator.of(context).pop();
                      onSaveGraph();
                    },
                  ),
                  const Divider(),
                  _buildAlgorithmSelectorSection(context, ref),
                  const Divider(),
                  Builder(
                    builder: (context) {
                      final activeAlgo = ref.watch(activeAlgorithmProvider);
                      final supportsMatrix =
                          activeAlgo == null || activeAlgo.supportsMatrix;
                      final reason = activeAlgo?.matrixUnavailableReason;

                      // Check validity according to active mode
                      bool isGraphValid = true;
                      String? invalidReason;

                      if (activeAlgo == null) {
                        final esInvalido = ref.watch(esGrafoInvalidoProvider);
                        final g = ref.watch(grafoProvider);
                        if (g.nodos.isEmpty) {
                          isGraphValid = false;
                          invalidReason = 'Lienzo vacío';
                        } else if (esInvalido) {
                          isGraphValid = false;
                          invalidReason = 'Grafo desconectado';
                        }
                      } else if (activeAlgo.id ==
                          AlgorithmRegistry.assignmentId) {
                        final validation = ref.watch(
                          transportationValidationProvider,
                        );
                        if (!validation.isValid) {
                          isGraphValid = false;
                          invalidReason = 'Grafo no válido para asignación';
                        }
                      } else if (activeAlgo.id ==
                          AlgorithmRegistry.northwestId) {
                        final graph = ref.watch(grafoProvider);
                        if (graph.nodos.isEmpty) {
                          isGraphValid = false;
                          invalidReason = 'Lienzo vacío';
                        }
                      }

                      final isEnabled = supportsMatrix && isGraphValid;

                      String? subtitleText;
                      if (!supportsMatrix && reason != null) {
                        subtitleText =
                            'No requerida en ${activeAlgo.shortName}';
                      } else if (!isGraphValid && invalidReason != null) {
                        subtitleText = invalidReason;
                      } else if (activeAlgo?.id ==
                          AlgorithmRegistry.northwestId) {
                        subtitleText = 'Matriz del grafo';
                      } else if (activeAlgo != null) {
                        subtitleText = 'Matriz de ${activeAlgo.shortName}';
                      }

                      return ListTile(
                        enabled: isEnabled,
                        leading: Icon(
                          Icons.grid_on_rounded,
                          color: isEnabled
                              ? colorScheme.secondary
                              : colorScheme.onSurface.withValues(alpha: 0.38),
                        ),
                        title: Text(
                          'Matriz',
                          style: TextStyle(
                            color: isEnabled
                                ? null
                                : colorScheme.onSurface.withValues(alpha: 0.38),
                          ),
                        ),
                        subtitle: subtitleText != null
                            ? Text(
                                subtitleText,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isEnabled
                                      ? colorScheme.secondary
                                      : colorScheme.onSurfaceVariant.withValues(
                                          alpha: 0.7,
                                        ),
                                ),
                              )
                            : null,
                        onTap: isEnabled
                            ? () {
                                Navigator.of(context).pop();
                                onOpenMatrix();
                              }
                            : null,
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.auto_awesome,
                      color: Colors.amber,
                    ),
                    title: const Text('Asistente'),
                    onTap: () {
                      Navigator.of(context).pop();
                      onOpenAIChat();
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.save_alt_rounded,
                      color: colorScheme.secondary,
                    ),
                    title: const Text('Guardar imagen'),
                    onTap: () {
                      Navigator.of(context).pop();
                      onSaveJpg();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.help_outline_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    title: const Text('Guía de Uso'),
                    onTap: () {
                      Navigator.of(context).pop();
                      onOpenTutorial();
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.settings_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    title: const Text('Configuración'),
                    onTap: () {
                      Navigator.of(context).pop();
                      onOpenConfig();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlgorithmSelectorSection(BuildContext context, WidgetRef ref) {
    final activeAlgo = ref.watch(activeAlgorithmProvider);
    final algorithms = ref.watch(algorithmRegistryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'ALGORITMOS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              letterSpacing: 1.1,
            ),
          ),
        ),
        ListTile(
          leading: Icon(
            Icons.brush_outlined,
            color: activeAlgo == null
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          title: const Text('Modo Libre'),
          trailing: activeAlgo == null
              ? Icon(
                  Icons.check_circle_rounded,
                  color: colorScheme.primary,
                  size: 20,
                )
              : null,
          selected: activeAlgo == null,
          onTap: () {
            Navigator.of(context).pop();
            onSelectAlgorithm(null);
          },
        ),
        ...algorithms.map((algo) {
          final isSelected = activeAlgo?.id == algo.id;
          return ListTile(
            leading: Icon(
              algo.icon,
              color: isSelected
                  ? algo.themeColor
                  : colorScheme.onSurfaceVariant,
            ),
            title: Text(algo.name),
            trailing: isSelected
                ? Icon(
                    Icons.check_circle_rounded,
                    color: algo.themeColor,
                    size: 20,
                  )
                : null,
            selected: isSelected,
            onTap: () {
              Navigator.of(context).pop();
              onSelectAlgorithm(algo.id);
            },
          );
        }),
      ],
    );
  }
}
