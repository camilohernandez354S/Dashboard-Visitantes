import 'instructor.dart';
import 'persona.dart';

/// Instructor de apoyo o adicional asociado a la ficha.
class InstructorAsignado extends Instructor {
  const InstructorAsignado({
    required super.persona,
    InstructorRol rol = InstructorRol.apoyo,
    String? especialidad,
    String? emailInstitucional,
    String? telefonoCorporativo,
  }) : super(
         rol: rol,
         especialidad: especialidad,
         emailInstitucional: emailInstitucional,
         telefonoCorporativo: telefonoCorporativo,
       );

  factory InstructorAsignado.fromJson(Map<String, dynamic> json) {
    final base = Instructor.fromJson(json);
    return InstructorAsignado(
      persona: base.persona,
      rol: base.rol == InstructorRol.principal ? InstructorRol.apoyo : base.rol,
      especialidad: base.especialidad,
      emailInstitucional: base.emailInstitucional,
      telefonoCorporativo: base.telefonoCorporativo,
    );
  }

  factory InstructorAsignado.fromPersona(
    Persona persona, {
    InstructorRol rol = InstructorRol.apoyo,
    String? especialidad,
    String? emailInstitucional,
    String? telefonoCorporativo,
  }) {
    return InstructorAsignado(
      persona: persona,
      rol: rol,
      especialidad: especialidad,
      emailInstitucional: emailInstitucional,
      telefonoCorporativo: telefonoCorporativo,
    );
  }
}
