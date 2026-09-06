import 'package:flutter_riverpod/flutter_riverpod.dart';

class EstadoCreacion {
  final String? nuevoNodoIdPendienteConexion; // Node created that requires connection
  final String? primerNodoSeleccionado; // Node 1 selected for new connection
  final String? segundoNodoSeleccionado; // Node 2 selected for new connection
  final bool mostrandoDialogoDireccion;

  const EstadoCreacion({
    this.nuevoNodoIdPendienteConexion,
    this.primerNodoSeleccionado,
    this.segundoNodoSeleccionado,
    this.mostrandoDialogoDireccion = false,
  });

  bool get requiereConexionParaNuevoNodo =>
      nuevoNodoIdPendienteConexion != null;

  EstadoCreacion copyWith({
    String? nuevoNodoIdPendienteConexion,
    String? primerNodoSeleccionado,
    String? segundoNodoSeleccionado,
    bool? mostrandoDialogoDireccion,
    bool clearNuevoNodo = false,
    bool clearSelecciones = false,
  }) {
    return EstadoCreacion(
      nuevoNodoIdPendienteConexion: clearNuevoNodo
          ? null
          : (nuevoNodoIdPendienteConexion ?? this.nuevoNodoIdPendienteConexion),
      primerNodoSeleccionado: clearSelecciones
          ? null
          : (primerNodoSeleccionado ?? this.primerNodoSeleccionado),
      segundoNodoSeleccionado: clearSelecciones
          ? null
          : (segundoNodoSeleccionado ?? this.segundoNodoSeleccionado),
      mostrandoDialogoDireccion:
          mostrandoDialogoDireccion ?? this.mostrandoDialogoDireccion,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EstadoCreacion &&
        other.nuevoNodoIdPendienteConexion == nuevoNodoIdPendienteConexion &&
        other.primerNodoSeleccionado == primerNodoSeleccionado &&
        other.segundoNodoSeleccionado == segundoNodoSeleccionado &&
        other.mostrandoDialogoDireccion == mostrandoDialogoDireccion;
  }

  @override
  int get hashCode => Object.hash(
        nuevoNodoIdPendienteConexion,
        primerNodoSeleccionado,
        segundoNodoSeleccionado,
        mostrandoDialogoDireccion,
      );

  static const initial = EstadoCreacion();
}

class CreacionNotifier extends Notifier<EstadoCreacion> {
  @override
  EstadoCreacion build() => EstadoCreacion.initial;

  void setNuevoNodoPendiente(String nodoId) {
    state = state.copyWith(nuevoNodoIdPendienteConexion: nodoId);
  }

  void seleccionarPrimerNodo(String nodoId) {
    state = state.copyWith(primerNodoSeleccionado: nodoId);
  }

  void seleccionarSegundoNodo(String nodoId) {
    state = state.copyWith(
      segundoNodoSeleccionado: nodoId,
      mostrandoDialogoDireccion: true,
    );
  }

  void cerrarDialogoDireccion() {
    state = state.copyWith(
      mostrandoDialogoDireccion: false,
      clearSelecciones: true,
    );
  }

  void reset() {
    state = EstadoCreacion.initial;
  }
}

final estadoCreacionProvider =
    NotifierProvider<CreacionNotifier, EstadoCreacion>(() {
  return CreacionNotifier();
});
