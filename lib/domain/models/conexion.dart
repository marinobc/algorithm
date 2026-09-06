import 'atributo.dart';
import 'direccion.dart';

class Conexion {
  final String id;
  final String nodoOrigenId;
  final String nodoDestinoId;
  final int colorValue;
  final Direccion direccion;
  final List<AtributoValor> atributos;
  final double? curvatura;
  final double? loopAngle;
  final double? offsetControlX;
  final double? offsetControlY;

  const Conexion({
    required this.id,
    required this.nodoOrigenId,
    required this.nodoDestinoId,
    required this.colorValue,
    this.direccion = Direccion.ninguna,
    this.atributos = const [],
    this.curvatura,
    this.loopAngle,
    this.offsetControlX,
    this.offsetControlY,
  });

  Conexion copyWith({
    String? id,
    String? nodoOrigenId,
    String? nodoDestinoId,
    int? colorValue,
    Direccion? direccion,
    List<AtributoValor>? atributos,
    double? curvatura,
    double? loopAngle,
    double? offsetControlX,
    double? offsetControlY,
  }) {
    return Conexion(
      id: id ?? this.id,
      nodoOrigenId: nodoOrigenId ?? this.nodoOrigenId,
      nodoDestinoId: nodoDestinoId ?? this.nodoDestinoId,
      colorValue: colorValue ?? this.colorValue,
      direccion: direccion ?? this.direccion,
      atributos: atributos ?? this.atributos,
      curvatura: curvatura ?? this.curvatura,
      loopAngle: loopAngle ?? this.loopAngle,
      offsetControlX: offsetControlX ?? this.offsetControlX,
      offsetControlY: offsetControlY ?? this.offsetControlY,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nodoOrigenId': nodoOrigenId,
      'nodoDestinoId': nodoDestinoId,
      'colorValue': colorValue,
      'direccion': direccion.name,
      'atributos': atributos.map((a) => a.toJson()).toList(),
      if (curvatura != null) 'curvatura': curvatura,
      if (loopAngle != null) 'loopAngle': loopAngle,
      if (offsetControlX != null) 'offsetControlX': offsetControlX,
      if (offsetControlY != null) 'offsetControlY': offsetControlY,
    };
  }

  factory Conexion.fromJson(Map<String, dynamic> json) {
    Direccion parsedDireccion = Direccion.ninguna;
    final dirStr = json['direccion'] as String?;
    if (dirStr != null) {
      for (final d in Direccion.values) {
        if (d.name == dirStr) {
          parsedDireccion = d;
          break;
        }
      }
    }

    final rawAttrs = json['atributos'] as List<dynamic>?;
    final parsedAttrs = rawAttrs != null
        ? rawAttrs
            .map((a) => AtributoValor.fromJson(a as Map<String, dynamic>))
            .toList()
        : <AtributoValor>[];

    return Conexion(
      id: json['id'] as String,
      nodoOrigenId: json['nodoOrigenId'] as String,
      nodoDestinoId: json['nodoDestinoId'] as String,
      colorValue: json['colorValue'] as int,
      direccion: parsedDireccion,
      atributos: parsedAttrs,
      curvatura: (json['curvatura'] as num?)?.toDouble(),
      loopAngle: (json['loopAngle'] as num?)?.toDouble(),
      offsetControlX: (json['offsetControlX'] as num?)?.toDouble(),
      offsetControlY: (json['offsetControlY'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Conexion &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nodoOrigenId == other.nodoOrigenId &&
          nodoDestinoId == other.nodoDestinoId &&
          colorValue == other.colorValue &&
          direccion == other.direccion &&
          curvatura == other.curvatura &&
          loopAngle == other.loopAngle &&
          offsetControlX == other.offsetControlX &&
          offsetControlY == other.offsetControlY &&
          _listEquals(atributos, other.atributos);

  @override
  int get hashCode =>
      id.hashCode ^
      nodoOrigenId.hashCode ^
      nodoDestinoId.hashCode ^
      colorValue.hashCode ^
      direccion.hashCode ^
      curvatura.hashCode ^
      loopAngle.hashCode ^
      offsetControlX.hashCode ^
      offsetControlY.hashCode;

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

