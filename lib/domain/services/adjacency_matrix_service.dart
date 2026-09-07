import 'dart:math';

import '../models/atributo.dart';
import '../models/direccion.dart';
import '../models/grafo.dart';
import '../models/nodo.dart';

class AdjacencyCell {
  final bool isConnected;
  final String weightedValue;
  final String directionSymbol;

  const AdjacencyCell({
    required this.isConnected,
    required this.weightedValue,
    required this.directionSymbol,
  });

  /// Getter for backward compatibility in binary matrix checks
  String get binaryValue => isConnected ? '1' : '0';
}

class AdjacencyMatrixData {
  final List<Nodo> nodes;
  final List<String> labels;
  final List<List<AdjacencyCell>> matrix;
  final List<double> rowSums;
  final List<double> colSums;
  final List<int> rowDegrees;
  final List<int> colDegrees;
  final double totalWeightSum;
  final int totalDegrees;

  /// Δ(G): maximum vertex degree (edges incident to the most-connected node)
  final int maxDegree;

  /// δ(G): minimum vertex degree (edges incident to the least-connected node)
  final int minDegree;

  /// Per-vertex degree list: d(v) = edges incident to v (self-loops count twice)
  final List<int> vertexDegrees;

  const AdjacencyMatrixData({
    required this.nodes,
    required this.labels,
    required this.matrix,
    required this.rowSums,
    required this.colSums,
    required this.rowDegrees,
    required this.colDegrees,
    required this.totalWeightSum,
    required this.totalDegrees,
    required this.maxDegree,
    required this.minDegree,
    required this.vertexDegrees,
  });

  /// Getters for backward compatibility
  List<List<AdjacencyCell>> get weightedMatrix => matrix;
  List<List<AdjacencyCell>> get binaryMatrix => matrix;

  bool get isEmpty => nodes.isEmpty;

  /// Formats a double value nicely without trailing .0 if integer
  static String formatValue(double val) {
    if (val % 1 == 0) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1);
  }

  /// Pure weighted CSV export by default
  String toCsv({bool weighted = true}) {
    if (isEmpty) return '';
    final buffer = StringBuffer();

    // Header row
    buffer.write('Origen/Destino,');
    buffer.write(labels.map((l) => '"$l"').join(','));
    buffer.writeln(',"Suma Fila","Grado Fila"');

    // Matrix Rows
    for (int i = 0; i < nodes.length; i++) {
      buffer.write('"${labels[i]}",');
      final rowValues = matrix[i].map((cell) {
        final val = weighted ? cell.weightedValue : cell.binaryValue;
        return '"$val"';
      });
      buffer.write(rowValues.join(','));
      buffer.writeln(',"${formatValue(rowSums[i])}","${rowDegrees[i]}"');
    }

    // Summary Row 1: Suma Columna
    buffer.write('"Suma Col.",');
    buffer.write(colSums.map((s) => '"${formatValue(s)}"').join(','));
    buffer.writeln(',"${formatValue(totalWeightSum)}","$totalDegrees"');

    // Summary Row 2: Grado Columna
    buffer.write('"Grado Col.",');
    buffer.write(colDegrees.map((d) => '"$d"').join(','));
    buffer.writeln(',"${formatValue(totalWeightSum)}","$totalDegrees"');

    return buffer.toString();
  }
}

class AdjacencyMatrixService {
  static AdjacencyMatrixData calculateMatrix(Grafo grafo) {
    // Preserve node creation / index number order (1, 2, 3...)
    final orderedNodes = grafo.nodos.values.toList();

    final labels = orderedNodes.map((n) => n.nombre ?? n.id).toList();
    final n = orderedNodes.length;

    final matrix = List.generate(
      n,
      (_) => List.generate(
        n,
        (_) => const AdjacencyCell(
          isConnected: false,
          weightedValue: '0',
          directionSymbol: '',
        ),
      ),
    );

    for (int i = 0; i < n; i++) {
      final u = orderedNodes[i];
      for (int j = 0; j < n; j++) {
        final v = orderedNodes[j];

        // Find connections between u and v
        final connUtoV = grafo.conexiones.values.where((c) {
          if (c.nodoOrigenId == u.id && c.nodoDestinoId == v.id) {
            return true;
          }
          if (c.direccion == Direccion.ninguna &&
              ((c.nodoOrigenId == u.id && c.nodoDestinoId == v.id) ||
                  (c.nodoOrigenId == v.id && c.nodoDestinoId == u.id))) {
            return true;
          }
          return false;
        }).toList();

        if (connUtoV.isNotEmpty) {
          final weights = <String>[];
          String dirSymbol = '';

          for (final c in connUtoV) {
            String val = '1';
            final attrVal = c.atributos.firstWhere(
              (a) => a.atributoId == 'attr_valor',
              orElse: () => c.atributos.isNotEmpty
                  ? c.atributos.first
                  : const AtributoValor(atributoId: '', valor: '1'),
            );
            final parsed = double.tryParse(attrVal.valor);
            if (attrVal.valor.isNotEmpty && parsed != null && parsed > 0) {
              val = attrVal.valor;
            }
            weights.add(val);

            if (u.id == v.id) {
              dirSymbol = '↺';
            } else if (c.direccion == Direccion.bidireccional) {
              dirSymbol = '↔';
            } else if (c.direccion == Direccion.unidireccional) {
              dirSymbol = c.nodoOrigenId == u.id ? '→' : '←';
            } else {
              dirSymbol = '—';
            }
          }

          final weightStr = weights.join(', ');

          final cell = AdjacencyCell(
            isConnected: true,
            weightedValue: weightStr,
            directionSymbol: dirSymbol,
          );

          matrix[i][j] = cell;
        } else {
          matrix[i][j] = const AdjacencyCell(
            isConnected: false,
            weightedValue: '0',
            directionSymbol: '',
          );
        }
      }
    }

    // Calculate Row and Column Sums and Degrees
    final rowSums = List<double>.filled(n, 0.0);
    final colSums = List<double>.filled(n, 0.0);
    final rowDegrees = List<int>.filled(n, 0);
    final colDegrees = List<int>.filled(n, 0);
    double totalWeightSum = 0.0;
    int totalDegrees = 0;

    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        final cell = matrix[i][j];
        if (cell.isConnected) {
          rowDegrees[i]++;
          colDegrees[j]++;
          totalDegrees++;

          double cellSum = 0.0;
          for (final part in cell.weightedValue.split(',')) {
            final parsed = double.tryParse(part.trim());
            if (parsed != null) {
              cellSum += parsed;
            }
          }
          rowSums[i] += cellSum;
          colSums[j] += cellSum;
          totalWeightSum += cellSum;
        }
      }
    }

    // Per-vertex degree: d(v) = number of edges incident to v.
    // Self-loops count twice (standard graph theory convention).
    final vertexDegrees = List<int>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      final nodeId = orderedNodes[i].id;
      for (final c in grafo.conexiones.values) {
        final isSelf = c.nodoOrigenId == nodeId && c.nodoDestinoId == nodeId;
        if (isSelf) {
          vertexDegrees[i] += 2;
        } else if (c.nodoOrigenId == nodeId || c.nodoDestinoId == nodeId) {
          vertexDegrees[i]++;
        }
      }
    }
    final maxDegree = vertexDegrees.isNotEmpty ? vertexDegrees.reduce(max) : 0;
    final minDegree = vertexDegrees.isNotEmpty ? vertexDegrees.reduce(min) : 0;

    return AdjacencyMatrixData(
      nodes: orderedNodes,
      labels: labels,
      matrix: matrix,
      rowSums: rowSums,
      colSums: colSums,
      rowDegrees: rowDegrees,
      colDegrees: colDegrees,
      totalWeightSum: totalWeightSum,
      totalDegrees: totalDegrees,
      maxDegree: maxDegree,
      minDegree: minDegree,
      vertexDegrees: vertexDegrees,
    );
  }
}
