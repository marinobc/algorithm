import 'package:flutter/material.dart';

import '../../domain/services/graph_storage_service.dart';


/// Modal dialog for loading a saved graph slot.
class LoadGraphDialog extends StatefulWidget {
  const LoadGraphDialog({super.key});

  static Future<SavedGraphItem?> show(BuildContext context) {
    return showDialog<SavedGraphItem>(
      context: context,
      builder: (_) => const LoadGraphDialog(),
    );
  }

  @override
  State<LoadGraphDialog> createState() => _LoadGraphDialogState();
}

class _LoadGraphDialogState extends State<LoadGraphDialog> {
  List<SavedGraphItem> _savedGraphs = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSavedGraphs();
  }

  Future<void> _loadSavedGraphs() async {
    setState(() => _isLoading = true);
    final items = await GraphStorageService.getSavedGraphs();
    if (mounted) {
      setState(() {
        _savedGraphs = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteGraph(SavedGraphItem item) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Eliminar Grafo', style: TextStyle(color: colorScheme.error)),
        content: Text(
          '¿Está seguro de eliminar "${item.nombre}"?\nEsta acción no se puede deshacer.',
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
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await GraphStorageService.deleteSavedGraph(item.id);
      await _loadSavedGraphs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);

    final filteredGraphs = _savedGraphs.where((item) {
      if (_searchQuery.trim().isEmpty) return true;
      return item.nombre.toLowerCase().contains(_searchQuery.trim().toLowerCase());
    }).toList();

    return Dialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: mediaQuery.size.height * 0.80,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Icon(
                    Icons.folder_open_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cargar Grafo Guardado',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Search Bar if more than 3 saved items
            if (_savedGraphs.length > 3)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar grafo por nombre...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),

            // Main Body List
            Flexible(
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(36.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : filteredGraphs.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(36.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 48,
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _savedGraphs.isEmpty
                                      ? 'No tienes ningún grafo guardado aún.'
                                      : 'No se encontraron grafos con ese nombre.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          itemCount: filteredGraphs.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = filteredGraphs[index];
                            return Material(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => Navigator.of(context).pop(item),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // 3-step Cluster Icon (Small <5, Medium 5-9, Large 10+)
                                      GraphClusterIconWidget(
                                        nodeCount: item.nodoCount,
                                        size: 48,
                                      ),
                                      const SizedBox(width: 14),

                                      // Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.nombre,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 8,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              children: [
                                                Text(
                                                  '${item.nodoCount} Nodos • ${item.conexionCount} Aristas',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                                Text(
                                                  '• ${item.fecha}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: colorScheme.onSurfaceVariant
                                                        .withValues(alpha: 0.7),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Action Buttons
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline_rounded,
                                          color: colorScheme.error.withValues(alpha: 0.85),
                                          size: 22,
                                        ),
                                        tooltip: 'Eliminar',
                                        onPressed: () => _deleteGraph(item),
                                      ),

                                      const SizedBox(width: 4),
                                      FilledButton.icon(
                                        onPressed: () => Navigator.of(context).pop(item),
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        icon: const Icon(Icons.download_rounded, size: 16),
                                        label: const Text('Cargar'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3-step cluster image icon widget based on graph node count:
/// - < 5 nodes: 1st stage -> s.png (small cluster)
/// - 5 to 9 nodes: 2nd stage -> m.png (medium cluster)
/// - 10+ nodes: 3rd stage -> xl.png (large cluster)
class GraphClusterIconWidget extends StatelessWidget {
  final int nodeCount;
  final double size;

  const GraphClusterIconWidget({
    super.key,
    required this.nodeCount,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    String imageAsset;
    Color containerBg;

    if (nodeCount < 5) {
      // 1st stage: Small cluster (< 5 nodes)
      imageAsset = 's.png';
      containerBg = colorScheme.primaryContainer;
    } else if (nodeCount < 10) {
      // 2nd stage: Medium cluster (5 to 9 nodes)
      imageAsset = 'm.png';
      containerBg = colorScheme.secondaryContainer;
    } else {
      // 3rd stage: Large cluster (10+ nodes)
      imageAsset = 'xl.png';
      containerBg = colorScheme.tertiaryContainer;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(size * 0.12),
          child: Image.asset(
            imageAsset,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.hub_rounded,
              size: size * 0.55,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}


