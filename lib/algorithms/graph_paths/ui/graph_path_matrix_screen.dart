import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/grafo_provider.dart';
import '../../../domain/models/conexion.dart';
import '../../../domain/models/direccion.dart';

/// A lossless, read-only view of the existing graph model. Empty is distinct
/// from weight zero; parallel edges remain separate values in one cell.
class GraphPathMatrixScreen extends ConsumerWidget {
  const GraphPathMatrixScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graph = ref.watch(grafoProvider);
    final nodes = graph.nodos.values.toList();
    final colors = Theme.of(context).colorScheme;
    final index = <String, int>{
      for (var i = 0; i < nodes.length; i++) nodes[i].id: i,
    };
    final matrix = List.generate(
      nodes.length,
      (_) => List.generate(nodes.length, (_) => <Conexion>[]),
    );
    for (final edge in graph.conexiones.values) {
      final row = index[edge.nodoOrigenId];
      final col = index[edge.nodoDestinoId];
      if (row == null || col == null) continue;
      matrix[row][col].add(edge);
      if (edge.direccion != Direccion.unidireccional && row != col) {
        matrix[col][row].add(edge);
      }
    }
    // Keeps each list's ordering stable for parallel edges.
    for (final row in matrix) {
      for (final cell in row) {
        cell.sort((a, b) => a.id.compareTo(b.id));
      }
    }
    String value(Conexion connection) {
      final weight = connection.atributos
          .where((attribute) => attribute.atributoId == 'attr_valor')
          .map((attribute) => attribute.valor)
          .firstOrNull;
      return weight ?? '?';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Matriz de adyacencia ponderada')),
      body: nodes.isEmpty
          ? const Center(child: Text('Agrega vértices para ver la matriz.'))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Cada celda muestra todos los pesos de las aristas del origen al destino. «—» significa que no hay arista; 0 es un peso válido.',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 18),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      const DataColumn(label: Text('Origen ↓ / destino →')),
                      for (final node in nodes)
                        DataColumn(label: Text(node.nombre ?? node.id)),
                    ],
                    rows: [
                      for (var i = 0; i < nodes.length; i++)
                        DataRow(
                          cells: [
                            DataCell(Text(nodes[i].nombre ?? nodes[i].id)),
                            for (var j = 0; j < nodes.length; j++)
                              DataCell(
                                Text(
                                  matrix[i][j].isEmpty
                                      ? '—'
                                      : matrix[i][j].map(value).join(' / '),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Las aristas no dirigidas o bidireccionales aparecen en ambas direcciones sin duplicarse en el grafo.',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
    );
  }
}
