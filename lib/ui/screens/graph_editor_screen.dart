import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../algorithms/assignment/providers/assignment_provider.dart';
import '../../algorithms/core/algorithm_registry.dart';
import '../../algorithms/core/graph_algorithm.dart';
import '../../algorithms/johnson/providers/johnson_provider.dart';
import '../../algorithms/northwest/providers/northwest_provider.dart';
import '../../application/providers/edicion_provider.dart';
import '../../application/providers/grafo_provider.dart';
import '../../domain/services/diceware_service.dart';
import '../../domain/services/graph_share_service.dart';
import '../../domain/services/graph_storage_service.dart';
import '../canvas/graph_canvas.dart';
import '../dialogs/ai_chat_dialog.dart';
import '../dialogs/algorithm_selection_dialog.dart';
import '../dialogs/config_dialog.dart';
import '../dialogs/load_graph_dialog.dart';
import '../dialogs/matrix_view_coordinator.dart';
import '../dialogs/rename_graph_dialog.dart';
import '../dialogs/tutorial_screen.dart';
import '../screens/welcome_explanation_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_toast.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final activeAlgo = ref.read(activeAlgorithmProvider);
      final grafo = ref.read(grafoProvider);
      final loadedItem = ref.read(loadedGraphItemProvider);
      if (activeAlgo == null && grafo.nodos.isEmpty && loadedItem == null) {
        AlgorithmSelectionDialog.show(context, ref);
      }
    });
  }

  void _cleanAndUnloadAll({bool preserveAlgorithm = false}) {
    ref.read(grafoProvider.notifier).limpiarGrafo();
    ref.read(loadedGraphItemProvider.notifier).setLoadedItem(null);
    if (!preserveAlgorithm) {
      ref.read(activeAlgorithmProvider.notifier).clear();
    }
    ref.read(transportationNotifierProvider.notifier).setActive(false);
    ref.read(johnsonNotifierProvider.notifier).setActive(false);
    ref.read(northwestNotifierProvider.notifier).setActive(false);
    ref.read(estadoEdicionProvider.notifier).desmarcarCambiosSinGuardar();
    ref.read(estadoEdicionProvider.notifier).deseleccionar();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _openConfigModal() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ConfigScreen()));
  }

  void _openTutorialScreen() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const TutorialScreen()));
  }

  void _openAdjacencyMatrixModal() {
    MatrixViewCoordinator.openGraphMatrix(context, ref);
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
    final rawGraph = ref.read(grafoProvider);
    final activeAlgo = ref.read(activeAlgorithmProvider);
    final graph = rawGraph.copyWith(tipoAlgoritmo: activeAlgo?.id);
    final loadedItem = ref.read(loadedGraphItemProvider);

    final graphNotifier = ref.read(grafoProvider.notifier);
    final edicionState = ref.read(estadoEdicionProvider);
    final hasUnsavedMutations =
        graphNotifier.tieneCambiosSinGuardar ||
        edicionState.tieneCambiosSinGuardar;

    if (loadedItem != null) {
      if (!hasUnsavedMutations) {
        if (mounted) {
          AppToast.show(
            context,
            'No había cambios por guardar.',
            icon: Icons.info_outline_rounded,
            duration: const Duration(seconds: 2),
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
        AppToast.show(
          context,
          'Grafo "${updatedItem.nombre}" guardado exitosamente.',
          icon: Icons.check_circle_rounded,
          duration: const Duration(seconds: 2),
        );
      }
    } else {
      final initialName = generateDicewareName();
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
        AppToast.show(
          context,
          'Grafo guardado como "${savedItem.nombre}".',
          icon: Icons.check_circle_rounded,
          duration: const Duration(seconds: 2),
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
      AppToast.show(
        context,
        'Nombre del grafo cambiado a "${updatedItem.nombre}".',
        icon: Icons.edit_rounded,
        duration: const Duration(seconds: 2),
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

      // Restore the algorithm that this graph was saved with, but keep optimization results temporal (inactive until user taps Optimizar)
      final savedAlgoId =
          loadedGraph.tipoAlgoritmo ?? selectedItem.tipoAlgoritmo;
      if (savedAlgoId != null) {
        ref.read(activeAlgorithmProvider.notifier).selectById(savedAlgoId);
      } else {
        ref.read(activeAlgorithmProvider.notifier).clear();
      }

      ref.read(transportationNotifierProvider.notifier).setActive(false);
      ref.read(johnsonNotifierProvider.notifier).setActive(false);
      ref.read(northwestNotifierProvider.notifier).setActive(false);

      ref.read(estadoEdicionProvider.notifier).desmarcarCambiosSinGuardar();
      ref.read(estadoEdicionProvider.notifier).deseleccionar();

      final currentAlgo = ref.read(activeAlgorithmProvider);
      final algoName = currentAlgo?.name ?? 'Modo Libre';
      final algoIcon = currentAlgo?.icon ?? Icons.brush_outlined;

      AppToast.show(
        context,
        'Grafo "${selectedItem.nombre}" cargado ($algoName)',
        icon: algoIcon,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _onVaciarGrafoSelected() async {
    final canProceed = await _promptUnsavedChanges(isNewGraph: true);
    if (canProceed && mounted) {
      final currentAlgo = ref.read(activeAlgorithmProvider);
      _cleanAndUnloadAll(preserveAlgorithm: currentAlgo != null);

      final algoName = currentAlgo?.shortName ?? 'Modo Libre';
      AppToast.show(
        context,
        'Lienzo vaciado ($algoName).',
        icon: Icons.delete_sweep_outlined,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _onSelectAlgorithm(String? targetAlgoId) async {
    final currentAlgo = ref.read(activeAlgorithmProvider);
    if (currentAlgo?.id == targetAlgoId ||
        (currentAlgo == null && targetAlgoId == null)) {
      return;
    }

    final grafo = ref.read(grafoProvider);
    if (grafo.nodos.isNotEmpty) {
      final canProceed = await _promptUnsavedChanges(isNewGraph: true);
      if (!canProceed || !mounted) return;

      _cleanAndUnloadAll();
    }

    if (targetAlgoId == null) {
      ref.read(activeAlgorithmProvider.notifier).clear();
    } else {
      ref.read(activeAlgorithmProvider.notifier).selectById(targetAlgoId);
    }
    ref.read(transportationNotifierProvider.notifier).setActive(false);
    ref.read(johnsonNotifierProvider.notifier).setActive(false);
    ref.read(northwestNotifierProvider.notifier).setActive(false);

    final newAlgo = ref.read(activeAlgorithmProvider);
    final algoName = newAlgo?.shortName ?? 'Modo Libre';
    final algoIcon = newAlgo?.icon ?? Icons.brush_outlined;

    if (mounted) {
      AppToast.show(
        context,
        'Modo cambiado a $algoName.',
        icon: algoIcon,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Widget _buildAlgorithmModeBadge(
    BuildContext context,
    GraphAlgorithm? activeAlgo,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isAlgoActive = activeAlgo != null;
    final badgeColor = isAlgoActive
        ? activeAlgo.themeColor
        : colorScheme.outline;
    final badgeLabel = isAlgoActive ? activeAlgo.shortName : 'Modo Libre';
    final badgeIcon = isAlgoActive ? activeAlgo.icon : Icons.brush_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: isAlgoActive ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badgeColor.withValues(alpha: isAlgoActive ? 0.6 : 0.25),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 16, color: badgeColor),
          const SizedBox(width: 6),
          Text(
            badgeLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isAlgoActive ? badgeColor : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoBack() async {
    final canProceed = await _promptUnsavedChanges();
    if (canProceed && mounted) {
      _cleanAndUnloadAll();
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WelcomeExplanationScreen()),
        );
      }
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
    final activeAlgo = ref.watch(activeAlgorithmProvider);
    final grafo = ref.watch(grafoProvider);

    final titleText = loadedItem != null
        ? '${loadedItem.nombre}${edicion.tieneCambiosSinGuardar ? " *" : ""}'
        : 'Nuevo Grafo${edicion.tieneCambiosSinGuardar ? " *" : ""}';

    final canvasControls = activeAlgo?.buildCanvasControls(context, ref);
    final emptyState = grafo.nodos.isEmpty
        ? activeAlgo?.buildEmptyState(context, ref)
        : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleGoBack();
      },
      child: Scaffold(
        backgroundColor: palette.canvasBg,
        appBar: AppBar(
          backgroundColor: colorScheme.surfaceContainerHigh,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Volver al Inicio',
            onPressed: _handleGoBack,
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
              if (loadedItem != null)
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  tooltip: 'Cambiar Nombre del Grafo',
                  onPressed: _renameCurrentGraph,
                ),
            ],
          ),
          actions: [
            _buildAlgorithmModeBadge(context, activeAlgo),
            const SizedBox(width: 8),
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
          onSelectAlgorithm: _onSelectAlgorithm,
          onOpenMatrix: _openAdjacencyMatrixModal,
          onOpenAIChat: _openAIChatModal,
          onSaveJpg: _saveGraphAsJpg,
          onOpenTutorial: _openTutorialScreen,
          onOpenConfig: _openConfigModal,
        ),
        body: Stack(
          children: [
            Positioned.fill(child: GraphCanvas(key: _canvasKey)),
            if (emptyState != null) Positioned.fill(child: emptyState),
            if (canvasControls != null)
              Positioned(top: 14, left: 14, child: canvasControls),
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
