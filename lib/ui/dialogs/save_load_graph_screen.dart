import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/grafo_provider.dart';
import '../../domain/services/graph_storage_service.dart';

class SaveLoadGraphScreen extends ConsumerStatefulWidget {
  const SaveLoadGraphScreen({super.key});

  @override
  ConsumerState<SaveLoadGraphScreen> createState() =>
      _SaveLoadGraphScreenState();
}

class _SaveLoadGraphScreenState extends ConsumerState<SaveLoadGraphScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _jsonController = TextEditingController();

  List<SavedGraphItem> _savedGraphs = [];
  bool _isLoading = true;
  String? _jsonError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSavedList();

    final graph = ref.read(grafoProvider);
    _jsonController.text = GraphStorageService.exportToJson(graph);

    final loadedItem = ref.read(loadedGraphItemProvider);
    if (loadedItem != null) {
      _nameController.text = loadedItem.nombre;
    } else {
      final defaultNum = DateTime.now().millisecondsSinceEpoch % 1000;
      _nameController.text = 'Grafo $defaultNum';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedList() async {
    setState(() => _isLoading = true);
    final items = await GraphStorageService.getSavedGraphs();
    if (mounted) {
      setState(() {
        _savedGraphs = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAsNewGraph() async {
    final name = _nameController.text;
    final graph = ref.read(grafoProvider);
    final newItem = await GraphStorageService.saveGraphSlot(name, graph);
    ref.read(loadedGraphItemProvider.notifier).setLoadedItem(newItem);
    await _loadSavedList();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Grafo guardado como nuevo registro "$name" en la BD local.',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _tabController.animateTo(1); // Switch to Cargar tab
    }
  }

  Future<void> _overrideCurrentGraph(SavedGraphItem loadedItem) async {
    final name = _nameController.text;
    final graph = ref.read(grafoProvider);
    final updatedItem = await GraphStorageService.overrideSavedGraphSlot(
      loadedItem.id,
      name,
      graph,
    );
    ref.read(loadedGraphItemProvider.notifier).setLoadedItem(updatedItem);
    await _loadSavedList();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Grafo "$name" actualizado (sobrescrito) en la BD local.',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _tabController.animateTo(1); // Switch to Cargar tab
    }
  }

  Future<void> _deleteSavedGraph(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Grafo'),
        content: Text(
          '¿Estás seguro de que deseas eliminar "$name" de la BD local?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await GraphStorageService.deleteSavedGraph(id);
      if (!mounted) return;
      if (ref.read(loadedGraphItemProvider)?.id == id) {
        ref.read(loadedGraphItemProvider.notifier).setLoadedItem(null);
      }
      await _loadSavedList();
    }
  }

  void _loadGraphFromItem(SavedGraphItem item) {
    try {
      final graph = GraphStorageService.importFromJson(item.jsonContent);
      ref.read(grafoProvider.notifier).cargarGrafo(graph);
      ref.read(loadedGraphItemProvider.notifier).setLoadedItem(item);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Grafo "${item.nombre}" cargado correctamente.'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar el grafo: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _importFromJsonText() {
    setState(() => _jsonError = null);
    try {
      final graph = GraphStorageService.importFromJson(_jsonController.text);
      ref.read(grafoProvider.notifier).cargarGrafo(graph);
      ref.read(loadedGraphItemProvider.notifier).setLoadedItem(null);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Grafo importado desde JSON exitosamente.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() {
        _jsonError = 'JSON inválido: ${e.toString()}';
      });
    }
  }

  void _copyJsonToClipboard() {
    Clipboard.setData(ClipboardData(text: _jsonController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código JSON copiado al portapapeles.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final graph = ref.watch(grafoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Grafos (BD Local & JSON)'),
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              text: 'Guardar (BD)',
              icon: Icon(Icons.save_outlined, size: 20),
            ),
            Tab(
              text: 'Grafos Guardados',
              icon: Icon(Icons.storage_rounded, size: 20),
            ),
            Tab(
              text: 'Importar / Exportar JSON',
              icon: Icon(Icons.code_rounded, size: 20),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Guardar Grafo en BD Local
              _buildSaveTab(context, colorScheme, graph),

              // Tab 2: Grafos Guardados en BD Local
              _buildLoadTab(context, colorScheme),

              // Tab 3: JSON Import/Export
              _buildJsonTab(context, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveTab(
    BuildContext context,
    ColorScheme colorScheme,
    dynamic graph,
  ) {
    final loadedItem = ref.watch(loadedGraphItemProvider);

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (loadedItem != null) ...[
                Card(
                  elevation: 0,
                  color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.6),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.storage_rounded,
                          color: colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Grafo Cargado Actualmente',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Trabajando en "${loadedItem.nombre}" (Guardado: ${loadedItem.fecha})',
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del Grafo',
                  hintText: 'Ej: Grafo de Red, Mapa de Nodos...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                ),
              ),
              const SizedBox(height: 20),

              // Graph Summary Card
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.bubble_chart_outlined,
                          color: colorScheme.onPrimaryContainer,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resumen del Grafo Actual',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${graph.nodos.length} nodos • ${graph.conexiones.length} conexiones',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (loadedItem != null) ...[
                FilledButton.icon(
                  icon: const Icon(Icons.published_with_changes_rounded),
                  label: Text('Sobrescribir Registro "${loadedItem.nombre}"'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _overrideCurrentGraph(loadedItem),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add_to_photos_rounded),
                  label: const Text('Guardar como Nuevo Registro'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveAsNewGraph,
                ),
              ] else ...[
                FilledButton.icon(
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Guardar en Base de Datos Local'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveAsNewGraph,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showVersionHistoryDialog(SavedGraphItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    final versions = item.history.reversed.toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.history_rounded, color: colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Historial de Versiones: ${item.nombre}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Todas las versiones guardadas de este registro se conservan automáticamente.',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 350),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: versions.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 12),
                  itemBuilder: (ctx, i) {
                    final v = versions[i];
                    final isLatest = v.versionNumber == item.currentVersion;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isLatest
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'v${v.versionNumber}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isLatest
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      title: Text(
                        '${v.nodoCount} nodos, ${v.conexionCount} conexiones',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        v.fecha + (isLatest ? ' • (Actual)' : ''),
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: FilledButton.tonal(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          try {
                            final graph = GraphStorageService.importFromJson(
                              v.jsonContent,
                            );
                            ref.read(grafoProvider.notifier).cargarGrafo(graph);
                            ref
                                .read(loadedGraphItemProvider.notifier)
                                .setLoadedItem(item);
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Versión v${v.versionNumber} de "${item.nombre}" restaurada.',
                                ),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al restaurar versión: $e'),
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .error,
                              ),
                            );
                          }
                        },
                        child: const Text('Restaurar'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showGraphItemOptionsBottomSheet(
    BuildContext context,
    SavedGraphItem item,
    ColorScheme colorScheme,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_tree_outlined, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'v${item.currentVersion} • ${item.nodoCount} nodos • ${item.conexionCount} conexiones',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Divider(height: 24),
              ListTile(
                leading: const Icon(Icons.file_open_rounded),
                title: const Text('Cargar Grafo'),
                subtitle: const Text(
                  'Cargar este grafo en el lienzo de trabajo',
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _loadGraphFromItem(item);
                },
              ),
              if (item.history.length > 1)
                ListTile(
                  leading: const Icon(Icons.history_rounded),
                  title: const Text('Ver Historial de Versiones'),
                  subtitle: Text('${item.history.length} versiones guardadas'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showVersionHistoryDialog(item);
                  },
                ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: colorScheme.error,
                ),
                title: Text(
                  'Eliminar Grafo',
                  style: TextStyle(
                    color: colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text('Borrar este registro de la BD local'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _deleteSavedGraph(item.id, item.nombre);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadTab(BuildContext context, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_savedGraphs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 64,
              color: colorScheme.outline.withAlpha(120),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay grafos guardados en la BD Local',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Guarda tu grafo actual en la primera pestaña para almacenarlo localmente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.swipe_rounded, size: 20, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Desliza a la derecha para Cargar • Desliza a la izquierda para Eliminar • Toca para opciones',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _savedGraphs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _savedGraphs[index];
              final versionCount = item.history.isNotEmpty
                  ? item.history.length
                  : 1;

              return Dismissible(
                key: Key(item.id),
                direction: DismissDirection.horizontal,
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    _loadGraphFromItem(item);
                    return false;
                  } else if (direction == DismissDirection.endToStart) {
                    await _deleteSavedGraph(item.id, item.nombre);
                    return false;
                  }
                  return false;
                },
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 24),
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.file_open_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Cargar Grafo',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Eliminar Grafo',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ],
                  ),
                ),
                child: Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () => _showGraphItemOptionsBottomSheet(
                      context,
                      item,
                      colorScheme,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Icon(
                              Icons.account_tree_outlined,
                              color: colorScheme.onPrimaryContainer,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.nombre,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.secondaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'v${item.currentVersion}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              colorScheme.onSecondaryContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.nodoCount} nodos • ${item.conexionCount} conexiones • $versionCount versión(es)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Guardado: ${item.fecha}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildJsonTab(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_jsonError != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _jsonError!,
              style: TextStyle(
                color: colorScheme.onErrorContainer,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: TextField(
            controller: _jsonController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Código JSON del Grafo',
              hintText: 'Pega o edita el código JSON de un grafo aquí...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 20),
                label: const Text('Copiar JSON'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _copyJsonToClipboard,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.download_rounded, size: 20),
                label: const Text('Importar JSON a Lienzo'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _importFromJsonText,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
