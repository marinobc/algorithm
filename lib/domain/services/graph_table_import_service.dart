import 'dart:math';

import 'package:flutter/material.dart';

import '../models/atributo.dart';
import '../models/conexion.dart';
import '../models/direccion.dart';
import '../models/grafo.dart';
import '../models/nodo.dart';

class GraphTableImportException implements Exception {
  final String message;

  const GraphTableImportException(this.message);

  @override
  String toString() => message;
}

class GraphTableImportService {
  static const _colors = [
    Color(0xFF7C4DFF),
    Color(0xFF00BFA5),
    Color(0xFFFF5252),
    Color(0xFFFF9100),
    Color(0xFF00B8D4),
    Color(0xFFD500F9),
    Color(0xFFAEEA00),
    Color(0xFFFFC400),
  ];

  static Grafo fromAdjacencyMatrix(String input, {required bool directed}) {
    final lines = input
        .trimRight()
        .split(RegExp(r'\r?\n'))
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.length < 2) {
      throw const GraphTableImportException(
        'Incluye una fila de encabezados y al menos una fila de datos.',
      );
    }

    final rows = lines.map(_splitLine).toList();
    final headers = rows.first.skip(1).map((value) => value.trim()).toList();
    if (headers.isEmpty || headers.any((name) => name.isEmpty)) {
      throw const GraphTableImportException(
        'La primera fila debe contener los nombres de todos los nodos.',
      );
    }
    if (headers.toSet().length != headers.length) {
      throw const GraphTableImportException(
        'Los nombres de los nodos no pueden repetirse.',
      );
    }
    if (rows.length - 1 != headers.length) {
      throw const GraphTableImportException(
        'La matriz debe ser cuadrada: una fila por cada nodo.',
      );
    }

    final matrix = <List<double?>>[];
    for (var index = 1; index < rows.length; index++) {
      final row = rows[index];
      if (row.length != headers.length + 1) {
        throw GraphTableImportException(
          'La fila ${index + 1} debe tener ${headers.length} valores.',
        );
      }
      final rowName = row.first.trim();
      if (rowName != headers[index - 1]) {
        throw GraphTableImportException(
          'La fila ${index + 1} debe llamarse "${headers[index - 1]}".',
        );
      }
      matrix.add(
        row.skip(1).map((raw) {
          final value = raw.trim();
          if (value.isEmpty || value == '-' || value == '0') return null;
          final parsed = double.tryParse(value.replaceAll(',', '.'));
          if (parsed == null || parsed <= 0) {
            throw GraphTableImportException(
              '"$value" no es un peso válido. Usa números positivos o 0.',
            );
          }
          return parsed;
        }).toList(),
      );
    }

    final nodeCount = headers.length;
    final radius = max(180.0, min(620.0, nodeCount * 48.0));
    final nodes = <String, Nodo>{};
    for (var i = 0; i < nodeCount; i++) {
      final angle = -pi / 2 + (2 * pi * i / nodeCount);
      final id = 'nodo_tabla_$i';
      nodes[id] = Nodo(
        id: id,
        nombre: headers[i],
        colorValue: _colors[i % _colors.length].toARGB32(),
        x: cos(angle) * radius,
        y: sin(angle) * radius,
      );
    }

    final connections = <String, Conexion>{};
    for (var row = 0; row < nodeCount; row++) {
      for (var column = 0; column < nodeCount; column++) {
        if (!directed && column < row) continue;
        final value =
            matrix[row][column] ?? (!directed ? matrix[column][row] : null);
        if (value == null) continue;
        final id = 'conexion_tabla_${row}_$column';
        connections[id] = Conexion(
          id: id,
          nodoOrigenId: 'nodo_tabla_$row',
          nodoDestinoId: 'nodo_tabla_$column',
          colorValue: const Color(0xFF616161).toARGB32(),
          direccion: directed ? Direccion.unidireccional : Direccion.ninguna,
          atributos: [
            AtributoValor(atributoId: 'attr_valor', valor: _formatValue(value)),
          ],
        );
      }
    }

    if (connections.isEmpty) {
      throw const GraphTableImportException(
        'La matriz no contiene conexiones. Agrega al menos un valor positivo.',
      );
    }

    return Grafo(nodos: nodes, conexiones: connections);
  }

  static Grafo fromCostMatrix({
    required List<String> rowNames,
    required List<String> columnNames,
    required List<List<double?>> values,
  }) {
    if (rowNames.isEmpty || columnNames.isEmpty) {
      throw const GraphTableImportException(
        'La tabla necesita al menos una fila y una columna.',
      );
    }
    if (values.length != rowNames.length ||
        values.any((row) => row.length != columnNames.length)) {
      throw const GraphTableImportException(
        'Las dimensiones de los valores no coinciden con la tabla.',
      );
    }

    final cleanRowNames = _validateNames(rowNames, 'filas');
    final cleanColumnNames = _validateNames(columnNames, 'columnas');
    final nodes = <String, Nodo>{};
    final rowSpacing = min(150.0, 720.0 / max(1, rowNames.length - 1));
    final columnSpacing = min(150.0, 720.0 / max(1, columnNames.length - 1));

    for (var row = 0; row < cleanRowNames.length; row++) {
      final id = 'fila_tabla_$row';
      nodes[id] = Nodo(
        id: id,
        nombre: cleanRowNames[row],
        colorValue: _colors[row % _colors.length].toARGB32(),
        x: -320,
        y: (row - (cleanRowNames.length - 1) / 2) * rowSpacing,
      );
    }
    for (var column = 0; column < cleanColumnNames.length; column++) {
      final id = 'columna_tabla_$column';
      nodes[id] = Nodo(
        id: id,
        nombre: cleanColumnNames[column],
        colorValue: _colors[(column + cleanRowNames.length) % _colors.length]
            .toARGB32(),
        x: 320,
        y: (column - (cleanColumnNames.length - 1) / 2) * columnSpacing,
      );
    }

    final connections = <String, Conexion>{};
    for (var row = 0; row < values.length; row++) {
      for (var column = 0; column < values[row].length; column++) {
        final value = values[row][column];
        if (value == null || value == 0) continue;
        if (value < 0) {
          throw const GraphTableImportException(
            'Los valores de la tabla no pueden ser negativos.',
          );
        }
        final id = 'conexion_tabla_${row}_$column';
        connections[id] = Conexion(
          id: id,
          nodoOrigenId: 'fila_tabla_$row',
          nodoDestinoId: 'columna_tabla_$column',
          colorValue: const Color(0xFF616161).toARGB32(),
          direccion: Direccion.unidireccional,
          atributos: [
            AtributoValor(atributoId: 'attr_valor', valor: _formatValue(value)),
          ],
        );
      }
    }
    if (connections.isEmpty) {
      throw const GraphTableImportException(
        'Ingresa al menos un valor positivo en la tabla.',
      );
    }
    return Grafo(nodos: nodes, conexiones: connections);
  }

  static List<String> _validateNames(List<String> names, String group) {
    final clean = names.map((name) => name.trim()).toList();
    if (clean.any((name) => name.isEmpty)) {
      throw GraphTableImportException(
        'Todos los nombres de las $group son obligatorios.',
      );
    }
    if (clean.toSet().length != clean.length) {
      throw GraphTableImportException(
        'Los nombres de las $group no pueden repetirse.',
      );
    }
    return clean;
  }

  static List<String> _splitLine(String line) {
    if (line.contains('\t')) return line.split('\t');
    if (line.contains(';')) return line.split(';');
    return line.split(',');
  }

  static String _formatValue(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}
