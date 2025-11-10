/// Información física de una sede SENA.
class Sede {
  const Sede({
    required this.id,
    required this.nombre,
    this.direccion,
    this.ciudad,
    this.departamento,
  });

  final int id;
  final String nombre;
  final String? direccion;
  final String? ciudad;
  final String? departamento;

  factory Sede.fromJson(Map<String, dynamic> json) {
    return Sede(
      id: _parseInt(json['id']),
      nombre: (json['nombre'] ?? json['name'] ?? '').toString(),
      direccion: _normalize(json['direccion'] ?? json['address']),
      ciudad: _normalize(json['ciudad'] ?? json['city']),
      departamento: _normalize(json['departamento'] ?? json['state']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nombre': nombre,
      if (direccion != null) 'direccion': direccion,
      if (ciudad != null) 'ciudad': ciudad,
      if (departamento != null) 'departamento': departamento,
    };
  }

  Sede copyWith({
    int? id,
    String? nombre,
    String? direccion,
    String? ciudad,
    String? departamento,
  }) {
    return Sede(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      ciudad: ciudad ?? this.ciudad,
      departamento: departamento ?? this.departamento,
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
