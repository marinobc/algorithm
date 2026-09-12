import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/edicion_provider.dart';
import '../../application/providers/grafo_invalido_provider.dart';
import '../../application/providers/grafo_provider.dart';
import '../../domain/models/grafo.dart';
import '../../domain/services/graph_storage_service.dart';
import '../dialogs/adjacency_matrix_dialog.dart';
import '../dialogs/config_dialog.dart';
import '../dialogs/new_graph_dialogs.dart';
import '../dialogs/rename_graph_dialog.dart';
import '../theme/app_theme.dart';
import '../widgets/library/graph_card_widget.dart';
import 'graph_editor_screen.dart';
import 'welcome_explanation_screen.dart';

class HomeLibraryScreen extends ConsumerStatefulWidget {
  const HomeLibraryScreen({super.key});

  @override
  ConsumerState<HomeLibraryScreen> createState() => _HomeLibraryScreenState();
}

class _HomeLibraryScreenState extends ConsumerState<HomeLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SavedGraphItem> _allGraphs = [];
  List<SavedGraphItem> _filteredGraphs = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadGraphs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGraphs() async {
    setState(() => _isLoading = true);
    final graphs = await GraphStorageService.getSavedGraphs();
    if (!mounted) return;
    setState(() {
      _allGraphs = graphs;
      _applySearch();
      _isLoading = false;
    });
  }

  void _applySearch() {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      _filteredGraphs = List.from(_allGraphs);
    } else {
      _filteredGraphs = _allGraphs
          .where((g) => g.nombre.toLowerCase().contains(query))
          .toList();
    }
  }

  void _onSearchChanged(String val) {
    setState(() {
      _searchQuery = val;
      _applySearch();
    });
  }

  void _openGraphEditor([SavedGraphItem? item, Grafo? initialGraph]) {
    if (item != null) {
      try {
        final graph = GraphStorageService.importFromJson(item.jsonContent);
        ref.read(grafoProvider.notifier).cargarGrafo(graph);
        ref.read(loadedGraphItemProvider.notifier).setLoadedItem(item);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar el grafo: $e')));
        return;
      }
    } else if (initialGraph != null) {
      ref.read(grafoProvider.notifier).cargarGrafo(initialGraph);
      ref.read(loadedGraphItemProvider.notifier).setLoadedItem(null);
    } else {
      ref.read(grafoProvider.notifier).limpiarGrafo();
      ref.read(loadedGraphItemProvider.notifier).setLoadedItem(null);
    }

    ref.read(estadoEdicionProvider.notifier).desmarcarCambiosSinGuardar();
    ref.read(estadoEdicionProvider.notifier).deseleccionar();

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const GraphEditorScreen()))
        .then((_) => _loadGraphs());
  }

  Future<void> _createNewGraph() async {
    final mode = await showNewGraphModeDialog(context);
    if (!mounted || mode == null) return;

    if (mode == NewGraphMode.visualDesign) {
      _openGraphEditor();
      return;
    }

    final graph = await showAdjacencyMatrixImportDialog(context);
    if (!mounted || graph == null) return;
    _openGraphEditor(null, graph);
  }

  void _openGraphMatrix(SavedGraphItem item) {
    try {
      final graph = GraphStorageService.importFromJson(item.jsonContent);
      ref.read(grafoProvider.notifier).cargarGrafo(graph);
      ref.read(loadedGraphItemProvider.notifier).setLoadedItem(item);
      ref.read(estadoEdicionProvider.notifier).desmarcarCambiosSinGuardar();
      ref.read(estadoEdicionProvider.notifier).deseleccionar();

      if (ref.read(esGrafoInvalidoProvider)) {
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
          .push(
            MaterialPageRoute(builder: (_) => const AdjacencyMatrixScreen()),
          )
          .then((_) => _loadGraphs());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir la matriz del grafo: $e')),
      );
    }
  }

  void _renameGraph(SavedGraphItem item) async {
    final result = await showGraphNameDialog(
      context,
      initialName: item.nombre,
      currentId: item.id,
    );
    if (result != null && mounted) {
      _loadGraphs();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Grafo renombrado a "${result.nombre}"')),
      );
    }
  }

  void _deleteGraph(SavedGraphItem item) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          'Eliminar Grafo',
          style: TextStyle(color: colorScheme.error),
        ),
        content: Text('¿Deseas eliminar permanentemente "${item.nombre}"?'),
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
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await GraphStorageService.deleteSavedGraph(item.id);
      if (!mounted) return;
      if (ref.read(loadedGraphItemProvider)?.id == item.id) {
        ref.read(loadedGraphItemProvider.notifier).setLoadedItem(null);
      }
      _loadGraphs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final palette = NeumorphicPalette.of(context);

    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = 1;
    double childAspectRatio = 1.25;

    if (width >= 1200) {
      crossAxisCount = 4;
      childAspectRatio = 1.0;
    } else if (width >= 800) {
      crossAxisCount = 3;
      childAspectRatio = 1.0;
    } else if (width >= 500) {
      crossAxisCount = 2;
      childAspectRatio = 0.95;
    }

    return Scaffold(
      backgroundColor: palette.canvasBg,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.hub_rounded, size: 28),
            SizedBox(width: 12),
            Text(
              'Biblioteca de Grafos',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: colorScheme.surfaceContainerHigh,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded),
            tooltip: 'Página Principal - Algoritmos',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const WelcomeExplanationScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configuración del Sistema',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ConfigScreen()));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: SearchBar(
                    controller: _searchController,
                    hintText: 'Buscar grafos por nombre...',
                    leading: const Icon(Icons.search),
                    trailing: _searchQuery.isNotEmpty
                        ? [
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            ),
                          ]
                        : null,
                    onChanged: _onSearchChanged,
                    elevation: WidgetStateProperty.all(1),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Hero Gallery Grid Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _allGraphs.isEmpty
                  ? _buildEmptyState(
                      context,
                      colorScheme,
                      'No tienes grafos guardados',
                      'Crea un nuevo grafo para comenzar a trabajar en el lienzo.',
                    )
                  : _filteredGraphs.isEmpty
                  ? _buildEmptyState(
                      context,
                      colorScheme,
                      'Sin resultados',
                      'No se encontraron grafos con el término "$_searchQuery".',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadGraphs,
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemCount: _filteredGraphs.length,
                        itemBuilder: (context, index) {
                          final item = _filteredGraphs[index];
                          return GraphCardWidget(
                            item: item,
                            onTap: () => _openGraphEditor(item),
                            onRename: () => _renameGraph(item),
                            onOpenMatrix: () => _openGraphMatrix(item),
                            onDelete: () => _deleteGraph(item),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_new_graph_home',
        onPressed: _createNewGraph,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo Grafo'),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme colorScheme,
    String title,
    String subtitle,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bubble_chart_outlined,
              size: 72,
              color: colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
