import 'dia.dart';

/// Agrupa los días en los que se imparte una ficha.
class DiasFormacion {
  const DiasFormacion._(this.dias);

  factory DiasFormacion(Set<DiaSemana> dias) {
    if (dias.isEmpty) {
      throw ArgumentError('Se requiere al menos un día de formación.');
    }
    return DiasFormacion._(Set.unmodifiable(dias));
  }

  factory DiasFormacion.fromJson(dynamic json) {
    if (json == null) {
      throw ArgumentError('No se puede crear DiasFormacion desde null');
    }
    if (json is DiasFormacion) return json;
    final Iterable<dynamic> source;
    if (json is String) {
      source = json.split(',').map((e) => e.trim());
    } else if (json is Iterable) {
      source = json;
    } else {
      throw ArgumentError('Formato no soportado para DiasFormacion: $json');
    }

    final parsed = <DiaSemana>{};
    for (final item in source) {
      parsed.add(DiaSemanaUtils.fromJson(item));
    }
    return DiasFormacion(parsed);
  }

  final Set<DiaSemana> dias;

  bool contiene(DiaSemana dia) => dias.contains(dia);

  List<String> toJson() => dias.map((d) => d.toJson()).toList();

  DiasFormacion copyWith({Set<DiaSemana>? diasActualizados}) {
    return DiasFormacion(diasActualizados ?? dias);
  }
}
