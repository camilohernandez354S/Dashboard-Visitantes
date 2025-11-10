import 'package:flutter/material.dart';

/// Representa una jornada (franja horaria) en la que se dicta la formación.
@immutable
class JornadaFormacion {
  const JornadaFormacion._({
    required this.nombre,
    required this.horaInicio,
    required this.horaFin,
  });

  factory JornadaFormacion({
    required String nombre,
    required TimeOfDay horaInicio,
    required TimeOfDay horaFin,
  }) {
    if (_toMinutes(horaFin) <= _toMinutes(horaInicio)) {
      throw ArgumentError('La hora fin debe ser posterior a la inicial');
    }
    return JornadaFormacion._(
      nombre: nombre,
      horaInicio: horaInicio,
      horaFin: horaFin,
    );
  }

  final String nombre;
  final TimeOfDay horaInicio;
  final TimeOfDay horaFin;

  Duration get duracion {
    final inicio = Duration(hours: horaInicio.hour, minutes: horaInicio.minute);
    final fin = Duration(hours: horaFin.hour, minutes: horaFin.minute);
    return fin - inicio;
  }

  factory JornadaFormacion.fromJson(Map<String, dynamic> json) {
    TimeOfDay parseHora(dynamic value) {
      if (value is TimeOfDay) return value;
      final texto = value?.toString() ?? '00:00';
      final partes = texto.split(':');
      final horas = int.parse(partes[0]);
      final minutos = partes.length > 1 ? int.parse(partes[1]) : 0;
      return TimeOfDay(hour: horas, minute: minutos);
    }

    return JornadaFormacion(
      nombre: (json['nombre'] ?? json['descripcion'] ?? '').toString(),
      horaInicio: parseHora(json['horaInicio'] ?? json['inicio']),
      horaFin: parseHora(json['horaFin'] ?? json['fin']),
    );
  }

  Map<String, dynamic> toJson() {
    String format(TimeOfDay time) =>
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return <String, dynamic>{
      'nombre': nombre,
      'horaInicio': format(horaInicio),
      'horaFin': format(horaFin),
    };
  }

  JornadaFormacion copyWith({
    String? nombre,
    TimeOfDay? horaInicio,
    TimeOfDay? horaFin,
  }) {
    return JornadaFormacion(
      nombre: nombre ?? this.nombre,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
    );
  }

  static int _toMinutes(TimeOfDay time) => time.hour * 60 + time.minute;
}
