import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/grafo_invalido_provider.dart';
import '../../application/providers/grafo_provider.dart';
import '../../domain/services/adjacency_matrix_service.dart';
import 'adjacency_matrix/matrix_grid_table.dart';
import 'adjacency_matrix/matrix_stats_footer.dart';

typedef AdjacencyMatrixDialog = AdjacencyMatrixScreen;

class AdjacencyMatrixScreen extends ConsumerStatefulWidget {
  const AdjacencyMatrixScreen({super.key});

  @override
  ConsumerState<AdjacencyMatrixScreen> createState() =>
      _AdjacencyMatrixScreenState();
}

class _AdjacencyMatrixScreenState extends ConsumerState<AdjacencyMatrixScreen> {
  int? _selectedRowIndex;
  int? _selectedColumnIndex;

  @override
  Widget build(BuildContext context) {
    final grafo = ref.watch(grafoProvider);
    final esInvalido = ref.watch(esGrafoInvalidoProvider);
    final matrixData = AdjacencyMatrixService.calculateMatrix(grafo);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Matriz de Adyacencia Ponderada',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Toca para resaltar el fondo',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: esInvalido
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.link_off_rounded,
                        size: 64,
                        color: colorScheme.error.withValues(alpha: 0.8),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Conecta el grafo para poder ver la matriz',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.error,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Existen nodos o secciones sin conectar en el lienzo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : matrixData.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.grid_off_rounded,
                      size: 64,
                      color: colorScheme.outline.withAlpha(128),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'El lienzo está vacío',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Agrega nodos y conexiones en el lienzo para calcular la matriz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Main Mathematical Matrix Card Container
                    Expanded(
                      child: Card(
                        margin: EdgeInsets.zero,
                        elevation: 0,
                        color: colorScheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: colorScheme.outlineVariant),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: MatrixGridTable(
                                    matrixData: matrixData,
                                    selectedRowIndex: _selectedRowIndex,
                                    selectedColumnIndex: _selectedColumnIndex,
                                    onCellTapped: (i, j) {
                                      setState(() {
                                        if (_selectedRowIndex == i &&
                                            _selectedColumnIndex == j) {
                                          _selectedRowIndex = null;
                                          _selectedColumnIndex = null;
                                        } else {
                                          _selectedRowIndex = i;
                                          _selectedColumnIndex = j;
                                        }
                                      });
                                    },
                                    onColumnHeaderTapped: (j) {
                                      setState(() {
                                        _selectedColumnIndex =
                                            _selectedColumnIndex == j ? null : j;
                                      });
                                    },
                                    onRowHeaderTapped: (i) {
                                      setState(() {
                                        _selectedRowIndex =
                                            _selectedRowIndex == i ? null : i;
                                      });
                                    },
                                    onColSummaryHeaderTapped: (idx) {
                                      setState(() {
                                        _selectedColumnIndex =
                                            _selectedColumnIndex == idx ? null : idx;
                                      });
                                    },
                                    onRowSummaryHeaderTapped: (idx) {
                                      setState(() {
                                        _selectedRowIndex =
                                            _selectedRowIndex == idx ? null : idx;
                                      });
                                    },
                                    colorScheme: colorScheme,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    MatrixStatsFooter(
                      totalNodes: matrixData.nodes.length,
                      totalConnections: grafo.conexiones.length,
                      maxDegree: matrixData.maxDegree,
                      minDegree: matrixData.minDegree,
                      hasSelection: _selectedRowIndex != null ||
                          _selectedColumnIndex != null,
                      onClearSelection: () {
                        setState(() {
                          _selectedRowIndex = null;
                          _selectedColumnIndex = null;
                        });
                      },
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
