import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/grafo_provider.dart';

/// Navigation Drawer component for GraphEditorScreen.
class AppDrawer extends ConsumerWidget {
  final String titleText;
  final VoidCallback onVaciarGrafo;
  final VoidCallback onCargarGraph;
  final VoidCallback onSaveGraph;
  final VoidCallback onOpenMatrix;
  final VoidCallback onOpenAIChat;
  final VoidCallback onSaveJpg;
  final VoidCallback onOpenTutorial;
  final VoidCallback onOpenConfig;
  final VoidCallback? onGoToInicio;
  final VoidCallback? onGoToGrafos;
  final VoidCallback? onGoToAsignacion;
  final VoidCallback? onGoToJohnson;

  const AppDrawer({
    super.key,
    required this.titleText,
    required this.onVaciarGrafo,
    required this.onCargarGraph,
    required this.onSaveGraph,
    required this.onOpenMatrix,
    required this.onOpenAIChat,
    required this.onSaveJpg,
    required this.onOpenTutorial,
    required this.onOpenConfig,
    this.onGoToInicio,
    this.onGoToGrafos,
    this.onGoToAsignacion,
    this.onGoToJohnson,
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
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Chip(
                        label: Text('${graph.nodos.length} Nodos'),
                        avatar: Icon(
                          Icons.circle,
                          size: 12,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
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

                  ListTile(
                    leading: Icon(
                      Icons.grid_on_rounded,
                      color: colorScheme.secondary,
                    ),
                    title: const Text('Matriz'),
                    onTap: () {
                      Navigator.of(context).pop();
                      onOpenMatrix();
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
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 6.0,
                    ),
                    child: Text(
                      'NAVEGACIÓN PRINCIPAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  if (onGoToInicio != null)
                    ListTile(
                      leading: Icon(
                        Icons.home_outlined,
                        color: colorScheme.primary,
                      ),
                      title: const Text('1. Inicio'),
                      onTap: () {
                        Navigator.of(context).pop();
                        onGoToInicio!();
                      },
                    ),

                  if (onGoToGrafos != null)
                    ListTile(
                      leading: Icon(
                        Icons.explore_outlined,
                        color: colorScheme.primary,
                      ),
                      title: const Text('2. Grafos'),
                      onTap: () {
                        Navigator.of(context).pop();
                        onGoToGrafos!();
                      },
                    ),
                  if (onGoToAsignacion != null)
                    ListTile(
                      leading: Icon(
                        Icons.assignment_turned_in_outlined,
                        color: colorScheme.primary,
                      ),
                      title: const Text('Asignación'),
                      onTap: () {
                        Navigator.of(context).pop();
                        onGoToAsignacion!();
                      },
                    ),
                  if (onGoToJohnson != null)
                    ListTile(
                      leading: Icon(
                        Icons.alt_route_rounded,
                        color: colorScheme.primary,
                      ),
                      title: const Text('Johnson'),
                      onTap: () {
                        Navigator.of(context).pop();
                        onGoToJohnson!();
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
}
