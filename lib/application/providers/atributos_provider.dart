import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/atributo.dart';

class AtributosNotifier extends Notifier<List<Atributo>> {
  @override
  List<Atributo> build() {
    return const [Atributo(id: 'attr_valor', nombre: 'Valor')];
  }

  void agregarAtributo(String nombre) {
    final newId = 'attr_${DateTime.now().millisecondsSinceEpoch}';
    state = [...state, Atributo(id: newId, nombre: nombre)];
  }

  void renombrarAtributo(String id, String nuevoNombre) {
    state = [
      for (final a in state)
        if (a.id == id) a.copyWith(nombre: nuevoNombre) else a,
    ];
  }

  void eliminarAtributo(String id) {
    state = state.where((a) => a.id != id).toList();
  }

  void reset() {
    state = const [Atributo(id: 'attr_valor', nombre: 'Valor')];
  }
}

final atributosGlobalesProvider =
    NotifierProvider<AtributosNotifier, List<Atributo>>(() {
      return AtributosNotifier();
    });
