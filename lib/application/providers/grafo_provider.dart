import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/atributo.dart';
import '../../domain/models/conexion.dart';
import '../../domain/models/direccion.dart';
import '../../domain/models/grafo.dart';
import '../../domain/models/nodo.dart';
import '../../domain/models/modo_tipo_nodo.dart';
import '../../domain/services/graph_geometry.dart';
import 'config_provider.dart';
import 'grafo_undo_tracker.dart';

export 'loaded_graph_provider.dart';

class GrafoNotifier extends Notifier<Grafo> {
  final GrafoUndoTracker _undoTracker = GrafoUndoTracker();

  bool get puedeDeshacer => _undoTracker.puedeDeshacer;
  bool get puedeRehacer => _undoTracker.puedeRehacer;
  bool get tieneCambiosSinGuardar => _undoTracker.tieneCambiosSinGuardar(state);

  void marcarPuntoGuardado() => _undoTracker.marcarPuntoGuardado(state);

  void _recordUndoState() => _undoTracker.recordUndoState(state);

  bool deshacer() {
    final prev = _undoTracker.deshacer(state);
    if (prev == null) return false;
    state = prev;
    return true;
  }

  bool rehacer() {
    final next = _undoTracker.rehacer(state);
    if (next == null) return false;
    state = next;
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
      return HSVColor.fromAHSV(
        1.0,
        initialHue,
        0.85,
        0.95,
      ).toColor().toARGB32();
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
    String? rol,
  }) {
    _recordUndoState();
    final clamped = GraphGeometry.clampNodePosition(x, y);
    final nextNumber = state.nodos.length + 1;
    final nodeName = nombre ?? 'Nodo $nextNumber';
    final nodeId =
        'nodo_${DateTime.now().microsecondsSinceEpoch}_${_nodeSeq++}';
    final nodeColor = colorValue ?? generateMaximallyDistinctColor();

    final nuevoNodo = Nodo(
      id: nodeId,
      nombre: nodeName,
      colorValue: nodeColor,
      x: clamped.x,
      y: clamped.y,
      rol: rol,
    );

    final updatedNodos = Map<String, Nodo>.from(state.nodos)
      ..[nodeId] = nuevoNodo;
    state = state.copyWith(nodos: updatedNodos);
    return nuevoNodo;
  }

  /// Adds a fully-prepared Nodo instance to the graph.
  Nodo agregarNodoInstancia(Nodo nodo) {
    _recordUndoState();
    final clamped = GraphGeometry.clampNodePosition(nodo.x, nodo.y);
    final clampedNode = nodo.copyWith(x: clamped.x, y: clamped.y);
    final updatedNodos = Map<String, Nodo>.from(state.nodos)
      ..[clampedNode.id] = clampedNode;
    state = state.copyWith(nodos: updatedNodos);
    return clampedNode;
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
    final updatedNodos = Map<String, Nodo>.from(state.nodos)
      ..[id] = updatedNodo;
    state = state.copyWith(nodos: updatedNodos);
  }

  /// Updates node properties (name, color, rol).
  void actualizarNodo(
    String id, {
    String? nombre,
    int? colorValue,
    String? rol,
    bool clearRol = false,
    double? cantidad,
    bool clearCantidad = false,
  }) {
    final nodo = state.nodos[id];
    if (nodo == null) return;
    _recordUndoState();
    final updatedNodo = nodo.copyWith(
      nombre: nombre ?? nodo.nombre,
      colorValue: colorValue ?? nodo.colorValue,
      rol: clearRol ? null : (rol ?? nodo.rol),
      clearRol: clearRol,
      cantidad: cantidad,
      clearCantidad: clearCantidad,
    );
    final updatedNodos = Map<String, Nodo>.from(state.nodos)
      ..[id] = updatedNodo;
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

    state = state.copyWith(nodos: updatedNodos, conexiones: updatedConexiones);

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
        orElse: () => const Conexion(
          id: '',
          nodoOrigenId: '',
          nodoDestinoId: '',
          colorValue: 0,
        ),
      );
      if (existingLoop.id.isNotEmpty) {
        return [];
      }
    } else {
      final existingPair = state.conexiones.values
          .where(
            (c) =>
                (c.nodoOrigenId == origenId && c.nodoDestinoId == destinoId) ||
                (c.nodoOrigenId == destinoId && c.nodoDestinoId == origenId),
          )
          .toList();

      if (existingPair.length >= 2) {
        return [];
      } else if (existingPair.length == 1) {
        // Connecting the same two nodes twice converts the relationship to bidirectional!
        actualizarParejaConexiones(
          nodeAId: origenId,
          nodeBId: destinoId,
          targetDirection: Direccion.bidireccional,
        );
        return state.conexiones.values
            .where(
              (c) =>
                  (c.nodoOrigenId == origenId &&
                      c.nodoDestinoId == destinoId) ||
                  (c.nodoOrigenId == destinoId && c.nodoDestinoId == origenId),
            )
            .toList();
      }
    }

    const validDefaultVal = '1';

    final defaultAttrs = <AtributoValor>[];
    if (atributos != null && atributos.isNotEmpty) {
      defaultAttrs.addAll(atributos);
    }

    final hasValAttr = defaultAttrs.any((a) => a.atributoId == 'attr_valor');
    if (!hasValAttr) {
      defaultAttrs.insert(
        0,
        AtributoValor(atributoId: 'attr_valor', valor: validDefaultVal),
      );
    } else {
      for (int i = 0; i < defaultAttrs.length; i++) {
        if (defaultAttrs[i].atributoId == 'attr_valor') {
          final valStr = defaultAttrs[i].valor.trim();
          final numVal = double.tryParse(valStr);
          if (valStr.isEmpty || numVal == null || numVal <= 0) {
            defaultAttrs[i] = AtributoValor(
              atributoId: 'attr_valor',
              valor: validDefaultVal,
            );
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
      final connColor =
          colorValue ??
          (targetDireccion == Direccion.ninguna
              ? 0xFF9E9E9E // Soft gray for non-directional
              : (origNode?.colorValue ??
                    0xFF00E676)); // Origin node color for directional

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

      final config = ref.read(configProvider);
      var updatedNodos = state.nodos;
      if (config.modoTipoNodo == ModoTipoNodo.detectado &&
          origNode != null &&
          destNode != null) {
        var newOrig = origNode;
        var newDest = destNode;
        bool nodeChanged = false;

        if (newOrig.rol == null) {
          newOrig = newOrig.copyWith(rol: 'origen');
          nodeChanged = true;
        }
        if (newDest.rol == null) {
          newDest = newDest.copyWith(rol: 'destino');
          nodeChanged = true;
        }

        if (nodeChanged) {
          final mutableNodos = Map<String, Nodo>.from(state.nodos);
          mutableNodos[newOrig.id] = newOrig;
          mutableNodos[newDest.id] = newDest;
          updatedNodos = mutableNodos;
        }
      }

      state = state.copyWith(
        nodos: updatedNodos,
        conexiones: updatedConexiones,
      );
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
      orElse: () => const Conexion(
        id: '',
        nodoOrigenId: '',
        nodoDestinoId: '',
        colorValue: 0,
      ),
    );

    final connBtoA = updatedConexiones.values.firstWhere(
      (c) => c.nodoOrigenId == nodeBId && c.nodoDestinoId == nodeAId,
      orElse: () => const Conexion(
        id: '',
        nodoOrigenId: '',
        nodoDestinoId: '',
        colorValue: 0,
      ),
    );

    final now = DateTime.now().microsecondsSinceEpoch;

    const validDefaultVal = '1';
    final fallbackAttrs = [
      AtributoValor(atributoId: 'attr_valor', valor: validDefaultVal),
    ];

    if (targetDirection == Direccion.bidireccional) {
      final id1 = connAtoB.id.isNotEmpty ? connAtoB.id : 'conn_${now}_1';
      final id2 = connBtoA.id.isNotEmpty ? connBtoA.id : 'conn_${now}_2';

      updatedConexiones[id1] = Conexion(
        id: id1,
        nodoOrigenId: nodeAId,
        nodoDestinoId: nodeBId,
        colorValue:
            colorValueAtoB ??
            (connAtoB.id.isNotEmpty ? connAtoB.colorValue : 0xFF4CAF50),
        direccion: Direccion.unidireccional,
        atributos:
            atributosAtoB ??
            (connAtoB.id.isNotEmpty && connAtoB.atributos.isNotEmpty
                ? connAtoB.atributos
                : fallbackAttrs),
        curvatura: connAtoB.id.isNotEmpty ? connAtoB.curvatura : null,
        loopAngle: connAtoB.id.isNotEmpty ? connAtoB.loopAngle : null,
        offsetControlX: connAtoB.id.isNotEmpty ? connAtoB.offsetControlX : null,
        offsetControlY: connAtoB.id.isNotEmpty ? connAtoB.offsetControlY : null,
      );

      updatedConexiones[id2] = Conexion(
        id: id2,
        nodoOrigenId: nodeBId,
        nodoDestinoId: nodeAId,
        colorValue:
            colorValueBtoA ??
            (connBtoA.id.isNotEmpty ? connBtoA.colorValue : 0xFFFF9800),
        direccion: Direccion.unidireccional,
        atributos:
            atributosBtoA ??
            (connBtoA.id.isNotEmpty && connBtoA.atributos.isNotEmpty
                ? connBtoA.atributos
                : fallbackAttrs),
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
        colorValue:
            colorValueAtoB ??
            (connAtoB.id.isNotEmpty ? connAtoB.colorValue : 0xFF4CAF50),
        direccion: Direccion.unidireccional,
        atributos:
            atributosAtoB ??
            (connAtoB.id.isNotEmpty && connAtoB.atributos.isNotEmpty
                ? connAtoB.atributos
                : fallbackAttrs),
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
        colorValue:
            colorValueAtoB ??
            (connAtoB.id.isNotEmpty ? connAtoB.colorValue : 0xFF9E9E9E),
        direccion: Direccion.ninguna,
        atributos:
            atributosAtoB ??
            (connAtoB.id.isNotEmpty && connAtoB.atributos.isNotEmpty
                ? connAtoB.atributos
                : fallbackAttrs),
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

    final config = ref.read(configProvider);
    var updatedNodos = state.nodos;

    if (config.modoTipoNodo == ModoTipoNodo.detectado) {
      final mutableNodos = Map<String, Nodo>.from(state.nodos);
      bool changed = false;

      for (final node in state.nodos.values) {
        if (node.rol == null) continue;

        final hasRemainingConns = updatedConexiones.values.any(
          (c) => c.nodoOrigenId == node.id || c.nodoDestinoId == node.id,
        );

        if (!hasRemainingConns) {
          mutableNodos[node.id] = node.copyWith(clearRol: true);
          changed = true;
        }
      }

      if (changed) {
        updatedNodos = mutableNodos;
      }
    }

    state = state.copyWith(nodos: updatedNodos, conexiones: updatedConexiones);
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

  /// Replaces the graph as one undoable operation.
  void reemplazarGrafo(Grafo grafo) {
    _recordUndoState();
    state = grafo;
  }

  /// Clears all nodes, connections, resets state and undo/redo stacks, and sets saved checkpoint.
  void limpiarGrafo() {
    _undoTracker.clear(const Grafo());
    state = const Grafo();
  }

  /// Replaces current graph state with a newly loaded graph, resets undo/redo stacks, and sets saved checkpoint.
  void cargarGrafo(Grafo nuevoGrafo) {
    _undoTracker.clear(nuevoGrafo);
    state = nuevoGrafo;
  }
}

final grafoProvider = NotifierProvider<GrafoNotifier, Grafo>(() {
  return GrafoNotifier();
});
