import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/edicion_provider.dart';
import '../../application/providers/grafo_invalido_provider.dart';
import '../../application/providers/grafo_provider.dart';
import '../../domain/services/graph_share_service.dart';
import '../../domain/services/graph_storage_service.dart';
import '../dialogs/adjacency_matrix_dialog.dart';
import '../dialogs/config_dialog.dart';
import '../dialogs/rename_graph_dialog.dart';
import '../theme/app_theme.dart';
import '../../main.dart';

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

  void _openGraphEditor([SavedGraphItem? item]) {
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
                          return _buildGraphCard(
                            context,
                            item,
                            colorScheme,
                            palette,
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
        onPressed: () => _openGraphEditor(null),
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

  Widget _buildGraphCard(
    BuildContext context,
    SavedGraphItem item,
    ColorScheme colorScheme,
    NeumorphicPalette palette,
  ) {
    final cardBgColor = colorScheme.surfaceContainerLow;

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardBgColor,
      child: InkWell(
        onTap: () => _openGraphEditor(item),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Visual Graph Image Save Thumbnail Preview Header
              Expanded(
                child: GraphThumbnailWidget(
                  item: item,
                  backgroundColor: cardBgColor,
                ),
              ),
              const SizedBox(height: 12),

              // Title & Action Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            item.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          padding: EdgeInsets.zero,
                          iconSize: 16,
                          tooltip: 'Editar nombre del grafo',
                          icon: Icon(
                            Icons.edit_rounded,
                            color: colorScheme.outline,
                          ),
                          onPressed: () => _renameGraph(item),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.filledTonal(
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: EdgeInsets.zero,
                        tooltip: 'Ver Matriz de Adyacencia',
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.secondaryContainer,
                          foregroundColor: colorScheme.onSecondaryContainer,
                        ),
                        icon: const Icon(Icons.grid_on_rounded, size: 18),
                        onPressed: () => _openGraphMatrix(item),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filledTonal(
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: EdgeInsets.zero,
                        tooltip: 'Eliminar Grafo',
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.errorContainer,
                          foregroundColor: colorScheme.onErrorContainer,
                        ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        onPressed: () => _deleteGraph(item),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Badges Row (Node & Edge Counts) + Date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 10,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${item.nodoCount} Nodos',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.alt_route_rounded,
                          size: 12,
                          color: colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${item.conexionCount} Aristas',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.fecha,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GraphThumbnailWidget extends StatefulWidget {
  final SavedGraphItem item;
  final Color backgroundColor;

  const GraphThumbnailWidget({
    super.key,
    required this.item,
    required this.backgroundColor,
  });

  @override
  State<GraphThumbnailWidget> createState() => _GraphThumbnailWidgetState();
}

class _GraphThumbnailWidgetState extends State<GraphThumbnailWidget> {
  Uint8List? _imageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrGenerateThumbnail();
  }

  @override
  void didUpdateWidget(covariant GraphThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id ||
        oldWidget.item.thumbnailBase64 != widget.item.thumbnailBase64 ||
        oldWidget.item.jsonContent != widget.item.jsonContent ||
        oldWidget.backgroundColor != widget.backgroundColor) {
      _loadOrGenerateThumbnail();
    }
  }

  void _loadOrGenerateThumbnail() {
    if (widget.item.nodoCount == 0) {
      setState(() {
        _imageBytes = null;
        _isLoading = false;
      });
      return;
    }

    if (widget.item.thumbnailBase64 != null &&
        widget.item.thumbnailBase64!.isNotEmpty) {
      try {
        final decoded = base64Decode(widget.item.thumbnailBase64!);
        setState(() {
          _imageBytes = decoded;
          _isLoading = false;
        });
        return;
      } catch (_) {}
    }

    // Legacy fallback: generate ONCE and cache
    _generateAndCacheLegacyThumbnail();
  }

  Future<void> _generateAndCacheLegacyThumbnail() async {
    setState(() => _isLoading = true);
    try {
      final graph = GraphStorageService.importFromJson(widget.item.jsonContent);
      if (graph.nodos.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final base64Str = await GraphShareService.generateThumbnailBase64(graph);
      if (base64Str != null && mounted) {
        final bytes = base64Decode(base64Str);
        setState(() {
          _imageBytes = bytes;
          _isLoading = false;
        });
        GraphStorageService.updateItemThumbnail(widget.item.id, base64Str);
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: _isLoading
          ? Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
            )
          : _imageBytes != null
          ? Image.memory(
              _imageBytes!,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              filterQuality: FilterQuality.high,
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.dashboard_customize_outlined,
                    color: colorScheme.outline.withValues(alpha: 0.5),
                    size: 32,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Lienzo Vacío',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.outline.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
