import 'ambiente.dart';
import 'dia.dart';
import 'dias_formacion.dart';
import 'instructor_asignado.dart';
import 'instructor_principal.dart';
import 'programa_formacion.dart';
import 'modalidad_formacion.dart';
import 'jornada_formacion.dart';

/// Entidad principal que representa una ficha de formación SENA.
class Ficha {
  const Ficha({
    required this.id,
    required this.codigo,
    required this.programa,
    required this.diasFormacion,
    this.fechaInicio,
    this.fechaFin,
    this.cupo,
    this.ambiente,
    this.instructorPrincipal,
    this.instructoresApoyo = const [],
  });

  final int id;
  final String codigo;
  final ProgramaFormacion programa;
  final DiasFormacion diasFormacion;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final int? cupo;
  final Ambiente? ambiente;
  final InstructorPrincipal? instructorPrincipal;
  final List<InstructorAsignado> instructoresApoyo;

  ModalidadFormacion get modalidad => programa.modalidad;
  JornadaFormacion? get jornada => programa.jornada;

  factory Ficha.fromJson(Map<String, dynamic> json) {
    final dynamic programaRaw = json['programa'] ?? json['programaFormacion'];
    final dynamic ambienteRaw = json['ambiente'] ?? json['ambienteFormacion'];
    final dynamic instructorPrincipalRaw =
        json['instructorPrincipal'] ?? json['instructor_principal'];
    final dynamic instructoresRaw =
        json['instructores'] ?? json['instructoresApoyo'];
    final dynamic diasRaw =
        json['dias'] ?? json['diasFormacion'] ?? json['dias_formacion'];

    return Ficha(
      id: _parseInt(json['id']),
      codigo: (json['codigo'] ?? json['ficha'] ?? '').toString(),
      programa:
          programaRaw is Map<String, dynamic>
              ? ProgramaFormacion.fromJson(programaRaw)
              : ProgramaFormacion(
                id: 0,
                codigo: (json['codigoPrograma'] ?? '').toString(),
                nombre:
                    (json['programa'] ?? json['nombrePrograma'] ?? '')
                        .toString(),
              ),
      diasFormacion:
          diasRaw != null
              ? DiasFormacion.fromJson(diasRaw)
              : DiasFormacion({DiaSemana.lunes, DiaSemana.martes}),
      fechaInicio: _parseDate(json['fechaInicio'] ?? json['inicio']),
      fechaFin: _parseDate(json['fechaFin'] ?? json['fin']),
      cupo: _parseNullableInt(json['cupo'] ?? json['capacidad']),
      ambiente:
          ambienteRaw is Map<String, dynamic>
              ? Ambiente.fromJson(ambienteRaw)
              : null,
      instructorPrincipal:
          instructorPrincipalRaw is Map<String, dynamic>
              ? InstructorPrincipal.fromJson(instructorPrincipalRaw)
              : null,
      instructoresApoyo: _parseInstructores(instructoresRaw),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'codigo': codigo,
      'programa': programa.toJson(),
      'diasFormacion': diasFormacion.toJson(),
      if (fechaInicio != null) 'fechaInicio': fechaInicio!.toIso8601String(),
      if (fechaFin != null) 'fechaFin': fechaFin!.toIso8601String(),
      if (cupo != null) 'cupo': cupo,
      if (ambiente != null) 'ambiente': ambiente!.toJson(),
      if (instructorPrincipal != null)
        'instructorPrincipal': instructorPrincipal!.toJson(),
      if (instructoresApoyo.isNotEmpty)
        'instructoresApoyo': instructoresApoyo.map((e) => e.toJson()).toList(),
    };
  }

  Ficha copyWith({
    int? id,
    String? codigo,
    ProgramaFormacion? programa,
    DiasFormacion? diasFormacion,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int? cupo,
    Ambiente? ambiente,
    InstructorPrincipal? instructorPrincipal,
    List<InstructorAsignado>? instructoresApoyo,
  }) {
    return Ficha(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      programa: programa ?? this.programa,
      diasFormacion: diasFormacion ?? this.diasFormacion,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      cupo: cupo ?? this.cupo,
      ambiente: ambiente ?? this.ambiente,
      instructorPrincipal: instructorPrincipal ?? this.instructorPrincipal,
      instructoresApoyo: instructoresApoyo ?? this.instructoresApoyo,
    );
  }

  static List<InstructorAsignado> _parseInstructores(dynamic raw) {
    if (raw is Iterable) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(InstructorAsignado.fromJson)
          .toList();
    }
    return const <InstructorAsignado>[];
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
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
