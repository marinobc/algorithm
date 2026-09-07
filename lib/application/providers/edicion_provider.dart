import 'package:flutter_riverpod/flutter_riverpod.dart';

class EstadoEdicion {
  final String? itemSeleccionadoId; // Node ID or Connection ID
  final bool esNodo; // true for Node, false for Connection
  final bool tieneCambiosSinGuardar;

  const EstadoEdicion({
    this.itemSeleccionadoId,
    this.esNodo = true,
    this.tieneCambiosSinGuardar = false,
  });

  EstadoEdicion copyWith({
    String? itemSeleccionadoId,
    bool? esNodo,
    bool? tieneCambiosSinGuardar,
    bool clearSeleccion = false,
  }) {
    return EstadoEdicion(
      itemSeleccionadoId: clearSeleccion
          ? null
          : (itemSeleccionadoId ?? this.itemSeleccionadoId),
      esNodo: esNodo ?? this.esNodo,
      tieneCambiosSinGuardar:
          tieneCambiosSinGuardar ?? this.tieneCambiosSinGuardar,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EstadoEdicion &&
        other.itemSeleccionadoId == itemSeleccionadoId &&
        other.esNodo == esNodo &&
        other.tieneCambiosSinGuardar == tieneCambiosSinGuardar;
  }

  @override
  int get hashCode =>
      Object.hash(itemSeleccionadoId, esNodo, tieneCambiosSinGuardar);

  static const initial = EstadoEdicion();
}

class EdicionNotifier extends Notifier<EstadoEdicion> {
  @override
  EstadoEdicion build() => EstadoEdicion.initial;

  void seleccionarNodo(String nodoId) {
    state = state.copyWith(itemSeleccionadoId: nodoId, esNodo: true);
  }

  void seleccionarConexion(String conexionId) {
    state = state.copyWith(itemSeleccionadoId: conexionId, esNodo: false);
  }

  void marcarCambioSinGuardar() {
    if (!state.tieneCambiosSinGuardar) {
      state = state.copyWith(tieneCambiosSinGuardar: true);
    }
  }

  void desmarcarCambiosSinGuardar() {
    state = state.copyWith(tieneCambiosSinGuardar: false);
  }

  void deseleccionar() {
    state = state.copyWith(clearSeleccion: true);
  }

  void reset() {
    state = EstadoEdicion.initial;
  }
}

final estadoEdicionProvider = NotifierProvider<EdicionNotifier, EstadoEdicion>(
  () {
    return EdicionNotifier();
  },
);
