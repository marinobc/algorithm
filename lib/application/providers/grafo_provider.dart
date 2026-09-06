import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/atributo.dart';
import '../../domain/models/conexion.dart';
import '../../domain/models/direccion.dart';
import '../../domain/models/grafo.dart';
import '../../domain/models/nodo.dart';
import '../../domain/services/graph_geometry.dart';
import '../../domain/services/graph_storage_service.dart';
import 'config_provider.dart';

class GrafoNotifier extends Notifier<Grafo> {
  final List<Grafo> _undoStack = [];
  final List<Grafo> _redoStack = [];
  Grafo? _lastSavedGraphState;

  bool get puedeDeshacer => _undoStack.isNotEmpty;
  bool get puedeRehacer => _redoStack.isNotEmpty;

  /// Returns true if current graph state differs from the last saved state.
  bool get tieneCambiosSinGuardar {
    final saved = _lastSavedGraphState;
    if (saved == null) {
      return state.nodos.isNotEmpty || _undoStack.isNotEmpty;
    }
    return state != saved;
  }

  /// Sets the current state snapshot as the saved checkpoint without clearing undo/redo.
  void marcarPuntoGuardado() {
    _lastSavedGraphState = state;
  }

  void _recordUndoState() {
    _undoStack.add(state);
    _redoStack.clear();
  }

  /// Undoes the last graph mutation.
  bool deshacer() {
    if (_undoStack.isEmpty) return false;
    _redoStack.add(state);
    state = _undoStack.removeLast();
    return true;
  }

  /// Redoes the last undone graph mutation.
  bool rehacer() {
    if (_redoStack.isEmpty) return false;
    _undoStack.add(state);
    state = _redoStack.removeLast();
    return true;
  }

  @override
  Grafo build() => const Grafo();

  int _nodeSeq = 0;

  /// Generates a bright HSV color value that maximizes minimum hue distance from all existing nodes in [state.nodos].
  int generateMaximallyDistinctColor() {
    final existingHues = state.nodos.values
        .map((n) => HSVColor.fromColor(Color(n.colorValue)).hue)
        .toList();

    if (existingHues.isEmpty) {
      final initialHue = Random().nextDouble() * 360.0;
      return HSVColor.fromAHSV(1.0, initialHue, 0.85, 0.95).toColor().toARGB32();
    }

    double bestHue = 0.0;
    double maxMinDistance = -1.0;

    for (int i = 0; i < 72; i++) {
      final candHue = i * 5.0;
      double minDistance = 360.0;

      for (final existingHue in existingHues) {
        double diff = (candHue - existingHue).abs();
        if (diff > 180.0) {
          diff = 360.0 - diff;
        }
        if (diff < minDistance) {
          minDistance = diff;
        }
      }

      if (minDistance > maxMinDistance) {
        maxMinDistance = minDistance;
        bestHue = candHue;
      }
    }

    final rng = Random();
    final sat = 0.75 + rng.nextDouble() * 0.20;
    final val = 0.85 + rng.nextDouble() * 0.15;
    return HSVColor.fromAHSV(1.0, bestHue, sat, val).toColor().toARGB32();
  }

  /// Adds a new node to the graph and returns the created node.
  Nodo agregarNodo(
    double x,
    double y, {
    String? nombre,
    int? colorValue,
  }) {
    _recordUndoState();
    final clamped = GraphGeometry.clampNodePosition(x, y);
    final nextNumber = state.nodos.length + 1;
    final nodeName = nombre ?? 'Nodo $nextNumber';
    final nodeId = 'nodo_${DateTime.now().microsecondsSinceEpoch}_${_nodeSeq++}';
    final nodeColor = colorValue ?? generateMaximallyDistinctColor();

    final nuevoNodo = Nodo(
      id: nodeId,
      nombre: nodeName,
      colorValue: nodeColor,
      x: clamped.x,
      y: clamped.y,
    );

    final updatedNodos = Map<String, Nodo>.from(state.nodos)..[nodeId] = nuevoNodo;
    state = state.copyWith(nodos: updatedNodos);
    return nuevoNodo;
  }

  /// Updates node position.
  void moverNodo(String id, double x, double y, {bool recordUndo = false}) {
    final nodo = state.nodos[id];
    if (nodo == null) return;
    if (recordUndo) {
      _recordUndoState();
    }
    final clamped = GraphGeometry.clampNodePosition(x, y);
    final updatedNodo = nodo.copyWith(x: clamped.x, y: clamped.y);
    final updatedNodos = Map<String, Nodo>.from(state.nodos)..[id] = updatedNodo;
    state = state.copyWith(nodos: updatedNodos);
  }

  /// Updates node properties (name, color).
  void actualizarNodo(String id, {String? nombre, int? colorValue}) {
    final nodo = state.nodos[id];
    if (nodo == null) return;
    _recordUndoState();
    final updatedNodo = nodo.copyWith(
      nombre: nombre ?? nodo.nombre,
      colorValue: colorValue ?? nodo.colorValue,
    );
    final updatedNodos = Map<String, Nodo>.from(state.nodos)..[id] = updatedNodo;
    state = state.copyWith(nodos: updatedNodos);
  }

  /// Deletes a node and all associated connections. Returns list of removed connections.
  List<Conexion> eliminarNodo(String id) {
    _recordUndoState();
    final conexionesAEliminar = state.obtenerConexionesDeNodo(id);
    final idsAEliminar = conexionesAEliminar.map((c) => c.id).toSet();

    final updatedNodos = Map<String, Nodo>.from(state.nodos)..remove(id);
    final updatedConexiones = Map<String, Conexion>.from(state.conexiones)
      ..removeWhere((key, value) => idsAEliminar.contains(key));

    state = state.copyWith(
      nodos: updatedNodos,
      conexiones: updatedConexiones,
    );

    return conexionesAEliminar;
  }

  /// Adds a new connection between two nodes.
  List<Conexion> agregarConexion(
    String origenId,
    String destinoId, [
    Direccion? direccion,
    int? colorValue,
    List<AtributoValor>? atributos,
  ]) {
    final defaultDir = ref.read(configProvider).tipoConexionPorDefecto;
    final targetDireccion = direccion ?? defaultDir;

    final isSelfLoop = origenId == destinoId;
    final origNode = state.nodos[origenId];
    final destNode = state.nodos[destinoId];

    if (isSelfLoop) {
      final existingLoop = state.conexiones.values.firstWhere(
        (c) => c.nodoOrigenId == origenId && c.nodoDestinoId == origenId,
        orElse: () => const Conexion(id: '', nodoOrigenId: '', nodoDestinoId: '', colorValue: 0),
      );
      if (existingLoop.id.isNotEmpty) {
        return [];
      }
    } else {
      final existingPair = state.conexiones.values.where(
        (c) =>
            (c.nodoOrigenId == origenId && c.nodoDestinoId == destinoId) ||
            (c.nodoOrigenId == destinoId && c.nodoDestinoId == origenId),
      ).toList();

      if (existingPair.length >= 2) {
        return [];
      } else if (existingPair.length == 1) {
        // Connecting the same two nodes twice converts the relationship to bidirectional!
        actualizarParejaConexiones(
          nodeAId: origenId,
          nodeBId: destinoId,
          targetDirection: Direccion.bidireccional,
        );
        return state.conexiones.values.where(
          (c) =>
              (c.nodoOrigenId == origenId && c.nodoDestinoId == destinoId) ||
              (c.nodoOrigenId == destinoId && c.nodoDestinoId == origenId),
        ).toList();
      }
    }

    _recordUndoState();
    final defaultConfigVal = ref.read(configProvider).valorConexionPorDefecto;
    final validDefaultVal = (defaultConfigVal.isEmpty ||
            double.tryParse(defaultConfigVal) == null ||
            (double.tryParse(defaultConfigVal) ?? 0) <= 0)
        ? '1'
        : defaultConfigVal;

    final defaultAttrs = <AtributoValor>[];
    if (atributos != null && atributos.isNotEmpty) {
      defaultAttrs.addAll(atributos);
    }

    final hasValAttr = defaultAttrs.any((a) => a.atributoId == 'attr_valor');
    if (!hasValAttr) {
      defaultAttrs.insert(0, AtributoValor(atributoId: 'attr_valor', valor: validDefaultVal));
    } else {
      for (int i = 0; i < defaultAttrs.length; i++) {
        if (defaultAttrs[i].atributoId == 'attr_valor') {
          final valStr = defaultAttrs[i].valor.trim();
          final numVal = double.tryParse(valStr);
          if (valStr.isEmpty || numVal == null || numVal <= 0) {
            defaultAttrs[i] = AtributoValor(atributoId: 'attr_valor', valor: validDefaultVal);
          }
        }
      }
    }

    if (targetDireccion == Direccion.bidireccional) {
      final now = DateTime.now().microsecondsSinceEpoch;
      final id1 = 'conn_${now}_1';
      final id2 = 'conn_${now}_2';

      final color1 = colorValue ?? (origNode?.colorValue ?? 0xFF00E676);
      final color2 = destNode?.colorValue ?? 0xFFFF3D00;

      final c1 = Conexion(
        id: id1,
        nodoOrigenId: origenId,
        nodoDestinoId: destinoId,
        colorValue: color1,
        direccion: Direccion.unidireccional,
        atributos: defaultAttrs,
      );

      final c2 = Conexion(
        id: id2,
        nodoOrigenId: destinoId,
        nodoDestinoId: origenId,
        colorValue: color2,
        direccion: Direccion.unidireccional,
        atributos: defaultAttrs,
      );

      final updatedConexiones = Map<String, Conexion>.from(state.conexiones)
        ..[id1] = c1
        ..[id2] = c2;
      state = state.copyWith(conexiones: updatedConexiones);
      return [c1, c2];
    } else {
      final conexionId = 'conn_${DateTime.now().microsecondsSinceEpoch}';
      final connColor = colorValue ??
          (targetDireccion == Direccion.ninguna
              ? 0xFF9E9E9E // Soft gray for non-directional
              : (origNode?.colorValue ?? 0xFF00E676)); // Origin node color for directional

      final nuevaConexion = Conexion(
        id: conexionId,
        nodoOrigenId: origenId,
        nodoDestinoId: destinoId,
        colorValue: connColor,
        direccion: targetDireccion,
        atributos: defaultAttrs,
      );

      final updatedConexiones = Map<String, Conexion>.from(state.conexiones)
        ..[conexionId] = nuevaConexion;
      state = state.copyWith(conexiones: updatedConexiones);
      return [nuevaConexion];
    }
  }

  /// Updates connection properties (direction, color, attributes, endpoints, curvatura, loopAngle, 2D offsets).
  void actualizarConexion(
    String id, {
    String? nodoOrigenId,
    String? nodoDestinoId,
    Direccion? direccion,
    int? colorValue,
    List<AtributoValor>? atributos,
    double? curvatura,
    double? loopAngle,
    double? offsetControlX,
    double? offsetControlY,
    bool recordUndo = false,
  }) {
    final conexion = state.conexiones[id];
    if (conexion == null) return;

    if (recordUndo) {
      _recordUndoState();
    }

    final updated = conexion.copyWith(
      nodoOrigenId: nodoOrigenId ?? conexion.nodoOrigenId,
      nodoDestinoId: nodoDestinoId ?? conexion.nodoDestinoId,
      direccion: direccion ?? conexion.direccion,
      colorValue: colorValue ?? conexion.colorValue,
      atributos: atributos ?? conexion.atributos,
      curvatura: curvatura ?? conexion.curvatura,
      loopAngle: loopAngle ?? conexion.loopAngle,
      offsetControlX: offsetControlX ?? conexion.offsetControlX,
      offsetControlY: offsetControlY ?? conexion.offsetControlY,
    );

    final updatedConexiones = Map<String, Conexion>.from(state.conexiones)
      ..[id] = updated;

    state = state.copyWith(conexiones: updatedConexiones);
  }

  /// Updates or converts a pair of connections between node A and node B.
  void actualizarParejaConexiones({
    required String nodeAId,
    required String nodeBId,
    required Direccion targetDirection,
    int? colorValueAtoB,
    int? colorValueBtoA,
    List<AtributoValor>? atributosAtoB,
    List<AtributoValor>? atributosBtoA,
  }) {
    _recordUndoState();
    final updatedConexiones = Map<String, Conexion>.from(state.conexiones);

    final connAtoB = updatedConexiones.values.firstWhere(
      (c) => c.nodoOrigenId == nodeAId && c.nodoDestinoId == nodeBId,
      orElse: () => const Conexion(id: '', nodoOrigenId: '', nodoDestinoId: '', colorValue: 0),
    );

    final connBtoA = updatedConexiones.values.firstWhere(
      (c) => c.nodoOrigenId == nodeBId && c.nodoDestinoId == nodeAId,
      orElse: () => const Conexion(id: '', nodoOrigenId: '', nodoDestinoId: '', colorValue: 0),
    );

    final now = DateTime.now().microsecondsSinceEpoch;

    final defaultConfigVal = ref.read(configProvider).valorConexionPorDefecto;
    final validDefaultVal = (defaultConfigVal.isEmpty ||
            double.tryParse(defaultConfigVal) == null ||
            (double.tryParse(defaultConfigVal) ?? 0) <= 0)
        ? '1'
        : defaultConfigVal;
    final fallbackAttrs = [AtributoValor(atributoId: 'attr_valor', valor: validDefaultVal)];

    if (targetDirection == Direccion.bidireccional) {
      final id1 = connAtoB.id.isNotEmpty ? connAtoB.id : 'conn_${now}_1';
      final id2 = connBtoA.id.isNotEmpty ? connBtoA.id : 'conn_${now}_2';

      updatedConexiones[id1] = Conexion(
        id: id1,
        nodoOrigenId: nodeAId,
        nodoDestinoId: nodeBId,
        colorValue: colorValueAtoB ?? (connAtoB.id.isNotEmpty ? connAtoB.colorValue : 0xFF4CAF50),
        direccion: Direccion.unidireccional,
        atributos: atributosAtoB ?? (connAtoB.id.isNotEmpty && connAtoB.atributos.isNotEmpty ? connAtoB.atributos : fallbackAttrs),
        curvatura: connAtoB.id.isNotEmpty ? connAtoB.curvatura : null,
        loopAngle: connAtoB.id.isNotEmpty ? connAtoB.loopAngle : null,
        offsetControlX: connAtoB.id.isNotEmpty ? connAtoB.offsetControlX : null,
        offsetControlY: connAtoB.id.isNotEmpty ? connAtoB.offsetControlY : null,
      );

      updatedConexiones[id2] = Conexion(
        id: id2,
        nodoOrigenId: nodeBId,
        nodoDestinoId: nodeAId,
        colorValue: colorValueBtoA ?? (connBtoA.id.isNotEmpty ? connBtoA.colorValue : 0xFFFF9800),
        direccion: Direccion.unidireccional,
        atributos: atributosBtoA ?? (connBtoA.id.isNotEmpty && connBtoA.atributos.isNotEmpty ? connBtoA.atributos : fallbackAttrs),
        curvatura: connBtoA.id.isNotEmpty ? connBtoA.curvatura : null,
        loopAngle: connBtoA.id.isNotEmpty ? connBtoA.loopAngle : null,
        offsetControlX: connBtoA.id.isNotEmpty ? connBtoA.offsetControlX : null,
        offsetControlY: connBtoA.id.isNotEmpty ? connBtoA.offsetControlY : null,
      );
    } else if (targetDirection == Direccion.unidireccional) {
      if (connBtoA.id.isNotEmpty) {
        updatedConexiones.remove(connBtoA.id);
      }

      final id1 = connAtoB.id.isNotEmpty ? connAtoB.id : 'conn_${now}_1';
      updatedConexiones[id1] = Conexion(
        id: id1,
        nodoOrigenId: nodeAId,
        nodoDestinoId: nodeBId,
        colorValue: colorValueAtoB ?? (connAtoB.id.isNotEmpty ? connAtoB.colorValue : 0xFF4CAF50),
        direccion: Direccion.unidireccional,
        atributos: atributosAtoB ?? (connAtoB.id.isNotEmpty && connAtoB.atributos.isNotEmpty ? connAtoB.atributos : fallbackAttrs),
        curvatura: connAtoB.id.isNotEmpty ? connAtoB.curvatura : null,
        loopAngle: connAtoB.id.isNotEmpty ? connAtoB.loopAngle : null,
        offsetControlX: connAtoB.id.isNotEmpty ? connAtoB.offsetControlX : null,
        offsetControlY: connAtoB.id.isNotEmpty ? connAtoB.offsetControlY : null,
      );
    } else {
      if (connBtoA.id.isNotEmpty) {
        updatedConexiones.remove(connBtoA.id);
      }

      final id1 = connAtoB.id.isNotEmpty ? connAtoB.id : 'conn_${now}_1';
      updatedConexiones[id1] = Conexion(
        id: id1,
        nodoOrigenId: nodeAId,
        nodoDestinoId: nodeBId,
        colorValue: colorValueAtoB ?? (connAtoB.id.isNotEmpty ? connAtoB.colorValue : 0xFF9E9E9E),
        direccion: Direccion.ninguna,
        atributos: atributosAtoB ?? (connAtoB.id.isNotEmpty && connAtoB.atributos.isNotEmpty ? connAtoB.atributos : fallbackAttrs),
        curvatura: connAtoB.id.isNotEmpty ? connAtoB.curvatura : null,
        loopAngle: connAtoB.id.isNotEmpty ? connAtoB.loopAngle : null,
        offsetControlX: connAtoB.id.isNotEmpty ? connAtoB.offsetControlX : null,
        offsetControlY: connAtoB.id.isNotEmpty ? connAtoB.offsetControlY : null,
      );
    }

    state = state.copyWith(conexiones: updatedConexiones);
  }

  /// Deletes a single connection line.
  /// In a bidirectional connection pair, deleting one line leaves the remaining reverse line
  /// intact as a single directional connection.
  void eliminarConexion(String id) {
    _recordUndoState();
    final targetConn = state.conexiones[id];
    final updatedConexiones = Map<String, Conexion>.from(state.conexiones);

    if (targetConn != null) {
      updatedConexiones.remove(id);
    }

    state = state.copyWith(conexiones: updatedConexiones);
  }

  /// Removes an attribute from all connections in the graph.
  void eliminarAtributoDeConexiones(String atributoId) {
    _recordUndoState();
    final updatedConexiones = <String, Conexion>{};
    for (final entry in state.conexiones.entries) {
      final conn = entry.value;
      final newAttrs = conn.atributos
          .where((av) => av.atributoId != atributoId)
          .toList();
      updatedConexiones[entry.key] = conn.copyWith(atributos: newAttrs);
    }
    state = state.copyWith(conexiones: updatedConexiones);
  }

  /// Empties all nodes and connections from the current graph while preserving history for undo.
  void vaciarGrafo() {
    _recordUndoState();
    state = const Grafo();
  }

  /// Clears all nodes, connections, resets state and undo/redo stacks, and sets saved checkpoint.
  void limpiarGrafo() {
    _undoStack.clear();
    _redoStack.clear();
    _lastSavedGraphState = const Grafo();
    state = const Grafo();
  }

  /// Replaces current graph state with a newly loaded graph, resets undo/redo stacks, and sets saved checkpoint.
  void cargarGrafo(Grafo nuevoGrafo) {
    _undoStack.clear();
    _redoStack.clear();
    _lastSavedGraphState = nuevoGrafo;
    state = nuevoGrafo;
  }
}

final grafoProvider = NotifierProvider<GrafoNotifier, Grafo>(() {
  return GrafoNotifier();
});

class LoadedGraphItemNotifier extends Notifier<SavedGraphItem?> {
  @override
  SavedGraphItem? build() => null;

  void setLoadedItem(SavedGraphItem? item) {
    state = item;
  }
}

final loadedGraphItemProvider =
    NotifierProvider<LoadedGraphItemNotifier, SavedGraphItem?>(() {
  return LoadedGraphItemNotifier();
});
