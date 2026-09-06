import 'atributo.dart';
import 'conexion.dart';
import 'nodo.dart';

class Grafo {
  final Map<String, Nodo> nodos;
  final Map<String, Conexion> conexiones;
  final List<Atributo> atributosGlobales;

  const Grafo({
    this.nodos = const {},
    this.conexiones = const {},
    this.atributosGlobales = const [
      Atributo(id: 'attr_valor', nombre: 'Valor'),
    ],
  });

  Grafo copyWith({
    Map<String, Nodo>? nodos,
    Map<String, Conexion>? conexiones,
    List<Atributo>? atributosGlobales,
  }) {
    return Grafo(
      nodos: nodos ?? this.nodos,
      conexiones: conexiones ?? this.conexiones,
      atributosGlobales: atributosGlobales ?? this.atributosGlobales,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nodos': nodos.map((key, value) => MapEntry(key, value.toJson())),
      'conexiones': conexiones.map((key, value) => MapEntry(key, value.toJson())),
      'atributosGlobales': atributosGlobales.map((a) => a.toJson()).toList(),
    };
  }

  factory Grafo.fromJson(Map<String, dynamic> json) {
    final rawNodos = json['nodos'] as Map<String, dynamic>? ?? {};
    final parsedNodos = rawNodos.map(
      (k, v) => MapEntry(k, Nodo.fromJson(v as Map<String, dynamic>)),
    );

    final rawConexiones = json['conexiones'] as Map<String, dynamic>? ?? {};
    final parsedConexiones = rawConexiones.map(
      (k, v) => MapEntry(k, Conexion.fromJson(v as Map<String, dynamic>)),
    );

    final rawAttrs = json['atributosGlobales'] as List<dynamic>?;
    final parsedAttrs = rawAttrs != null
        ? rawAttrs
            .map((a) => Atributo.fromJson(a as Map<String, dynamic>))
            .toList()
        : const [Atributo(id: 'attr_valor', nombre: 'Valor')];

    return Grafo(
      nodos: parsedNodos,
      conexiones: parsedConexiones,
      atributosGlobales: parsedAttrs,
    );
  }

  List<Conexion> obtenerConexionesDeNodo(String nodoId) {
    return conexiones.values.where((c) {
      return c.nodoOrigenId == nodoId || c.nodoDestinoId == nodoId;
    }).toList();
  }

  List<Nodo> obtenerVecinos(String nodoId) {
    final result = <Nodo>[];
    for (final c in conexiones.values) {
      if (c.nodoOrigenId == nodoId) {
        final destino = nodos[c.nodoDestinoId];
        if (destino != null) result.add(destino);
      } else if (c.nodoDestinoId == nodoId) {
        final origen = nodos[c.nodoOrigenId];
        if (origen != null) result.add(origen);
      }
    }
    return result;
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Grafo || runtimeType != other.runtimeType) return false;
    return _mapEquals(nodos, other.nodos) &&
        _mapEquals(conexiones, other.conexiones) &&
        _listEquals(atributosGlobales, other.atributosGlobales);
  }

  @override
  int get hashCode =>
      _mapHash(nodos) ^ _mapHash(conexiones) ^ _listHash(atributosGlobales);

  static bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static int _mapHash<K, V>(Map<K, V> map) {
    int hash = 0;
    for (final entry in map.entries) {
      hash ^= entry.key.hashCode ^ entry.value.hashCode;
    }
    return hash;
  }

  static int _listHash<T>(List<T> list) {
    int hash = 0;
    for (final item in list) {
      hash ^= item.hashCode;
    }
    return hash;
  }
}

