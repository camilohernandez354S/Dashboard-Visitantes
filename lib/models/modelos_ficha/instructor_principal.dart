import 'instructor.dart';
import 'persona.dart';

/// Especialización semántica para el instructor principal.
class InstructorPrincipal extends Instructor {
  const InstructorPrincipal({
    required super.persona,
    String? especialidad,
    String? emailInstitucional,
    String? telefonoCorporativo,
  }) : super(
         rol: InstructorRol.principal,
         especialidad: especialidad,
         emailInstitucional: emailInstitucional,
         telefonoCorporativo: telefonoCorporativo,
       );

  factory InstructorPrincipal.fromJson(Map<String, dynamic> json) {
    final base = Instructor.fromJson(json);
    return InstructorPrincipal(
      persona: base.persona,
      especialidad: base.especialidad,
      emailInstitucional: base.emailInstitucional,
      telefonoCorporativo: base.telefonoCorporativo,
    );
  }

  factory InstructorPrincipal.fromPersona(
    Persona persona, {
    String? especialidad,
    String? emailInstitucional,
    String? telefonoCorporativo,
  }) {
    return InstructorPrincipal(
      persona: persona,
      especialidad: especialidad,
      emailInstitucional: emailInstitucional,
      telefonoCorporativo: telefonoCorporativo,
    );
  }
}
