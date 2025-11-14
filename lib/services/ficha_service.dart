import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/modelos_ficha/ambiente.dart';
import '../models/modelos_ficha/dia.dart';
import '../models/modelos_ficha/dias_formacion.dart';
import '../models/modelos_ficha/ficha.dart';
import '../models/modelos_ficha/instructor_asignado.dart';
import '../models/modelos_ficha/instructor_principal.dart';
import '../models/modelos_ficha/modalidad_formacion.dart';
import '../models/modelos_ficha/persona.dart';
import '../models/modelos_ficha/programa_formacion.dart';
import '../models/modelos_ficha/sede.dart';
import '../models/modelos_ficha/jornada_formacion.dart';
import 'api_service.dart' show apiBase;

/// Servicio encargado de obtener información de fichas de formación.
class FichaService {
  const FichaService();

  Uri? get _baseUri =>
      apiBase.isEmpty ? null : Uri.parse(apiBase).resolve('fichas/');

  /// Obtiene todas las fichas del backend o datos mock si no hay API.
  Future<List<Ficha>> fetchFichas() async {
    if (_baseUri == null) {
      await Future.delayed(const Duration(milliseconds: 250));
      return _mockFichas();
    }

    final uri = _baseUri!;

    final response = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 6));

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(Ficha.fromJson)
            .toList();
      } else if (decoded is Map<String, dynamic> && decoded['data'] is List) {
        return (decoded['data'] as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(Ficha.fromJson)
            .toList();
      }
      throw const FormatException(
        'Formato de respuesta no soportado. Se esperaba una lista.',
      );
    }

    throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
  }

  /// Obtiene el detalle de una ficha específica.
  Future<Ficha> fetchFichaDetalle(int fichaId) async {
    final base = _baseUri;
    if (base == null) {
      return _mockFichas().firstWhere(
        (ficha) => ficha.id == fichaId,
        orElse: () => _mockFichas().first,
      );
    }

    final uri = base.resolve('$fichaId');

    final response = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 6));

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return Ficha.fromJson(decoded);
      }
      throw const FormatException(
        'Formato de ficha no soportado. Se esperaba un objeto JSON.',
      );
    }

    throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
  }

  List<Ficha> _mockFichas() {
    return [
      Ficha(
        id: 1,
        codigo: '2569789',
        programa: ProgramaFormacion(
          id: 21,
          codigo: 'ADSI-2025',
          nombre: 'Análisis y Desarrollo de Software',
          version: 3,
          modalidad: ModalidadFormacion.mixta,
          jornada: JornadaFormacion(
            nombre: 'Diurna',
            horaInicio: const TimeOfDay(hour: 7, minute: 0),
            horaFin: const TimeOfDay(hour: 13, minute: 0),
          ),
        ),
        diasFormacion: DiasFormacion({
          DiaSemana.lunes,
          DiaSemana.martes,
          DiaSemana.miercoles,
          DiaSemana.jueves,
        }),
        fechaInicio: DateTime.now().subtract(const Duration(days: 30)),
        fechaFin: DateTime.now().add(const Duration(days: 240)),
        cupo: 30,
        instructorPrincipal: InstructorPrincipal(
          persona: Persona(
            id: 501,
            nombres: 'Laura',
            apellidos: 'Jiménez',
            tipoDocumento: 'CC',
            numeroDocumento: '1024567890',
            email: 'laura.jimenez@sena.edu.co',
          ),
          especialidad: 'Desarrollo de software',
        ),
        instructoresApoyo: [
          InstructorAsignado(
            persona: Persona(
              id: 502,
              nombres: 'Carlos',
              apellidos: 'Mejía',
              tipoDocumento: 'CC',
              numeroDocumento: '1011234567',
            ),
          ),
        ],
        ambiente: Ambiente(
          id: 10,
          codigo: 'LAB-304',
          nombre: 'Laboratorio de Desarrollo',
          capacidad: 35,
          tipo: 'Laboratorio',
          sede: Sede(
            id: 1,
            nombre: 'Centro de Innovación',
            ciudad: 'San José del Guaviare',
            departamento: 'Guaviare',
            direccion: 'Calle 12 #45-67',
          ),
        ),
      ),
      Ficha(
        id: 2,
        codigo: '2698745',
        programa: ProgramaFormacion(
          id: 32,
          codigo: 'Cocina-2024',
          nombre: 'Cocina Internacional',
          version: 1,
          modalidad: ModalidadFormacion.presencial,
        ),
        diasFormacion: DiasFormacion({DiaSemana.viernes, DiaSemana.sabado}),
        fechaInicio: DateTime.now().subtract(const Duration(days: 15)),
        fechaFin: DateTime.now().add(const Duration(days: 120)),
        cupo: 20,
      ),
    ];
  }
}
