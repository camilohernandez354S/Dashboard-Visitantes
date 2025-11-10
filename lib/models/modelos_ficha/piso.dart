import 'bloque.dart';

/// Piso o nivel dentro de un bloque.
class Piso {
  const Piso({
    required this.id,
    required this.numero,
    this.descripcion,
    this.bloque,
  });

  final int id;
  final int numero;
  final String? descripcion;
  final Bloque? bloque;

  factory Piso.fromJson(Map<String, dynamic> json) {
    return Piso(
      id: _parseInt(json['id']),
      numero: _parseInt(json['numero'] ?? json['level'] ?? 0),
      descripcion: _normalize(json['descripcion'] ?? json['description']),
      bloque:
          json['bloque'] is Map<String, dynamic>
              ? Bloque.fromJson(json['bloque'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'numero': numero,
      if (descripcion != null) 'descripcion': descripcion,
      if (bloque != null) 'bloque': bloque!.toJson(),
    };
  }

  Piso copyWith({int? id, int? numero, String? descripcion, Bloque? bloque}) {
    return Piso(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      descripcion: descripcion ?? this.descripcion,
      bloque: bloque ?? this.bloque,
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
