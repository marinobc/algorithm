class Nodo {
  final String id;
  final String? nombre;
  final int colorValue; // ARGB 32-bit int color value
  final double x;
  final double y;
  final double radius;

  static const double defaultRadius = 32.0; // Default diameter = 64.0

  const Nodo({
    required this.id,
    this.nombre,
    required this.colorValue,
    required this.x,
    required this.y,
    this.radius = defaultRadius,
  });

  double get diameter => radius * 2;

  Nodo copyWith({
    String? id,
    String? nombre,
    int? colorValue,
    double? x,
    double? y,
    double? radius,
  }) {
    return Nodo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      colorValue: colorValue ?? this.colorValue,
      x: x ?? this.x,
      y: y ?? this.y,
      radius: radius ?? this.radius,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (nombre != null) 'nombre': nombre,
      'colorValue': colorValue,
      'x': x,
      'y': y,
      'radius': radius,
    };
  }

  factory Nodo.fromJson(Map<String, dynamic> json) {
    return Nodo(
      id: json['id'] as String,
      nombre: json['nombre'] as String?,
      colorValue: json['colorValue'] as int,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      radius: (json['radius'] as num?)?.toDouble() ?? defaultRadius,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Nodo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nombre == other.nombre &&
          colorValue == other.colorValue &&
          x == other.x &&
          y == other.y &&
          radius == other.radius;

  @override
  int get hashCode =>
      id.hashCode ^
      nombre.hashCode ^
      colorValue.hashCode ^
      x.hashCode ^
      y.hashCode ^
      radius.hashCode;
}

