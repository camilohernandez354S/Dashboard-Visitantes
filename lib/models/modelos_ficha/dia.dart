/// Representa los días de la semana válidos para una ficha de formación.
enum DiaSemana { lunes, martes, miercoles, jueves, viernes, sabado, domingo }

extension DiaSemanaUtils on DiaSemana {
  static DiaSemana fromJson(dynamic value) {
    if (value is DiaSemana) return value;
    final normalized = value?.toString().toLowerCase().trim();
    return switch (normalized) {
      'lunes' || 'mon' || 'monday' => DiaSemana.lunes,
      'martes' || 'mar' || 'tue' || 'tuesday' => DiaSemana.martes,
      'miercoles' ||
      'miércoles' ||
      'mie' ||
      'wed' ||
      'wednesday' => DiaSemana.miercoles,
      'jueves' || 'jue' || 'thu' || 'thursday' => DiaSemana.jueves,
      'viernes' || 'vie' || 'fri' || 'friday' => DiaSemana.viernes,
      'sabado' || 'sábado' || 'sab' || 'sat' || 'saturday' => DiaSemana.sabado,
      'domingo' || 'dom' || 'sun' || 'sunday' => DiaSemana.domingo,
      _ => throw ArgumentError('Valor de día no soportado: $value'),
    };
  }

  String get label {
    switch (this) {
      case DiaSemana.lunes:
        return 'Lunes';
      case DiaSemana.martes:
        return 'Martes';
      case DiaSemana.miercoles:
        return 'Miércoles';
      case DiaSemana.jueves:
        return 'Jueves';
      case DiaSemana.viernes:
        return 'Viernes';
      case DiaSemana.sabado:
        return 'Sábado';
      case DiaSemana.domingo:
        return 'Domingo';
    }
  }

  String get shortLabel {
    switch (this) {
      case DiaSemana.lunes:
        return 'Lun';
      case DiaSemana.martes:
        return 'Mar';
      case DiaSemana.miercoles:
        return 'Mié';
      case DiaSemana.jueves:
        return 'Jue';
      case DiaSemana.viernes:
        return 'Vie';
      case DiaSemana.sabado:
        return 'Sáb';
      case DiaSemana.domingo:
        return 'Dom';
    }
  }

  String toJson() => name;
}
