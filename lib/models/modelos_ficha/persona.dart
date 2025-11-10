/// Representa datos personales básicos utilizados en la ficha.
class Persona {
  const Persona({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.tipoDocumento,
    required this.numeroDocumento,
    this.email,
    this.telefono,
    this.celular,
  });

  final int id;
  final String nombres;
  final String apellidos;
  final String tipoDocumento;
  final String numeroDocumento;
  final String? email;
  final String? telefono;
  final String? celular;

  String get nombreCompleto =>
      '$nombres $apellidos'.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

  factory Persona.fromJson(Map<String, dynamic> json) {
    return Persona(
      id: _parseInt(json['id']),
      nombres: (json['nombres'] ?? json['nombre'] ?? '').toString(),
      apellidos: (json['apellidos'] ?? json['apellido'] ?? '').toString(),
      tipoDocumento:
          (json['tipoDocumento'] ?? json['tipo_documento'] ?? '').toString(),
      numeroDocumento:
          (json['numeroDocumento'] ?? json['documento'] ?? '').toString(),
      email: _parseNullableString(json['email'] ?? json['correo']),
      telefono: _parseNullableString(json['telefono']),
      celular: _parseNullableString(json['celular']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nombres': nombres,
      'apellidos': apellidos,
      'tipoDocumento': tipoDocumento,
      'numeroDocumento': numeroDocumento,
      if (email != null) 'email': email,
      if (telefono != null) 'telefono': telefono,
      if (celular != null) 'celular': celular,
    };
  }

  Persona copyWith({
    int? id,
    String? nombres,
    String? apellidos,
    String? tipoDocumento,
    String? numeroDocumento,
    String? email,
    String? telefono,
    String? celular,
  }) {
    return Persona(
      id: id ?? this.id,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      celular: celular ?? this.celular,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static String? _parseNullableString(dynamic value) {
    if (value == null) return null;
    final result = value.toString().trim();
    return result.isEmpty ? null : result;
  }
}
