import 'bloque.dart';
import 'piso.dart';
import 'sede.dart';

/// Ambiente físico donde se desarrolla la formación.
class Ambiente {
  const Ambiente({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.capacidad,
    this.tipo,
    this.sede,
    this.bloque,
    this.piso,
  });

  final int id;
  final String codigo;
  final String nombre;
  final int? capacidad;
  final String? tipo;
  final Sede? sede;
  final Bloque? bloque;
  final Piso? piso;

  factory Ambiente.fromJson(Map<String, dynamic> json) {
    return Ambiente(
      id: _parseInt(json['id']),
      codigo: (json['codigo'] ?? json['code'] ?? '').toString(),
      nombre: (json['nombre'] ?? json['name'] ?? '').toString(),
      capacidad: _parseNullableInt(json['capacidad']),
      tipo: _normalize(json['tipo'] ?? json['type']),
      sede:
          json['sede'] is Map<String, dynamic>
              ? Sede.fromJson(json['sede'] as Map<String, dynamic>)
              : null,
      bloque:
          json['bloque'] is Map<String, dynamic>
              ? Bloque.fromJson(json['bloque'] as Map<String, dynamic>)
              : null,
      piso:
          json['piso'] is Map<String, dynamic>
              ? Piso.fromJson(json['piso'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      if (capacidad != null) 'capacidad': capacidad,
      if (tipo != null) 'tipo': tipo,
      if (sede != null) 'sede': sede!.toJson(),
      if (bloque != null) 'bloque': bloque!.toJson(),
      if (piso != null) 'piso': piso!.toJson(),
    };
  }

  Ambiente copyWith({
    int? id,
    String? codigo,
    String? nombre,
    int? capacidad,
    String? tipo,
    Sede? sede,
    Bloque? bloque,
    Piso? piso,
  }) {
    return Ambiente(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      capacidad: capacidad ?? this.capacidad,
      tipo: tipo ?? this.tipo,
      sede: sede ?? this.sede,
      bloque: bloque ?? this.bloque,
      piso: piso ?? this.piso,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static String? _normalize(dynamic value) {
    if (value == null) return null;
    final result = value.toString().trim();
    return result.isEmpty ? null : result;
  }
}
