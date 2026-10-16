import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/services/sorting_set_storage_service.dart';

class SortingSetDialogs {
  static Future<String?> askName(BuildContext context) => showDialog<String>(
    context: context,
    builder: (context) {
      var name = '';
      return StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Guardar conjunto'),
          content: TextField(
            autofocus: true,
            maxLength: 40,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Nombre del conjunto'),
            onChanged: (value) => setDialogState(() => name = value),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.of(context).pop(value.trim());
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: name.trim().isEmpty
                  ? null
                  : () => Navigator.of(context).pop(name.trim()),
              child: const Text('Guardar'),
            ),
          ],
        ),
      );
    },
  );

  static Future<SavedSortingSet?> load(BuildContext context) =>
      showDialog<SavedSortingSet>(
        context: context,
        builder: (_) => const _LoadSortingSetDialog(),
      );
}

class _LoadSortingSetDialog extends StatefulWidget {
  const _LoadSortingSetDialog();

  @override
  State<_LoadSortingSetDialog> createState() => _LoadSortingSetDialogState();
}

class _LoadSortingSetDialogState extends State<_LoadSortingSetDialog> {
  List<SavedSortingSet> _sets = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final sets = await SortingSetStorageService.getSavedSets();
      if (!mounted) return;
      setState(() {
        _sets = sets;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudieron leer los conjuntos guardados.';
      });
    }
  }

  Future<void> _delete(SavedSortingSet item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar conjunto'),
        content: Text('¿Eliminar "${item.name}" de este navegador?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await SortingSetStorageService.delete(item.id);
      await _refresh();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo eliminar el conjunto.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cargar conjunto'),
      content: SizedBox(
        width: 460,
        height: math.min(400, MediaQuery.sizeOf(context).height * 0.55),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!))
            : _sets.isEmpty
            ? const Center(child: Text('Todavía no hay conjuntos guardados.'))
            : ListView.separated(
                itemCount: _sets.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _sets[index];
                  final preview = item.values.take(8).join(', ');
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: Text(item.name),
                    subtitle: Text(
                      '${item.values.length} números · $preview${item.values.length > 8 ? ', …' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      tooltip: 'Eliminar ${item.name}',
                      onPressed: () => _delete(item),
                    ),
                    onTap: () => Navigator.of(context).pop(item),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
