import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../algorithms/assignment/domain/services/assignment_validator.dart';
import '../../algorithms/bst/ui/bst_lab_screen.dart';
import '../../algorithms/assignment/providers/assignment_provider.dart';
import '../../algorithms/core/algorithm_registry.dart';
import '../../algorithms/core/graph_algorithm.dart';
import '../../algorithms/graph_paths/ui/graph_path_colors.dart';
import '../../algorithms/johnson/domain/services/johnson_validator.dart';
import '../../algorithms/johnson/providers/johnson_provider.dart';
import '../../algorithms/northwest/domain/services/northwest_problem_extractor.dart';
import '../../algorithms/northwest/providers/northwest_provider.dart';
import '../../application/providers/grafo_provider.dart';
import '../../domain/services/base_sorting_algorithm.dart';
import '../../domain/services/graph_storage_service.dart';
import '../../domain/services/sorting_registry.dart';
import '../screens/graph_editor_screen.dart';
import '../screens/sorting_visualizer_screen.dart';
import '../screens/welcome_explanation_screen.dart';
import '../widgets/algorithm_catalog_illustration.dart';
import '../widgets/app_toast.dart';
import 'load_graph_dialog.dart';

class AlgorithmSelectionDialog extends StatelessWidget {
  final WidgetRef ref;
  final bool canDismiss;

  const AlgorithmSelectionDialog({
    super.key,
    required this.ref,
    this.canDismiss = true,
  });

  static Future<GraphAlgorithm?> show(
    BuildContext context,
    WidgetRef ref, {
    bool canDismiss = true,
  }) {
    return showDialog<GraphAlgorithm?>(
      context: context,
      barrierDismissible: canDismiss,
      builder: (_) =>
          AlgorithmSelectionDialog(ref: ref, canDismiss: canDismiss),
    );
  }

  @override
  Widget build(BuildContext context) {
    final registered = {
      for (final algorithm in ref.read(algorithmRegistryProvider))
        algorithm.id: algorithm,
    };
    final options = _options(registered);
    final colors = Theme.of(context).colorScheme;

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? 12 : 20),
      backgroundColor: colors.surface,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280, maxHeight: 780),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 28),
          child: Column(
            children: [
              _CatalogHeader(
                canDismiss: canDismiss,
                onClose: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 26),
              Expanded(
                child: _CatalogOptionsList(
                  options: options,
                  onSelect: (option) => _select(context, option),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_AlgorithmCatalogOption> _options(
    Map<String, GraphAlgorithm> registered,
  ) {
    final assignment = registered[AlgorithmRegistry.assignmentId];
    final johnson = registered[AlgorithmRegistry.johnsonId];
    final northwest = registered[AlgorithmRegistry.northwestId];
    final dijkstra = registered[AlgorithmRegistry.dijkstraId];
    final kruskal = registered[AlgorithmRegistry.kruskalId];
    return [
      const _AlgorithmCatalogOption(
        id: 'free-mode',
        title: 'Modo Libre',
        description: 'Dibuja y edita grafos libremente, sin restricciones de un algoritmo.',
        accentColor: Color(0xFF8B5CF6),
        illustration: AlgorithmCatalogIllustration.freeMode,
      ),
      if (assignment != null)
        _AlgorithmCatalogOption(
          id: assignment.id,
          title: 'Asignación',
          description:
              'Resuelve problemas de asignación mediante el Algoritmo Húngaro.',
          accentColor: const Color(0xFF258BFF),
          illustration: AlgorithmCatalogIllustration.assignment,
          algorithm: assignment,
        ),
      if (johnson != null)
        _AlgorithmCatalogOption(
          id: johnson.id,
          title: 'Johnson',
          description: 'Analiza redes de actividades, identifica la ruta crítica y calcula las holguras.',
          accentColor: const Color(0xFF00C7A5),
          illustration: AlgorithmCatalogIllustration.johnson,
          algorithm: johnson,
        ),
      if (northwest != null)
        _AlgorithmCatalogOption(
          id: northwest.id,
          title: 'Northwest',
          description: 'Resuelve problemas de transporte mediante esquina noroeste y optimización MODI.',
          accentColor: const Color(0xFFE54872),
          illustration: AlgorithmCatalogIllustration.northwest,
          algorithm: northwest,
        ),
      if (dijkstra != null)
        _AlgorithmCatalogOption(
          id: dijkstra.id,
          title: 'Dijkstra',
          description:
              'Encuentra caminos mínimos y explora caminos máximos simples.',
          accentColor: GraphPathColors.dijkstraAccent,
          illustration: AlgorithmCatalogIllustration.dijkstra,
          algorithm: dijkstra,
        ),
      if (kruskal != null)
        _AlgorithmCatalogOption(
          id: kruskal.id,
          title: 'Kruskal',
          description: 'Construye árboles de expansión mínimos y máximos.',
          accentColor: GraphPathColors.kruskalAccent,
          illustration: AlgorithmCatalogIllustration.kruskal,
          algorithm: kruskal,
        ),
      const _AlgorithmCatalogOption(
        id: 'bst',
        title: 'Árboles BST',
        description: 'Construye y recorre árboles binarios de búsqueda.',
        accentColor: Color(0xFF7461AE),
        illustration: AlgorithmCatalogIllustration.bst,
      ),
      const _AlgorithmCatalogOption(
        id: 'selection-sort',
        title: 'Selection Sort',
        description:
            'Busca el mínimo y lo intercambia hasta ordenar el conjunto.',
        accentColor: Color(0xFFFF9100),
        illustration: AlgorithmCatalogIllustration.selectionSort,
        sortingAlgorithm: SortingRegistry.selection,
      ),
      const _AlgorithmCatalogOption(
        id: 'insertion-sort',
        title: 'Insertion Sort',
        description:
            'Inserta cada elemento en una región que ya está ordenada.',
        accentColor: Color(0xFF00BFA5),
        illustration: AlgorithmCatalogIllustration.insertionSort,
        sortingAlgorithm: SortingRegistry.insertion,
      ),
      const _AlgorithmCatalogOption(
        id: 'shell-sort',
        title: 'Shell Sort',
        description: 'Ordena subsecuencias con incrementos de Knuth.',
        accentColor: Color(0xFF008C9E),
        illustration: AlgorithmCatalogIllustration.shellSort,
        sortingAlgorithm: SortingRegistry.shell,
      ),
      const _AlgorithmCatalogOption(
        id: 'merge-sort',
        title: 'Merge Sort',
        description: 'Divide el conjunto y fusiona mitades ordenadas.',
        accentColor: Color(0xFFE17237),
        illustration: AlgorithmCatalogIllustration.mergeSort,
        sortingAlgorithm: SortingRegistry.merge,
      ),
      const _AlgorithmCatalogOption(
        id: 'upcoming',
        title: 'Próximamente',
        description: 'Estamos preparando nuevos algoritmos para ampliar las herramientas disponibles.',
        accentColor: Color(0xFF756A9F),
        illustration: AlgorithmCatalogIllustration.upcoming,
        available: false,
      ),
    ];
  }

  void _select(BuildContext context, _AlgorithmCatalogOption option) {
    if (option.id == 'bst') {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const BstLabScreen()));
      return;
    }
    final sortingAlgorithm = option.sortingAlgorithm;
    if (sortingAlgorithm != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SortingVisualizerScreen(algorithm: sortingAlgorithm),
        ),
      );
      return;
    }
    if (option.id == 'free-mode') {
      ref.read(activeAlgorithmProvider.notifier).clear();
      ref.read(transportationNotifierProvider.notifier).setActive(false);
      ref.read(johnsonNotifierProvider.notifier).setActive(false);
      ref.read(northwestNotifierProvider.notifier).setActive(false);
      Navigator.of(context).pop(null);
      return;
    }
    final algorithm = option.algorithm;
    if (algorithm == null) return;
    final graph = ref.read(grafoProvider);
    if (graph.conexiones.isNotEmpty) {
      final error = switch (algorithm.id) {
        AlgorithmRegistry.assignmentId => TransportationValidator.validate(
          graph,
        ).errorMessage,
        AlgorithmRegistry.johnsonId => JohnsonValidator.validate(
          graph,
        ).errorMessage,
        AlgorithmRegistry.northwestId => NorthwestProblemExtractor.extract(
          graph,
        ).errorMessage,
        _ => null,
      };
      if (error != null) {
        AppToast.show(context, error, icon: Icons.warning_amber_rounded);
        return;
      }
    }
    ref.read(transportationNotifierProvider.notifier).setActive(false);
    ref.read(johnsonNotifierProvider.notifier).setActive(false);
    ref.read(northwestNotifierProvider.notifier).setActive(false);
    ref.read(activeAlgorithmProvider.notifier).selectById(algorithm.id);
    Navigator.of(context).pop(algorithm);
  }
}

class AlgorithmSelectionScreen extends ConsumerWidget {
  final bool openedFromEditor;
  const AlgorithmSelectionScreen({super.key, this.openedFromEditor = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registered = {
      for (final algorithm in ref.read(algorithmRegistryProvider))
        algorithm.id: algorithm,
    };
    final options = AlgorithmSelectionDialog(ref: ref)
        ._options(registered)
        .where(
          (option) =>
              !openedFromEditor ||
              (option.id != AlgorithmRegistry.dijkstraId &&
                  option.id != AlgorithmRegistry.kruskalId),
        )
        .toList();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
              child: Column(
                children: [
                  _CatalogHeader(
                    canDismiss: true,
                    onClose: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop(false);
                      } else {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const WelcomeExplanationScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 26),
                  Expanded(
                    child: _CatalogOptionsList(
                      options: options,
                      onSelect: (option) => _select(context, ref, option),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _select(
    BuildContext context,
    WidgetRef ref,
    _AlgorithmCatalogOption option,
  ) {
    if (option.id == AlgorithmRegistry.dijkstraId ||
        option.id == AlgorithmRegistry.kruskalId) {
      ref.read(activeAlgorithmProvider.notifier).selectById(option.id);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GraphEditorScreen()),
      );
      return;
    }
    if (option.id == 'bst') {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const BstLabScreen()));
      return;
    }
    final sortingAlgorithm = option.sortingAlgorithm;
    if (sortingAlgorithm != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SortingVisualizerScreen(algorithm: sortingAlgorithm),
        ),
      );
      return;
    }
    if (option.id == 'free-mode') {
      ref.read(activeAlgorithmProvider.notifier).clear();
    } else {
      final algorithm = option.algorithm;
      if (algorithm == null) return;
      ref.read(activeAlgorithmProvider.notifier).selectById(algorithm.id);
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GraphEditorScreen()),
      );
    }
  }
}

class _CatalogOptionsList extends StatefulWidget {
  final List<_AlgorithmCatalogOption> options;
  final ValueChanged<_AlgorithmCatalogOption> onSelect;

  const _CatalogOptionsList({required this.options, required this.onSelect});

  @override
  State<_CatalogOptionsList> createState() => _CatalogOptionsListState();
}

class _CatalogOptionsListState extends State<_CatalogOptionsList> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp('[áàäâ]'), 'a')
      .replaceAll(RegExp('[éèëê]'), 'e')
      .replaceAll(RegExp('[íìïî]'), 'i')
      .replaceAll(RegExp('[óòöô]'), 'o')
      .replaceAll(RegExp('[úùüû]'), 'u')
      .replaceAll('ñ', 'n');

  bool _matches(_AlgorithmCatalogOption option) {
    final query = _normalize(_query.trim());
    if (query.isEmpty) return true;

    final category = option.sortingAlgorithm != null
        ? 'ordenamiento sorting sort'
        : option.id == 'bst'
        ? 'estructura estructuras de datos arbol arboles bst'
        : option.id == 'free-mode'
        ? 'grafos libre edicion'
        : !option.available
        ? 'proximamente'
        : 'grafos';
    final searchable = _normalize(
      '${option.title} ${option.description} ${option.id} $category',
    );
    return query.split(RegExp(r'\s+')).every(searchable.contains);
  }

  Widget _categoryHeader(BuildContext context, String title) {
    final colors = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 22, 0, 12),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Divider(color: colors.outlineVariant)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final filtered = widget.options.where(_matches).toList();
    final general = filtered
        .where(
          (option) =>
              option.available &&
              option.sortingAlgorithm == null &&
              option.id != 'bst',
        )
        .toList();
    final sorting = filtered
        .where((option) => option.sortingAlgorithm != null)
        .toList();
    final structures = filtered.where((option) => option.id == 'bst').toList();
    final upcoming = filtered.where((option) => !option.available).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1040
            ? 4
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          mainAxisExtent: columns == 1 ? 280 : 300,
        );

        Widget grid(List<_AlgorithmCatalogOption> entries) => SliverGrid(
          gridDelegate: gridDelegate,
          delegate: SliverChildBuilderDelegate(
            (context, index) => _AlgorithmCatalogCard(
              option: entries[index],
              onSelect: entries[index].available
                  ? () => widget.onSelect(entries[index])
                  : null,
            ),
            childCount: entries.length,
          ),
        );

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Buscar algoritmo por nombre o descripción',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpiar búsqueda',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: colors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: colors.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: colors.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: colors.primary, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 42,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No encontramos algoritmos para «${_query.trim()}».',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              if (general.isNotEmpty) grid(general),
              if (sorting.isNotEmpty) ...[
                _categoryHeader(context, 'Ordenamiento'),
                grid(sorting),
              ],
              if (structures.isNotEmpty) ...[
                _categoryHeader(context, 'Estructuras de datos'),
                grid(structures),
              ],
              if (upcoming.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Divider(color: colors.outlineVariant),
                  ),
                ),
                grid(upcoming),
              ],
              if (_query.isNotEmpty && filtered.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      '${filtered.length} resultado${filtered.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ],
          ),
        );
      },
    );
  }
}

class _CatalogHeader extends ConsumerWidget {
  final bool canDismiss;
  final VoidCallback onClose;
  const _CatalogHeader({required this.canDismiss, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 3,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'ALGORITMOS',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Selecciona un algoritmo',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Elige el algoritmo con el que quieres trabajar.',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 15),
              ),
            ],
          ),
        ),
        FutureBuilder<List<SavedGraphItem>>(
          future: GraphStorageService.getSavedGraphs(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.folder_open_rounded, size: 18),
                label: const Text(
                  'Cargar Grafo Guardado',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final loadedItem = await LoadGraphDialog.show(context);
                  if (loadedItem != null && context.mounted) {
                    final loadedGraph = GraphStorageService.importFromJson(
                      loadedItem.jsonContent,
                    );
                    ref.read(grafoProvider.notifier).cargarGrafo(loadedGraph);
                    ref
                        .read(loadedGraphItemProvider.notifier)
                        .setLoadedItem(loadedItem);

                    final savedAlgoId =
                        loadedGraph.tipoAlgoritmo ?? loadedItem.tipoAlgoritmo;
                    if (savedAlgoId != null) {
                      ref
                          .read(activeAlgorithmProvider.notifier)
                          .selectById(savedAlgoId);
                    } else {
                      ref.read(activeAlgorithmProvider.notifier).clear();
                    }

                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop(true);
                    } else {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const GraphEditorScreen(),
                        ),
                      );
                    }
                  }
                },
              ),
            );
          },
        ),
        if (canDismiss)
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Cerrar selector de algoritmos',
          ),
      ],
    );
  }
}

class _AlgorithmCatalogCard extends StatefulWidget {
  final _AlgorithmCatalogOption option;
  final VoidCallback? onSelect;
  const _AlgorithmCatalogCard({required this.option, this.onSelect});
  @override
  State<_AlgorithmCatalogCard> createState() => _AlgorithmCatalogCardState();
}

class _AlgorithmCatalogCardState extends State<_AlgorithmCatalogCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final available = widget.option.available;
    return Semantics(
      button: available,
      enabled: available,
      label: widget.option.title,
      child: MouseRegion(
        cursor: available ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onSelect,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: available
                    ? (_hovered
                          ? widget.option.accentColor.withValues(alpha: 0.18)
                          : colors.surfaceContainerLow)
                    : colors.surfaceContainerLowest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: available
                      ? (_hovered
                            ? widget.option.accentColor
                            : colors.outlineVariant.withValues(alpha: 0.5))
                      : colors.outlineVariant.withValues(alpha: 0.2),
                  width: available && _hovered ? 1.8 : 1.0,
                ),
                boxShadow: _hovered && available
                    ? [
                        BoxShadow(
                          color: widget.option.accentColor.withValues(
                            alpha: 0.15,
                          ),
                          blurRadius: 12,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Opacity(
                      opacity: available ? 1 : .55,
                      child: AlgorithmCatalogIllustrationWidget(
                        illustration: widget.option.illustration,
                        accentColor: widget.option.accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.option.title,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (available)
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: widget.option.accentColor.withValues(
                              alpha: .25,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surface.withValues(alpha: .55),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Próximamente',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.option.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 34,
                    height: 4,
                    decoration: BoxDecoration(
                      color: widget.option.accentColor.withValues(
                        alpha: available ? 1 : .45,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlgorithmCatalogOption {
  final String id;
  final String title;
  final String description;
  final Color accentColor;
  final AlgorithmCatalogIllustration illustration;
  final bool available;
  final GraphAlgorithm? algorithm;
  final BaseSortingAlgorithm? sortingAlgorithm;
  const _AlgorithmCatalogOption({
    required this.id,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.illustration,
    this.available = true,
    this.algorithm,
    this.sortingAlgorithm,
  });
}
