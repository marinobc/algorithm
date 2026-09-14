import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/edicion_provider.dart';
import '../../application/providers/grafo_invalido_provider.dart';
import '../../application/providers/grafo_provider.dart';
import '../../domain/services/graph_share_service.dart';
import '../../domain/services/graph_storage_service.dart';
import '../canvas/graph_canvas.dart';
import '../dialogs/adjacency_matrix_dialog.dart';
import '../dialogs/ai_chat_dialog.dart';
import '../dialogs/config_dialog.dart';
import '../dialogs/load_graph_dialog.dart';
import '../dialogs/rename_graph_dialog.dart';
import '../dialogs/tutorial_screen.dart';
import '../screens/welcome_explanation_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/canvas_controls_fabs.dart';
import '../widgets/edit_panel.dart';
import '../widgets/floating_algorithm_card.dart';

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

  void _onCargarGraphSelected() async {
    final selectedItem = await LoadGraphDialog.show(context);
    if (selectedItem == null || !mounted) return;

    final canProceed = await _promptUnsavedChanges();
    if (canProceed && mounted) {
      final loadedGraph = GraphStorageService.importFromJson(
        selectedItem.jsonContent,
      );
      ref.read(grafoProvider.notifier).cargarGrafo(loadedGraph);
      ref.read(loadedGraphItemProvider.notifier).setLoadedItem(selectedItem);
      ref.read(estadoEdicionProvider.notifier).desmarcarCambiosSinGuardar();
      ref.read(estadoEdicionProvider.notifier).deseleccionar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Grafo "${selectedItem.nombre}" cargado.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onVaciarGrafoSelected() async {
    final canProceed = await _promptUnsavedChanges(isNewGraph: true);
    if (canProceed && mounted) {
      ref.read(grafoProvider.notifier).limpiarGrafo();
      ref.read(loadedGraphItemProvider.notifier).setLoadedItem(null);
      ref.read(estadoEdicionProvider.notifier).desmarcarCambiosSinGuardar();
      ref.read(estadoEdicionProvider.notifier).deseleccionar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Grafo vaciado.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = NeumorphicPalette.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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
            tooltip: 'Volver al Inicio',
            onPressed: () async {
              final canPop = await _promptUnsavedChanges();
              if (canPop && context.mounted) {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const WelcomeExplanationScreen(),
                    ),
                  );
                }
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
        endDrawer: AppDrawer(
          titleText: titleText,
          onVaciarGrafo: _onVaciarGrafoSelected,
          onCargarGraph: _onCargarGraphSelected,
          onSaveGraph: _saveCurrentGraph,
          onOpenMatrix: _openAdjacencyMatrixModal,
          onOpenAIChat: _openAIChatModal,
          onSaveJpg: _saveGraphAsJpg,
          onOpenTutorial: _openTutorialScreen,
          onOpenConfig: _openConfigModal,
        ),
        body: Stack(
          children: [
            Positioned.fill(child: GraphCanvas(key: _canvasKey)),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: const FloatingAlgorithmCard(),
            ),
            Positioned(
              bottom:
                  (edicion.itemSeleccionadoId != null ? 240 : 16) +
                  bottomPadding,
              right: 16,
              child: CanvasControlsFabs(
                onResetView: () {
                  _canvasKey.currentState?.centrarLienzo(preserveScale: false);
                },
              ),
            ),
            const Align(alignment: Alignment.bottomCenter, child: EditPanel()),
          ],
        ),
      ),
    );
  }
}
