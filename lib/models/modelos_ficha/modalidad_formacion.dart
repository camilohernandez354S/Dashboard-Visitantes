/// Modalidad en la que se imparte la formación.
enum ModalidadFormacion { presencial, virtual, mixta }

extension ModalidadFormacionUtils on ModalidadFormacion {
  static ModalidadFormacion fromJson(dynamic value) {
    if (value is ModalidadFormacion) return value;
    final normalized = value?.toString().toLowerCase().trim();
    return switch (normalized) {
      'presencial' || 'onsite' || 'en sitio' => ModalidadFormacion.presencial,
      'virtual' || 'online' => ModalidadFormacion.virtual,
      'mixta' ||
      'hibrida' ||
      'híbrida' ||
      'blended' => ModalidadFormacion.mixta,
      _ => ModalidadFormacion.presencial,
    };
  }

  String toJson() => name;

  String get label {
    return switch (this) {
      ModalidadFormacion.presencial => 'Presencial',
      ModalidadFormacion.virtual => 'Virtual',
      ModalidadFormacion.mixta => 'Mixta',
    };
  }
}
