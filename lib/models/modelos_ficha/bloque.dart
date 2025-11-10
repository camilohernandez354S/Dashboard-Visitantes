import 'sede.dart';

/// Bloque físico dentro de una sede.
class Bloque {
  const Bloque({
    required this.id,
    required this.nombre,
    required this.codigo,
    this.descripcion,
    this.sede,
  });

  final int id;
  final String nombre;
  final String codigo;
  final String? descripcion;
  final Sede? sede;

  factory Bloque.fromJson(Map<String, dynamic> json) {
    return Bloque(
      id: _parseInt(json['id']),
      nombre: (json['nombre'] ?? json['name'] ?? '').toString(),
      codigo: (json['codigo'] ?? json['code'] ?? '').toString(),
      descripcion: _normalize(json['descripcion'] ?? json['description']),
      sede:
          json['sede'] is Map<String, dynamic>
              ? Sede.fromJson(json['sede'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nombre': nombre,
      'codigo': codigo,
      if (descripcion != null) 'descripcion': descripcion,
      if (sede != null) 'sede': sede!.toJson(),
    };
  }

  Bloque copyWith({
    int? id,
    String? nombre,
    String? codigo,
    String? descripcion,
    Sede? sede,
  }) {
    return Bloque(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      codigo: codigo ?? this.codigo,
      descripcion: descripcion ?? this.descripcion,
      sede: sede ?? this.sede,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static String? _normalize(dynamic value) {
    if (value == null) return null;
    final result = value.toString().trim();
    return result.isEmpty ? null : result;
  }
}
