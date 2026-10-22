import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/bst_tree.dart';
import '../../../domain/services/bst_storage_service.dart';

class BstSavedDialogs {
  static Future<String?> askName(BuildContext context) => showDialog<String>(
    context: context,
    builder: (context) {
      var name = '';
      return StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Guardar árbol'),
          content: TextField(
            autofocus: true,
            maxLength: 40,
            decoration: const InputDecoration(labelText: 'Nombre del árbol'),
            onChanged: (value) => setDialogState(() => name = value),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) Navigator.pop(context, value.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: name.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, name.trim()),
              child: const Text('Guardar'),
            ),
          ],
        ),
      );
    },
  );

  static Future<SavedBstPractice?> load(BuildContext context) =>
      showDialog<SavedBstPractice>(
        context: context,
        builder: (_) => const _LoadBstDialog(),
      );
}

class _LoadBstDialog extends StatefulWidget {
  const _LoadBstDialog();

  @override
  State<_LoadBstDialog> createState() => _LoadBstDialogState();
}

class _LoadBstDialogState extends State<_LoadBstDialog> {
  List<SavedBstPractice> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final items = await BstStorageService.getSavedPractices();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'No se pudieron leer los árboles guardados.';
        });
      }
    }
  }

  Future<void> _delete(SavedBstPractice item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar árbol'),
        content: Text('¿Eliminar "${item.name}" de este navegador?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await BstStorageService.delete(item.id);
      await _refresh();
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo eliminar el árbol.');
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Cargar árbol'),
    content: SizedBox(
      width: 460,
      height: math.min(400, MediaQuery.sizeOf(context).height * 0.55),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _items.isEmpty
          ? const Center(child: Text('Todavía no hay árboles guardados.'))
          : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _items[index];
                final values = item.tree.traverse(BstTraversal.preorder);
                final preview = values.take(8).join(', ');
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: Text(item.name),
                  subtitle: Text(
                    '${values.length} valores · $preview${values.length > 8 ? ', …' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: 'Eliminar ${item.name}',
                    onPressed: () => _delete(item),
                  ),
                  onTap: () => Navigator.pop(context, item),
                );
              },
            ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cerrar'),
      ),
    ],
  );
}
