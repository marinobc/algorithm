import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../domain/models/conexion.dart';
import '../../domain/models/direccion.dart';
import '../text/app_text.dart';
import '../text/dialog_text.dart';
import '../theme/app_theme.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final bool isNode;
  final String? nodeName;
  final Conexion? targetConnection;
  final List<Conexion> connectionsToDelete;
  final Map<String, String> attributeNames;
  final Map<String, String> nodeNames;

  const DeleteConfirmationDialog({
    super.key,
    required this.isNode,
    this.nodeName,
    this.targetConnection,
    this.connectionsToDelete = const [],
    this.attributeNames = const {},
    this.nodeNames = const {},
  });

  String _formatConnectionValues(Conexion conn) {
    final origName = nodeNames[conn.nodoOrigenId] ?? conn.nodoOrigenId;
    final destName = nodeNames[conn.nodoDestinoId] ?? conn.nodoDestinoId;
    final isSelfLoop = conn.nodoOrigenId == conn.nodoDestinoId;

    final directionLabel = isSelfLoop
        ? 'Bucle ($origName)'
        : (conn.direccion == Direccion.ninguna
              ? '$origName - $destName'
              : '$origName → $destName');

    final filledValues = conn.atributos
        .where((av) => av.valor.trim().isNotEmpty)
        .map((av) {
          final tag = attributeNames[av.atributoId];
          return tag != null && tag.isNotEmpty ? '$tag: ${av.valor}' : av.valor;
        })
        .toList();

    if (filledValues.isEmpty) {
      return '• $directionLabel (Sin valores)';
    }

    return '• $directionLabel (${filledValues.join(', ')})';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final title = isNode
        ? DialogText.deleteNodeTitle
        : DialogText.deleteConnectionTitle;

    final confirmMessage = isNode
        ? (nodeName != null && nodeName!.isNotEmpty
              ? DialogText.confirmDeleteNamedNode(nodeName!)
              : DialogText.confirmDeleteNode)
        : DialogText.confirmDeleteConnection;

    return AlertDialog(
      icon: Icon(Icons.delete_outline, color: colorScheme.error),
      title: Text(title, style: TextStyle(color: colorScheme.error)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            confirmMessage,
            style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
          ),
          if (!isNode && targetConnection != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatConnectionValues(targetConnection!),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          if (isNode && connectionsToDelete.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              DialogText.confirmDeleteNodeConnections(
                connectionsToDelete.length,
              ),
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 140),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final conn in connectionsToDelete)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 4.0,
                          ),
                          child: Text(
                            _formatConnectionValues(conn),
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(AppText.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(AppText.delete),
        ),
      ],
    );
  }
}

@Preview(name: 'DeleteConfirmationDialog - Node', group: 'Dialogs')
Widget deleteConfirmationNodePreview() {
  const sampleConn = Conexion(
    id: 'c1',
    nodoOrigenId: 'n1',
    nodoDestinoId: 'n2',
    colorValue: 0xFF2196F3,
    direccion: Direccion.unidireccional,
  );

  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.darkTheme,
    themeMode: ThemeMode.dark,
    home: Scaffold(
      body: Center(
        child: DeleteConfirmationDialog(
          isNode: true,
          nodeName: 'Nodo Alfa',
          connectionsToDelete: const [sampleConn],
        ),
      ),
    ),
  );
}

@Preview(name: 'DeleteConfirmationDialog - Connection', group: 'Dialogs')
Widget deleteConfirmationConnectionPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Center(child: DeleteConfirmationDialog(isNode: false)),
    ),
  );
}
