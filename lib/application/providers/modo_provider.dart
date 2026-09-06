import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'creacion_provider.dart';
import 'edicion_provider.dart';

enum ModoActivo { ninguno, anadir, modificar, eliminar }

enum TipoObjetivo { nodo, conexion }

class ModoNotifier extends Notifier<ModoActivo> {
  @override
  ModoActivo build() => ModoActivo.anadir;

  void seleccionarModo(ModoActivo nuevoModo) {
    if (state == nuevoModo) {
      state = ModoActivo.anadir;
    } else {
      state = nuevoModo;
    }
    ref.read(tipoObjetivoProvider.notifier).reset();
    ref.read(estadoEdicionProvider.notifier).deseleccionar();
    ref.read(estadoCreacionProvider.notifier).reset();
  }

  void reset() {
    state = ModoActivo.anadir;
    ref.read(tipoObjetivoProvider.notifier).reset();
    ref.read(estadoEdicionProvider.notifier).deseleccionar();
    ref.read(estadoCreacionProvider.notifier).reset();
  }
}

final modoActivoProvider = NotifierProvider<ModoNotifier, ModoActivo>(() {
  return ModoNotifier();
});

class TipoObjetivoNotifier extends Notifier<TipoObjetivo> {
  @override
  TipoObjetivo build() => TipoObjetivo.nodo;

  void seleccionarTipo(TipoObjetivo nuevoTipo) {
    state = nuevoTipo;
  }

  void reset() {
    state = TipoObjetivo.nodo;
  }
}

final tipoObjetivoProvider =
    NotifierProvider<TipoObjetivoNotifier, TipoObjetivo>(() {
      return TipoObjetivoNotifier();
    });
