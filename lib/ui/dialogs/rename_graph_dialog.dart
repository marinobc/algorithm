import 'package:flutter/material.dart';

import '../../domain/models/grafo.dart';
import '../../domain/services/graph_storage_service.dart';

Future<SavedGraphItem?> showGraphNameDialog(
  BuildContext context, {
  required String initialName,
  String? currentId,
  Grafo? currentGraphState,
}) async {
  final isEditing = currentId != null || currentGraphState != null;

  final requestedName = await showDialog<String>(
    context: context,
    builder: (ctx) =>
        _GraphNameDialogContent(initialName: initialName, isEditing: isEditing),
  );

  if (requestedName == null || requestedName.isEmpty) return null;
  if (requestedName == initialName &&
      currentId != null &&
      currentGraphState == null) {
    return null;
  }

  final items = await GraphStorageService.getSavedGraphs();
  final existingConflict = await GraphStorageService.findExistingGraphByName(
    requestedName,
    excludeId: currentId,
  );

  if (existingConflict != null) {
    final autoIncName = GraphStorageService.generateUniqueName(
      requestedName,
      items,
      excludeId: currentId,
    );
    if (!context.mounted) return null;

    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Nombre Ya Existente',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Ya existe un archivo guardado con el nombre "$requestedName".\n\n¿Desea reescribir el grafo existente o guardar con otro nombre "$autoIncName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('cancel'),
            child: const Text('Cancelar'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop('auto_inc'),
            child: Text('Guardar como "$autoIncName"'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop('overwrite'),
            child: const Text('Reescribir'),
          ),
        ],
      ),
    );

    if (action == 'cancel' || action == null) return null;

    if (action == 'overwrite') {
      if (currentGraphState != null) {
        return await GraphStorageService.overrideSavedGraphSlot(
          existingConflict.id,
          requestedName,
          currentGraphState,
        );
      } else if (currentId != null) {
        return await GraphStorageService.renameSavedGraphSlot(
          currentId,
          requestedName,
        );
      }
    } else if (action == 'auto_inc') {
      if (currentGraphState != null) {
        if (currentId != null) {
          return await GraphStorageService.overrideSavedGraphSlot(
            currentId,
            autoIncName,
            currentGraphState,
          );
        } else {
          return await GraphStorageService.saveGraphSlot(
            autoIncName,
            currentGraphState,
          );
        }
      } else if (currentId != null) {
        return await GraphStorageService.renameSavedGraphSlot(
          currentId,
          autoIncName,
        );
      }
    }
    return null;
  } else {
    if (currentGraphState != null) {
      if (currentId != null) {
        return await GraphStorageService.overrideSavedGraphSlot(
          currentId,
          requestedName,
          currentGraphState,
        );
      } else {
        return await GraphStorageService.saveGraphSlot(
          requestedName,
          currentGraphState,
        );
      }
    } else if (currentId != null) {
      return await GraphStorageService.renameSavedGraphSlot(
        currentId,
        requestedName,
      );
    }
    return null;
  }
}

class _GraphNameDialogContent extends StatefulWidget {
  final String initialName;
  final bool isEditing;

  const _GraphNameDialogContent({
    required this.initialName,
    required this.isEditing,
  });

  @override
  State<_GraphNameDialogContent> createState() =>
      _GraphNameDialogContentState();
}

class _GraphNameDialogContentState extends State<_GraphNameDialogContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(_controller.text.trim());
  }

  void _cancel() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.isEditing ? 'Renombrar Grafo' : 'Guardar Grafo'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        onTap: () {
          _controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controller.text.length,
          );
        },
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(
          labelText: 'Nombre del Grafo',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(onPressed: _cancel, child: const Text('Cancelar')),
        FilledButton(onPressed: _submit, child: const Text('Aceptar')),
      ],
    );
  }
}
