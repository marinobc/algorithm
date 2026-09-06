import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/providers/edicion_provider.dart';
import 'application/providers/grafo_invalido_provider.dart';
import 'application/providers/grafo_provider.dart';
import 'application/providers/theme_provider.dart';
import 'domain/services/graph_share_service.dart';
import 'domain/services/graph_storage_service.dart';
import 'ui/canvas/graph_canvas.dart';
import 'ui/dialogs/adjacency_matrix_dialog.dart';
import 'ui/dialogs/ai_chat_dialog.dart';
import 'ui/dialogs/config_dialog.dart';
import 'ui/dialogs/rename_graph_dialog.dart';
import 'ui/dialogs/tutorial_screen.dart';
import 'ui/screens/home_library_screen.dart';
import 'ui/theme/app_theme.dart';
import 'ui/widgets/canvas_controls_fabs.dart';
import 'ui/widgets/edit_panel.dart';
import 'ui/widgets/invalid_graph_banner.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // If .env is missing or unreadable, safely continue with fallback
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Editor de Nodos y Conexiones',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const HomeLibraryScreen(),
    );
  }
}

class GraphEditorScreen extends ConsumerStatefulWidget {
  const GraphEditorScreen({super.key});

  @override
  ConsumerState<GraphEditorScreen> createState() => _GraphEditorScreenState();
}

class _GraphEditorScreenState extends ConsumerState<GraphEditorScreen> {
  final GlobalKey<GraphCanvasState> _canvasKey = GlobalKey<GraphCanvasState>();

  void _openConfigModal() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ConfigScreen()));
  }

  void _openTutorialScreen() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const TutorialScreen()));
  }

  void _openAdjacencyMatrixModal() {
    final esInvalido = ref.read(esGrafoInvalidoProvider);
    if (esInvalido) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conecta el grafo para poder ver la matriz'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AdjacencyMatrixScreen()));
  }

  void _openAIChatModal() {
    showDialog(context: context, builder: (_) => const AIChatDialog());
  }

  void _saveGraphAsJpg() {
    final graph = ref.read(grafoProvider);
    final loadedItem = ref.read(loadedGraphItemProvider);
    final graphName = loadedItem?.nombre;
    GraphShareService.showSaveJpgDialog(context, graph, graphName: graphName);
  }

  Future<bool> _promptUnsavedChanges({bool isNewGraph = false}) async {
    final graphNotifier = ref.read(grafoProvider.notifier);
    final hasUnsavedFlag = ref
        .read(estadoEdicionProvider)
        .tieneCambiosSinGuardar;
    final hasMutations = graphNotifier.tieneCambiosSinGuardar || hasUnsavedFlag;

    if (!hasMutations) return true;

    final title = isNewGraph ? 'Crear nuevo grafo' : 'Salir al Menú Principal';
    final message = isNewGraph
        ? '¿Está seguro de crear uno nuevo? Tiene cambios sin guardar.'
        : 'Tiene cambios sin guardar en este grafo. ¿Desea guardarlos antes de salir?';

    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('cancel'),
            child: const Text('Cancelar'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop('dont_save'),
            child: const Text('No Guardar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop('save'),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (choice == 'save') {
      await _saveCurrentGraph();
      return true;
    } else if (choice == 'dont_save') {
      return true;
    }
    return false;
  }

  Future<void> _saveCurrentGraph() async {
    final graph = ref.read(grafoProvider);
    final loadedItem = ref.read(loadedGraphItemProvider);

    final graphNotifier = ref.read(grafoProvider.notifier);
    final edicionState = ref.read(estadoEdicionProvider);
    final hasUnsavedMutations =
        graphNotifier.tieneCambiosSinGuardar ||
        edicionState.tieneCambiosSinGuardar;

    if (loadedItem != null) {
      if (!hasUnsavedMutations) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No había cambios por guardar.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Graph ALREADY has a name set AND has unsaved changes: save directly to slot!
      final updatedItem = await GraphStorageService.overrideSavedGraphSlot(
        loadedItem.id,
        loadedItem.nombre,
        graph,
      );
      ref.read(loadedGraphItemProvider.notifier).setLoadedItem(updatedItem);
      ref.read(grafoProvider.notifier).marcarPuntoGuardado();
      ref.read(estadoEdicionProvider.notifier).desmarcarCambiosSinGuardar();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Grafo "${updatedItem.nombre}" guardado exitosamente.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Graph HAS NO name yet: prompt for a name!
      final initialName = 'Grafo ${DateTime.now().minute}';
      final savedItem = await showGraphNameDialog(
        context,
        initialName: initialName,
        currentGraphState: graph,
      );

      if (savedItem == null) return;

      ref.read(loadedGraphItemProvider.notifier).setLoadedItem(savedItem);
      ref.read(grafoProvider.notifier).marcarPuntoGuardado();
      ref.read(estadoEdicionProvider.notifier).desmarcarCambiosSinGuardar();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Grafo guardado como "${savedItem.nombre}".'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _renameCurrentGraph() async {
    final loadedItem = ref.read(loadedGraphItemProvider);
    if (loadedItem == null) return;
    final graph = ref.read(grafoProvider);

    final updatedItem = await showGraphNameDialog(
      context,
      initialName: loadedItem.nombre,
      currentId: loadedItem.id,
      currentGraphState: graph,
    );

    if (updatedItem == null) return;

    ref.read(loadedGraphItemProvider.notifier).setLoadedItem(updatedItem);
    ref.read(grafoProvider.notifier).marcarPuntoGuardado();
    ref.read(estadoEdicionProvider.notifier).desmarcarCambiosSinGuardar();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nombre del grafo cambiado a "${updatedItem.nombre}".'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onNewGraphSelected() async {
    final canProceed = await _promptUnsavedChanges(isNewGraph: true);
    if (canProceed && mounted) {
      ref.read(grafoProvider.notifier).limpiarGrafo();
      ref.read(loadedGraphItemProvider.notifier).setLoadedItem(null);
      ref.read(estadoEdicionProvider.notifier).desmarcarCambiosSinGuardar();
      ref.read(estadoEdicionProvider.notifier).deseleccionar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nuevo lienzo creado.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _onVaciarGrafoSelected() async {
    final currentGraph = ref.read(grafoProvider);
    if (currentGraph.nodos.isEmpty && currentGraph.conexiones.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El grafo ya está vacío.'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Vaciar Grafo', style: TextStyle(color: colorScheme.error)),
        content: const Text(
          '¿Deseas vaciar todos los nodos y conexiones del grafo actual?\n\n'
          'Esta acción mantendrá el grafo en edición pero eliminará sus elementos (puedes deshacer con la opción Deshacer).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Vaciar Grafo'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ref.read(grafoProvider.notifier).vaciarGrafo();
      ref.read(estadoEdicionProvider.notifier).marcarCambioSinGuardar();
      ref.read(estadoEdicionProvider.notifier).deseleccionar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Grafo vaciado (nodos y conexiones eliminados).'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = NeumorphicPalette.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final loadedItem = ref.watch(loadedGraphItemProvider);
    final edicion = ref.watch(estadoEdicionProvider);

    final titleText = loadedItem != null
        ? '${loadedItem.nombre}${edicion.tieneCambiosSinGuardar ? " *" : ""}'
        : 'Nuevo Grafo${edicion.tieneCambiosSinGuardar ? " *" : ""}';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canPop = await _promptUnsavedChanges();
        if (canPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: palette.canvasBg,
        appBar: AppBar(
          backgroundColor: colorScheme.surfaceContainerHigh,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Volver a la Biblioteca',
            onPressed: () async {
              final canPop = await _promptUnsavedChanges();
              if (canPop && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  titleText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 16),
                tooltip: 'Cambiar Nombre del Grafo',
                onPressed: _renameCurrentGraph,
              ),
            ],
          ),
          actions: [
            // Invalid Graph Danger Icon (shows toast SnackBar on tap)
            const InvalidGraphBanner(),

            // Material 3 Lateral Menu Drawer Toggle Button
            Builder(
              builder: (menuCtx) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Menú Principal',
                onPressed: () {
                  Scaffold.of(menuCtx).openEndDrawer();
                },
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        endDrawer: Drawer(
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
                            label: Text(
                              '${ref.watch(grafoProvider).nodos.length} Nodos',
                            ),
                            avatar: Icon(
                              Icons.circle,
                              size: 12,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                              '${ref.watch(grafoProvider).conexiones.length} Aristas',
                            ),
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
                          Icons.add_box_outlined,
                          color: colorScheme.primary,
                        ),
                        title: const Text('Nuevo Grafo'),
                        onTap: () {
                          Navigator.of(context).pop();
                          _onNewGraphSelected();
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.save_outlined,
                          color: colorScheme.primary,
                        ),
                        title: const Text('Guardar Grafo'),
                        onTap: () {
                          Navigator.of(context).pop();
                          _saveCurrentGraph();
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.cleaning_services_rounded,
                          color: colorScheme.primary,
                        ),
                        title: const Text('Vaciar Grafo'),
                        onTap: () {
                          Navigator.of(context).pop();
                          _onVaciarGrafoSelected();
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
                          _openAdjacencyMatrixModal();
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
                          _openAIChatModal();
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
                          _saveGraphAsJpg();
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
                          _openTutorialScreen();
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
                          _openConfigModal();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              // 1. Interactive Canvas Background
              Positioned.fill(
                child: RepaintBoundary(child: GraphCanvas(key: _canvasKey)),
              ),

              // 2. Floating Action Controls Column (Center, Undo, Redo)
              Positioned(
                right: 16,
                bottom: 24,
                child: CanvasControlsFabs(
                  onResetView: () => _canvasKey.currentState?.centrarLienzo(),
                ),
              ),

              // 3. Edit Panel overlay
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: RepaintBoundary(child: EditPanel()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'Main App Preview', group: 'Main')
Widget mainAppPreview() {
  return const ProviderScope(child: MainApp());
}
