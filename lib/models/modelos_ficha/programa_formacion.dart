import 'jornada_formacion.dart';
import 'modalidad_formacion.dart';

/// Datos descriptivos de un programa de formación.
class ProgramaFormacion {
  const ProgramaFormacion({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.version,
    this.modalidad = ModalidadFormacion.presencial,
    this.jornada,
  });

  final int id;
  final String codigo;
  final String nombre;
  final int? version;
  final ModalidadFormacion modalidad;
  final JornadaFormacion? jornada;

  factory ProgramaFormacion.fromJson(Map<String, dynamic> json) {
    return ProgramaFormacion(
      id: _parseInt(json['id']),
      codigo: (json['codigo'] ?? json['code'] ?? '').toString(),
      nombre: (json['nombre'] ?? json['name'] ?? '').toString(),
      version: _parseNullableInt(json['version']),
      modalidad: ModalidadFormacionUtils.fromJson(json['modalidad']),
      jornada:
          json['jornada'] is Map<String, dynamic>
              ? JornadaFormacion.fromJson(
                json['jornada'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      if (version != null) 'version': version,
      'modalidad': modalidad.toJson(),
      if (jornada != null) 'jornada': jornada!.toJson(),
    };
  }

  ProgramaFormacion copyWith({
    int? id,
    String? codigo,
    String? nombre,
    int? version,
    ModalidadFormacion? modalidad,
    JornadaFormacion? jornada,
  }) {
    return ProgramaFormacion(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      version: version ?? this.version,
      modalidad: modalidad ?? this.modalidad,
      jornada: jornada ?? this.jornada,
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
}
