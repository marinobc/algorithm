class Atributo {
  final String id;
  final String nombre;

  const Atributo({required this.id, required this.nombre});

  Atributo copyWith({String? id, String? nombre}) {
    return Atributo(id: id ?? this.id, nombre: nombre ?? this.nombre);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nombre': nombre};
  }

  factory Atributo.fromJson(Map<String, dynamic> json) {
    return Atributo(id: json['id'] as String, nombre: json['nombre'] as String);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Atributo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nombre == other.nombre;

  @override
  int get hashCode => id.hashCode ^ nombre.hashCode;
}

class AtributoValor {
  final String atributoId;
  final String valor;

  const AtributoValor({required this.atributoId, required this.valor});

  AtributoValor copyWith({String? atributoId, String? valor}) {
    return AtributoValor(
      atributoId: atributoId ?? this.atributoId,
      valor: valor ?? this.valor,
    );
  }

  Map<String, dynamic> toJson() {
    return {'atributoId': atributoId, 'valor': valor};
  }

  factory AtributoValor.fromJson(Map<String, dynamic> json) {
    return AtributoValor(
      atributoId: json['atributoId'] as String,
      valor: json['valor'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AtributoValor &&
          runtimeType == other.runtimeType &&
          atributoId == other.atributoId &&
          valor == other.valor;

  @override
  int get hashCode => atributoId.hashCode ^ valor.hashCode;
}
