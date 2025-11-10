import 'persona.dart';

/// Rol asignado a un instructor dentro de la ficha.
enum InstructorRol { principal, apoyo, invitado }

extension InstructorRolUtils on InstructorRol {
  static InstructorRol fromJson(dynamic value) {
    if (value is InstructorRol) return value;
    final normalized = value?.toString().toLowerCase().trim();
    return switch (normalized) {
      'principal' || 'lead' || 'lider' || 'líder' => InstructorRol.principal,
      'apoyo' || 'auxiliar' || 'apprentice' => InstructorRol.apoyo,
      'invitado' || 'guest' => InstructorRol.invitado,
      _ => InstructorRol.apoyo,
    };
  }

  String toJson() => name;
}

/// Información de un instructor asociado a la ficha.
class Instructor {
  const Instructor({
    required this.persona,
    required this.rol,
    this.especialidad,
    this.emailInstitucional,
    this.telefonoCorporativo,
  });

  final Persona persona;
  final InstructorRol rol;
  final String? especialidad;
  final String? emailInstitucional;
  final String? telefonoCorporativo;

  bool get esPrincipal => rol == InstructorRol.principal;

  Instructor copyWith({
    Persona? persona,
    InstructorRol? rol,
    String? especialidad,
    String? emailInstitucional,
    String? telefonoCorporativo,
  }) {
    return Instructor(
      persona: persona ?? this.persona,
      rol: rol ?? this.rol,
      especialidad: especialidad ?? this.especialidad,
      emailInstitucional: emailInstitucional ?? this.emailInstitucional,
      telefonoCorporativo: telefonoCorporativo ?? this.telefonoCorporativo,
    );
  }

  factory Instructor.fromJson(Map<String, dynamic> json) {
    return Instructor(
      persona:
          json['persona'] is Map<String, dynamic>
              ? Persona.fromJson(json['persona'] as Map<String, dynamic>)
              : Persona.fromJson(json),
      rol: InstructorRolUtils.fromJson(json['rol']),
      especialidad: _normalize(json['especialidad']),
      emailInstitucional: _normalize(
        json['emailInstitucional'] ?? json['correoInstitucional'],
      ),
      telefonoCorporativo: _normalize(json['telefonoCorporativo']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'persona': persona.toJson(),
      'rol': rol.toJson(),
      if (especialidad != null) 'especialidad': especialidad,
      if (emailInstitucional != null) 'emailInstitucional': emailInstitucional,
      if (telefonoCorporativo != null)
        'telefonoCorporativo': telefonoCorporativo,
    };
  }

  static String? _normalize(dynamic value) {
    if (value == null) return null;
    final result = value.toString().trim();
    return result.isEmpty ? null : result;
  }
}
