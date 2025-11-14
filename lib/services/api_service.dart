import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// URL base de la API configurada via --dart-define
const String apiBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.139.237.174:8000',
);

class ApiService {
  /// Convierte un valor dinámico a int de forma segura.
  static int? _asIntHelper(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  /// Obtiene las estadísticas del dashboard desde la API.
  /// Consulta el endpoint /api/websocket/estadisticas.
  /// Parsea la nueva estructura de respuesta con roles, asistencias_hoy y personas_dentro.
  static Future<DashboardData> fetchDashboardData() async {
    try {
      final uri = Uri.parse('$apiBase/api/websocket/estadisticas');

      final resp = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 6));

      if (resp.statusCode == 200) {
        final dynamic decoded = jsonDecode(resp.body);

        // Manejar formato de respuesta Laravel: {success: true, data: {...}}
        dynamic responseData = decoded;
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('success') && decoded.containsKey('data')) {
            responseData = decoded['data'];
          } else if (decoded.containsKey('data')) {
            responseData = decoded['data'];
          }
        }

        // Parsear la nueva estructura de estadísticas
        if (responseData is Map<String, dynamic>) {
          // Extraer datos de personas_dentro (conteos actuales) - ESTA ES LA FUENTE DE VERDAD
          final personasDentro =
              responseData['personas_dentro'] as Map<String, dynamic>?;

          // Extraer datos de roles (totales, activos, inactivos) - SOLO PARA MOSTRAR EN EL PANEL
          final roles = responseData['roles'] as Map<String, dynamic>?;

          // Extraer asistencias_hoy
          final asistenciasHoy = responseData['asistencias_hoy'] as int? ?? 0;

          // Mapear personas_dentro a los campos del modelo (ESTA ES LA FUENTE PRINCIPAL)
          int instructores = 0;
          int aprendices = 0;
          int funcionarios = 0;
          int visitantes = 0;

          if (personasDentro != null) {
            // Usar SOLO personas_dentro para los conteos actuales
            instructores = _asIntHelper(personasDentro['instructores']) ?? 0;
            aprendices = _asIntHelper(personasDentro['aprendices']) ?? 0;
            // Mapear administrativos a funcionarios
            funcionarios = _asIntHelper(personasDentro['administrativos']) ?? 0;
            visitantes = _asIntHelper(personasDentro['visitantes']) ?? 0;
          }

          // Crear DashboardData con los datos extraídos del endpoint
          // NO calcular desde registros, usar SOLO los datos del endpoint
          final data = DashboardData(
            instructores: instructores,
            aprendices: aprendices,
            funcionarios: funcionarios,
            visitantes: visitantes,
            variations: const {},
            weekly: const [],
            hourly: const [],
            records:
                const [], // NO usar registros, solo estadísticas del endpoint
            asistenciasHoy: asistenciasHoy,
            rolesData: roles,
            personasDentroData: personasDentro,
          );

          return data;
        }

        // Si no hay nada, retornar datos vacíos
        return DashboardData.fromRecords([]);
      } else if (resp.statusCode == 500) {
        final dynamic decoded = jsonDecode(resp.body);
        final message =
            decoded is Map<String, dynamic>
                ? (decoded['message'] ?? 'Error al obtener estadísticas')
                : 'Error al obtener estadísticas';
        throw Exception('Error HTTP ${resp.statusCode}: $message');
      } else {
        final dynamic decoded = jsonDecode(resp.body);
        final message =
            decoded is Map<String, dynamic>
                ? (decoded['message'] ?? decoded.toString())
                : decoded.toString();
        throw Exception('Error HTTP ${resp.statusCode}: $message');
      }
    } on TimeoutException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene la lista de visitantes actualmente dentro del centro.
  /// Endpoint: GET /api/websocket/visitantes-actuales
  static Future<List<Map<String, dynamic>>> fetchVisitantesActuales() async {
    try {
      final uri = Uri.parse('$apiBase/api/websocket/visitantes-actuales');

      final resp = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 6));

      if (resp.statusCode == 200) {
        final dynamic decoded = jsonDecode(resp.body);

        // Manejar formato Laravel: {success: true, data: [...]}
        if (decoded is List) {
          return decoded.whereType<Map<String, dynamic>>().toList();
        } else if (decoded is Map<String, dynamic>) {
          // Verificar formato Laravel
          if (decoded.containsKey('success') && decoded.containsKey('data')) {
            final data = decoded['data'];
            if (data is List) {
              return data.whereType<Map<String, dynamic>>().toList();
            } else if (data is Map) {
              // Error: el endpoint está retornando estadísticas en lugar de visitantes
              return [];
            }
          } else if (decoded.containsKey('data')) {
            final data = decoded['data'];
            if (data is List) {
              return data.whereType<Map<String, dynamic>>().toList();
            } else if (data is Map) {
              return [];
            }
          }
        }
        return [];
      } else if (resp.statusCode == 500) {
        final dynamic decoded = jsonDecode(resp.body);
        final message =
            decoded is Map<String, dynamic>
                ? (decoded['message'] ?? 'Error al obtener visitantes actuales')
                : 'Error al obtener visitantes actuales';
        throw Exception('Error HTTP ${resp.statusCode}: $message');
      } else {
        final dynamic decoded = jsonDecode(resp.body);
        final message =
            decoded is Map<String, dynamic>
                ? (decoded['message'] ?? decoded.toString())
                : decoded.toString();
        throw Exception('Error HTTP ${resp.statusCode}: $message');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Registra una entrada de visitante.
  /// Endpoint: POST /api/websocket/entrada
  static Future<Map<String, dynamic>> registrarEntrada({
    required int personaId,
    required String nombre,
    required String documento,
    required String rol,
    String? ficha,
    String? ambiente,
  }) async {
    try {
      final uri = Uri.parse('$apiBase/api/websocket/entrada');
      final body = {
        'persona_id': personaId,
        'nombre': nombre,
        'documento': documento,
        'rol': rol,
        if (ficha != null) 'ficha': ficha,
        if (ambiente != null) 'ambiente': ambiente,
      };

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        // Si viene con formato Laravel {success: true, ...}, retornar todo el objeto
        return decoded;
      } else if (response.statusCode == 422) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final errors =
            decoded['errors'] ?? decoded['message'] ?? 'Error de validación';
        throw Exception('Error de validación (HTTP 422): $errors');
      } else if (response.statusCode == 500) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final message = decoded['message'] ?? 'Error al registrar entrada';
        throw Exception('Error HTTP ${response.statusCode}: $message');
      } else {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
        final message = decoded?['message'] ?? response.body;
        throw Exception('Error HTTP ${response.statusCode}: $message');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Registra una salida de visitante.
  /// Endpoint: POST /api/websocket/salida
  static Future<Map<String, dynamic>> registrarSalida({
    required int personaId,
    required String nombre,
    required String documento,
    required String rol,
  }) async {
    try {
      final uri = Uri.parse('$apiBase/api/websocket/salida');
      final body = {
        'persona_id': personaId,
        'nombre': nombre,
        'documento': documento,
        'rol': rol,
      };

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        // Si viene con formato Laravel {success: true, ...}, retornar todo el objeto
        return decoded;
      } else if (response.statusCode == 422) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final errors =
            decoded['errors'] ?? decoded['message'] ?? 'Error de validación';
        throw Exception('Error de validación (HTTP 422): $errors');
      } else if (response.statusCode == 500) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final message = decoded['message'] ?? 'Error al registrar salida';
        throw Exception('Error HTTP ${response.statusCode}: $message');
      } else {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
        final message = decoded?['message'] ?? response.body;
        throw Exception('Error HTTP ${response.statusCode}: $message');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene los registros diarios desde el endpoint.
  /// Endpoint: GET /api/presencia/registros-diarios
  static Future<List<DailyRecord>> fetchRegistrosDiarios() async {
    try {
      final uri = Uri.parse('$apiBase/api/presencia/registros-diarios');

      final resp = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final dynamic decoded = jsonDecode(resp.body);

        // Manejar formato de respuesta Laravel: {success: true, data: {registros: [...]}}
        dynamic responseData = decoded;
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('success') && decoded.containsKey('data')) {
            responseData = decoded['data'];
          } else if (decoded.containsKey('data')) {
            responseData = decoded['data'];
          }
        }

        // Extraer el array de registros desde data.registros
        List<dynamic> registrosList = [];
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('registros') &&
              responseData['registros'] is List) {
            registrosList = responseData['registros'] as List;
          }
        } else if (responseData is List) {
          // Si data es directamente un array (formato alternativo)
          registrosList = responseData;
        }

        if (registrosList.isNotEmpty) {
          return registrosList
              .whereType<Map<String, dynamic>>()
              .map((json) {
                try {
                  // Agregar la fecha y sede_id al json para que DailyRecord pueda usarlos
                  if (responseData is Map<String, dynamic>) {
                    final fecha = responseData['fecha']?.toString();
                    if (fecha != null && !json.containsKey('fecha')) {
                      json['fecha'] = fecha;
                    }
                  }
                  return DailyRecord.fromJson(json);
                } catch (e) {
                  return null;
                }
              })
              .whereType<DailyRecord>()
              .toList();
        }

        return [];
      } else if (resp.statusCode == 404) {
        // Endpoint no encontrado, retornar lista vacía sin error
        return [];
      } else {
        final dynamic decoded = jsonDecode(resp.body);
        final message =
            decoded is Map<String, dynamic>
                ? (decoded['message'] ?? 'Error al obtener registros diarios')
                : 'Error al obtener registros diarios';
        throw Exception('Error HTTP ${resp.statusCode}: $message');
      }
    } on TimeoutException {
      // Timeout: retornar lista vacía sin lanzar error
      return [];
    } catch (e) {
      // Para errores de conexión, retornar lista vacía en lugar de lanzar excepción
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('timeout') ||
          errorStr.contains('connection') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('network') ||
          errorStr.contains('socket')) {
        return [];
      }
      // Para otros errores, lanzar excepción
      rethrow;
    }
  }

  /// Obtiene las entradas por hora desde el endpoint.
  /// Endpoint: GET /api/websocket/entradas-por-hora
  static Future<EntradasPorHoraData> fetchEntradasPorHora() async {
    try {
      final uri = Uri.parse('$apiBase/api/websocket/entradas-por-hora');

      final resp = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 6));

      if (resp.statusCode == 200) {
        final dynamic decoded = jsonDecode(resp.body);

        // Manejar formato de respuesta Laravel: {success: true, data: {...}}
        dynamic responseData = decoded;
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('success') && decoded.containsKey('data')) {
            responseData = decoded['data'];
          } else if (decoded.containsKey('data')) {
            responseData = decoded['data'];
          }
        }

        if (responseData is Map<String, dynamic>) {
          final fecha = responseData['fecha'] as String? ?? '';
          final sedeId = _asIntHelper(responseData['sede_id']) ?? 0;
          final series = responseData['series'] as List<dynamic>? ?? [];

          final entradas =
              series
                  .map((item) {
                    if (item is Map<String, dynamic>) {
                      final hora = item['hora'] as String? ?? '';
                      final total = _asIntHelper(item['total']) ?? 0;
                      return EntradaPorHora(hora: hora, total: total);
                    }
                    return null;
                  })
                  .whereType<EntradaPorHora>()
                  .toList();

          return EntradasPorHoraData(
            fecha: fecha,
            sedeId: sedeId,
            entradas: entradas,
          );
        }

        throw Exception('Formato de respuesta inválido');
      } else {
        throw Exception('Error HTTP ${resp.statusCode}: ${resp.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
}

/// Modelo para un registro diario de asistencia.
class DailyRecord {
  final String nombre;
  final String apellido;
  final String cargo;
  final String tipo; // 'entrada' o 'salida'
  final DateTime timestamp;

  const DailyRecord({
    required this.nombre,
    required this.apellido,
    required this.cargo,
    required this.tipo,
    required this.timestamp,
  });

  String get nombreCompleto => '$nombre $apellido'.trim();

  bool get esEntrada => tipo.toLowerCase() == 'entrada';
  bool get esSalida => tipo.toLowerCase() == 'salida';

  factory DailyRecord.fromJson(Map<String, dynamic> json) {
    final nombre = (json['nombre'] ?? json['nombres'] ?? '').toString().trim();
    final apellido =
        (json['apellido'] ?? json['apellidos'] ?? '').toString().trim();

    // El cargo puede venir de 'sede' o de otros campos
    final cargo =
        (json['cargo'] ??
                json['sede'] ??
                json['rol'] ??
                json['tipo_persona'] ??
                json['role'] ??
                '')
            .toString()
            .trim();

    // Determinar tipo desde hora_entrada y hora_salida
    // Si hora_salida tiene valor, el último evento fue una salida
    // Si solo hay hora_entrada, el último evento fue una entrada
    String tipo = 'entrada';
    final horaSalida = json['hora_salida'];
    final horaEntrada = json['hora_entrada'];

    if (horaSalida != null && horaSalida.toString().trim().isNotEmpty) {
      // Si hay hora_salida, el último evento fue una salida
      tipo = 'salida';
    } else if (horaEntrada != null &&
        horaEntrada.toString().trim().isNotEmpty) {
      // Si solo hay hora_entrada, el último evento fue una entrada
      tipo = 'entrada';
    } else if (json.containsKey('tipo')) {
      tipo =
          (json['tipo'] ?? json['tipo_registro'] ?? 'entrada')
              .toString()
              .toLowerCase();
    }

    // Construir timestamp desde fecha + hora_entrada o hora_salida
    DateTime timestamp = DateTime.now();
    final fecha = json['fecha']?.toString();

    if (fecha != null) {
      // Intentar construir desde fecha + hora
      String horaStr = '';
      if (tipo == 'salida' && horaSalida != null) {
        horaStr = horaSalida.toString().trim();
      } else if (horaEntrada != null) {
        horaStr = horaEntrada.toString().trim();
      }

      if (horaStr.isNotEmpty) {
        // Formato esperado: "2025-11-14" + "04:51:38" = "2025-11-14 04:51:38"
        final fechaHoraStr = '$fecha $horaStr';
        final parsed = DateTime.tryParse(fechaHoraStr);
        if (parsed != null) {
          timestamp = parsed;
        }
      } else {
        // Solo fecha sin hora
        final parsed = DateTime.tryParse(fecha);
        if (parsed != null) {
          timestamp = parsed;
        }
      }
    } else {
      // Fallback a otros campos de timestamp
      if (json.containsKey('timestamp')) {
        final ts = json['timestamp'];
        if (ts is String) {
          timestamp = DateTime.tryParse(ts) ?? DateTime.now();
        } else if (ts is int) {
          timestamp = DateTime.fromMillisecondsSinceEpoch(ts);
        }
      } else if (json.containsKey('created_at')) {
        final ts = json['created_at'];
        if (ts is String) {
          timestamp = DateTime.tryParse(ts) ?? DateTime.now();
        }
      } else if (json.containsKey('fecha_hora')) {
        final ts = json['fecha_hora'];
        if (ts is String) {
          timestamp = DateTime.tryParse(ts) ?? DateTime.now();
        }
      }
    }

    return DailyRecord(
      nombre: nombre,
      apellido: apellido,
      cargo: cargo,
      tipo: tipo,
      timestamp: timestamp,
    );
  }
}

/// Modelo para datos de entradas por hora.
class EntradaPorHora {
  final String hora;
  final int total;

  const EntradaPorHora({required this.hora, required this.total});
}

/// Modelo para la respuesta completa de entradas por hora.
class EntradasPorHoraData {
  final String fecha;
  final int sedeId;
  final List<EntradaPorHora> entradas;

  const EntradasPorHoraData({
    required this.fecha,
    required this.sedeId,
    required this.entradas,
  });
}

/// Entidad principal con los datos del dashboard.
class DashboardData {
  final int instructores;
  final int aprendices;
  final int funcionarios;
  final int visitantes;
  final Map<String, double> variations;
  final List<WeeklyAttendance> weekly;
  final List<HourlyAttendance> hourly;
  final List<AttendanceRecord> records;
  final int asistenciasHoy;
  final Map<String, dynamic>? rolesData;
  final Map<String, dynamic>? personasDentroData;

  const DashboardData({
    required this.instructores,
    required this.aprendices,
    required this.funcionarios,
    required this.visitantes,
    required this.variations,
    required this.weekly,
    required this.hourly,
    required this.records,
    this.asistenciasHoy = 0,
    this.rolesData,
    this.personasDentroData,
  });

  DashboardData copyWith({
    int? instructores,
    int? aprendices,
    int? funcionarios,
    int? visitantes,
    Map<String, double>? variations,
    List<WeeklyAttendance>? weekly,
    List<HourlyAttendance>? hourly,
    List<AttendanceRecord>? records,
    int? asistenciasHoy,
    Map<String, dynamic>? rolesData,
    Map<String, dynamic>? personasDentroData,
  }) {
    return DashboardData(
      instructores: instructores ?? this.instructores,
      aprendices: aprendices ?? this.aprendices,
      funcionarios: funcionarios ?? this.funcionarios,
      visitantes: visitantes ?? this.visitantes,
      variations: Map.unmodifiable(variations ?? this.variations),
      weekly: List.unmodifiable(weekly ?? this.weekly),
      hourly: List.unmodifiable(hourly ?? this.hourly),
      records: List.unmodifiable(records ?? this.records),
      asistenciasHoy: asistenciasHoy ?? this.asistenciasHoy,
      rolesData: rolesData ?? this.rolesData,
      personasDentroData: personasDentroData ?? this.personasDentroData,
    );
  }

  DashboardData mergeFromSocket(Map<String, dynamic> payload) {
    if (payload['record'] is Map<String, dynamic>) {
      final recordJson = payload['record'] as Map<String, dynamic>;
      // Intentar usar fromServerJson primero (formato del servidor Node.js)
      // Si no funciona, usar fromJson (formato genérico)
      AttendanceRecord record;
      try {
        if (recordJson.containsKey('hora') && recordJson.containsKey('rol')) {
          record = AttendanceRecord.fromServerJson(recordJson);
        } else {
          record = AttendanceRecord.fromJson(recordJson);
        }
      } catch (e) {
        record = AttendanceRecord.fromJson(recordJson);
      }
      return applyRecord(record);
    }

    final parsedRecords = _parseRecordsList(payload['records']);
    if (parsedRecords != null) {
      return DashboardData.fromRecords(parsedRecords, previousRecords: records);
    }

    Map<String, double>? updatedVariations;
    if (payload['variations'] is Map) {
      final parsed = <String, double>{};
      (payload['variations'] as Map).forEach((key, value) {
        if (value is num) {
          parsed[key.toString()] = value.toDouble();
        }
      });
      if (parsed.isNotEmpty) {
        updatedVariations = Map.unmodifiable(parsed);
      }
    }

    List<WeeklyAttendance>? updatedWeekly;
    if (payload['weekly'] is List) {
      final parsedList =
          (payload['weekly'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map(WeeklyAttendance.fromJson)
              .toList();
      if (parsedList.isNotEmpty) {
        updatedWeekly = List.unmodifiable(parsedList);
      }
    }

    List<HourlyAttendance>? updatedHourly;
    if (payload['hourly'] is List) {
      final parsedList = HourlyAttendance.fromJsonList(payload['hourly']);
      if (parsedList.isNotEmpty) {
        updatedHourly = List.unmodifiable(parsedList);
      }
    }

    return copyWith(
      instructores: _asInt(payload['instructores']) ?? instructores,
      aprendices: _asInt(payload['aprendices']) ?? aprendices,
      funcionarios: _asInt(payload['funcionarios']) ?? funcionarios,
      visitantes: _asInt(payload['visitantes']) ?? visitantes,
      variations: updatedVariations ?? variations,
      weekly: updatedWeekly ?? weekly,
      hourly: updatedHourly ?? hourly,
    );
  }

  DashboardData applyRecord(AttendanceRecord record) {
    if (!record.role.isTracked) return this;
    final updatedRecords = List<AttendanceRecord>.from(records)..add(record);
    return DashboardData.fromRecords(updatedRecords, previousRecords: records);
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  static List<AttendanceRecord>? _parseRecordsList(dynamic raw) {
    if (raw is! List) return null;
    final parsed =
        raw
            .whereType<Map<String, dynamic>>()
            .map(AttendanceRecord.fromJson)
            .where((record) => record.role.isTracked)
            .toList();
    if (parsed.isEmpty) return null;
    return parsed;
  }

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final parsedRecords = _parseRecordsList(json['records']);
    if (parsedRecords != null) {
      final previousRecords =
          _parseRecordsList(json['previous_records']) ??
          const <AttendanceRecord>[];
      return DashboardData.fromRecords(
        parsedRecords,
        previousRecords: previousRecords,
      );
    }

    final weeklyList =
        (json['weekly'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(WeeklyAttendance.fromJson)
            .toList();

    final hourlyList = HourlyAttendance.fromJsonList(json['hourly']);

    final variationsMap = <String, double>{};
    if (json['variations'] is Map) {
      (json['variations'] as Map).forEach((key, value) {
        final doubleVal = value is num ? value.toDouble() : 0.0;
        variationsMap[key.toString()] = doubleVal;
      });
    }

    return DashboardData(
      instructores:
          json['instructores'] is int
              ? json['instructores'] as int
              : (json['instructores'] as num?)?.toInt() ?? 0,
      aprendices:
          json['aprendices'] is int
              ? json['aprendices'] as int
              : (json['aprendices'] as num?)?.toInt() ?? 0,
      funcionarios:
          json['funcionarios'] is int
              ? json['funcionarios'] as int
              : (json['funcionarios'] as num?)?.toInt() ?? 0,
      visitantes:
          json['visitantes'] is int
              ? json['visitantes'] as int
              : (json['visitantes'] as num?)?.toInt() ?? 0,
      variations: variationsMap,
      weekly:
          weeklyList.isNotEmpty ? weeklyList : WeeklyAttendance.fromRecords([]),
      hourly:
          hourlyList.isNotEmpty ? hourlyList : HourlyAttendance.fromRecords([]),
      records: const [],
      asistenciasHoy:
          json['asistencias_hoy'] is int
              ? json['asistencias_hoy'] as int
              : (json['asistencias_hoy'] as num?)?.toInt() ?? 0,
      rolesData: json['roles'] as Map<String, dynamic>?,
      personasDentroData: json['personas_dentro'] as Map<String, dynamic>?,
    );
  }

  factory DashboardData.fromRecords(
    List<AttendanceRecord> currentRecords, {
    List<AttendanceRecord>? previousRecords,
  }) {
    final current = _sortedTracked(currentRecords);
    final previous = _sortedTracked(
      previousRecords ?? const <AttendanceRecord>[],
    );

    final currentCounts = _emptyRoleCounts();
    for (final record in current) {
      currentCounts[record.role] = currentCounts[record.role]! + 1;
    }

    final previousCounts = _emptyRoleCounts();
    for (final record in previous) {
      previousCounts[record.role] = previousCounts[record.role]! + 1;
    }

    double variationForRole(AttendanceRole role) {
      final actual = currentCounts[role]!.toDouble();
      final previousTotal = previousCounts[role]!.toDouble();
      // Si no hay datos previos, la variación es 0 (no hay comparación)
      if (previousTotal <= 0) {
        return 0.0;
      }
      final delta = ((actual - previousTotal) / previousTotal) * 100;
      return (delta * 10).roundToDouble() / 10;
    }

    final variations = <String, double>{
      AttendanceRole.instructor.analyticsKey: variationForRole(
        AttendanceRole.instructor,
      ),
      AttendanceRole.aprendiz.analyticsKey: variationForRole(
        AttendanceRole.aprendiz,
      ),
      AttendanceRole.funcionario.analyticsKey: variationForRole(
        AttendanceRole.funcionario,
      ),
      AttendanceRole.visitante.analyticsKey: variationForRole(
        AttendanceRole.visitante,
      ),
    };

    return DashboardData(
      instructores: currentCounts[AttendanceRole.instructor]!,
      aprendices: currentCounts[AttendanceRole.aprendiz]!,
      funcionarios: currentCounts[AttendanceRole.funcionario]!,
      visitantes: currentCounts[AttendanceRole.visitante]!,
      variations: Map.unmodifiable(variations),
      weekly: WeeklyAttendance.fromRecords(current),
      hourly: HourlyAttendance.fromRecords(current),
      records: List.unmodifiable(current),
      asistenciasHoy: 0,
      rolesData: null,
      personasDentroData: null,
    );
  }

  static Map<AttendanceRole, int> _emptyRoleCounts() {
    return {
      AttendanceRole.instructor: 0,
      AttendanceRole.aprendiz: 0,
      AttendanceRole.funcionario: 0,
      AttendanceRole.visitante: 0,
    };
  }

  static List<AttendanceRecord> _sortedTracked(List<AttendanceRecord> source) {
    final filtered = source
        .where((record) => record.role.isTracked)
        .toList(growable: false);
    filtered.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return filtered;
  }

  factory DashboardData.mock() {
    final now = DateTime.now();
    final currentRecords = AttendanceRecord.mockWeek(
      reference: now,
      multiplier: 1.0,
    );
    final previousRecords = AttendanceRecord.mockWeek(
      reference: now.subtract(const Duration(days: 7)),
      multiplier: 0.85,
    );
    return DashboardData.fromRecords(
      currentRecords,
      previousRecords: previousRecords,
    );
  }

  int get weeklyTotal => weekly.fold<int>(
    0,
    (previousValue, element) => previousValue + element.value,
  );

  double variationFor(String key) => variations[key] ?? 0.0;

  DateTime? get latestRecordAt =>
      records.isNotEmpty ? records.last.recordedAt : null;

  String? get resumeToken => latestRecordAt?.toUtc().toIso8601String();

  /// Calcula el breakdown por sede para un rol específico.
  /// Retorna un mapa con el nombre de la sede y el conteo.
  Map<String, int> getBreakdownBySede(AttendanceRole role) {
    final sedeCounts = <String, int>{};

    for (final record in records) {
      if (record.role == role) {
        final sede = record.sede ?? 'Sin sede';
        sedeCounts[sede] = (sedeCounts[sede] ?? 0) + 1;
      }
    }

    // Si no hay registros, retornar mapa vacío
    if (sedeCounts.isEmpty) {
      return {};
    }

    return sedeCounts;
  }

  /// Calcula el trend semanal (últimos 7 días) para un rol específico.
  /// Retorna una lista de 7 valores, uno por cada día de la semana.
  List<int> getWeeklyTrend(AttendanceRole role) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calcular el inicio de la semana (lunes)
    final daysFromMonday = now.weekday - DateTime.monday;
    final weekStart = today.subtract(Duration(days: daysFromMonday));

    // Crear contadores para cada día de la semana
    final dayCounts = <int, int>{for (int i = 0; i < 7; i++) i: 0};

    // Contar registros por día de la semana actual
    for (final record in records) {
      if (record.role != role) continue;

      final recordDate = DateTime(
        record.recordedAt.year,
        record.recordedAt.month,
        record.recordedAt.day,
      );

      // Verificar si el registro está en la semana actual
      final daysDiff = recordDate.difference(weekStart).inDays;
      if (daysDiff >= 0 && daysDiff < 7) {
        dayCounts[daysDiff] = (dayCounts[daysDiff] ?? 0) + 1;
      }
    }

    // Retornar lista ordenada (lunes a domingo)
    return [
      dayCounts[0] ?? 0,
      dayCounts[1] ?? 0,
      dayCounts[2] ?? 0,
      dayCounts[3] ?? 0,
      dayCounts[4] ?? 0,
      dayCounts[5] ?? 0,
      dayCounts[6] ?? 0,
    ];
  }

  /// Calcula la distribución por sede de todos los registros.
  /// Retorna un mapa con el nombre de la sede y el porcentaje (0.0 a 1.0).
  Map<String, double> getSedeDistribution() {
    if (records.isEmpty) {
      return {};
    }

    final sedeCounts = <String, int>{};
    int total = 0;

    for (final record in records) {
      final sede = record.sede ?? 'Sin sede';
      sedeCounts[sede] = (sedeCounts[sede] ?? 0) + 1;
      total++;
    }

    if (total == 0) {
      return {};
    }

    return sedeCounts.map((key, value) => MapEntry(key, value / total));
  }
}

/// Modelo de asistencias diarias para la gráfica combinada.
class WeeklyAttendance {
  final String label;
  final int value;

  const WeeklyAttendance({required this.label, required this.value});

  factory WeeklyAttendance.fromJson(Map<String, dynamic> json) {
    return WeeklyAttendance(
      label: json['label']?.toString() ?? '',
      value:
          json['value'] is int
              ? json['value'] as int
              : (json['value'] as num?)?.toInt() ?? 0,
    );
  }

  static List<WeeklyAttendance> fromRecords(List<AttendanceRecord> records) {
    final totals = <int, int>{
      DateTime.monday: 0,
      DateTime.tuesday: 0,
      DateTime.wednesday: 0,
      DateTime.thursday: 0,
      DateTime.friday: 0,
      DateTime.saturday: 0,
      DateTime.sunday: 0,
    };

    for (final record in records) {
      final weekday = record.recordedAt.weekday;
      totals[weekday] = (totals[weekday] ?? 0) + 1;
    }

    return [
      WeeklyAttendance(label: 'Lun', value: totals[DateTime.monday] ?? 0),
      WeeklyAttendance(label: 'Mar', value: totals[DateTime.tuesday] ?? 0),
      WeeklyAttendance(label: 'Mié', value: totals[DateTime.wednesday] ?? 0),
      WeeklyAttendance(label: 'Jue', value: totals[DateTime.thursday] ?? 0),
      WeeklyAttendance(label: 'Vie', value: totals[DateTime.friday] ?? 0),
      WeeklyAttendance(label: 'Sáb', value: totals[DateTime.saturday] ?? 0),
      WeeklyAttendance(label: 'Dom', value: totals[DateTime.sunday] ?? 0),
    ];
  }

  static List<WeeklyAttendance> mockWeek() {
    return const [
      WeeklyAttendance(label: 'Lun', value: 80),
      WeeklyAttendance(label: 'Mar', value: 120),
      WeeklyAttendance(label: 'Mié', value: 95),
      WeeklyAttendance(label: 'Jue', value: 110),
      WeeklyAttendance(label: 'Vie', value: 140),
      WeeklyAttendance(label: 'Sáb', value: 90),
      WeeklyAttendance(label: 'Dom', value: 60),
    ];
  }
}

/// Modelo de asistencias por hora para la gráfica diaria.
class HourlyAttendance {
  final String hour;
  final int value;

  const HourlyAttendance({required this.hour, required this.value});

  static List<HourlyAttendance> fromRecords(List<AttendanceRecord> records) {
    // Si no hay registros, retornar horas vacías (todas en 0)
    final now = DateTime.now();
    final dayDate = DateTime(now.year, now.month, now.day);

    final start = DateTime(
      dayDate.year,
      dayDate.month,
      dayDate.day,
      _hourStart,
    );
    final hourFormatter = DateFormat('HH:00');

    final hours = List<DateTime>.generate(
      _baseHourlyDistribution.length,
      (index) => start.add(Duration(hours: index)),
    );

    if (records.isEmpty) {
      return hours
          .map(
            (dt) => HourlyAttendance(hour: hourFormatter.format(dt), value: 0),
          )
          .toList();
    }

    final sorted = List<AttendanceRecord>.from(records)
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final latest = sorted.last.recordedAt;
    final latestDayDate = DateTime(latest.year, latest.month, latest.day);

    // Usar la fecha del último registro, o la fecha actual si es hoy
    final targetDate =
        latestDayDate.year == dayDate.year &&
                latestDayDate.month == dayDate.month &&
                latestDayDate.day == dayDate.day
            ? dayDate
            : latestDayDate;
    final targetStart = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      _hourStart,
    );
    final targetEndExclusive = targetStart.add(
      Duration(hours: _baseHourlyDistribution.length),
    );

    final counts = {for (final hour in hours) hourFormatter.format(hour): 0};

    for (final record in sorted) {
      final recordDay = DateTime(
        record.recordedAt.year,
        record.recordedAt.month,
        record.recordedAt.day,
      );
      if (recordDay != targetDate) continue;
      if (record.recordedAt.isBefore(targetStart) ||
          !record.recordedAt.isBefore(targetEndExclusive)) {
        continue;
      }
      final slotLabel = hourFormatter.format(
        DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          record.recordedAt.hour,
        ),
      );
      counts[slotLabel] = (counts[slotLabel] ?? 0) + 1;
    }

    return hours
        .map(
          (dt) => HourlyAttendance(
            hour: hourFormatter.format(dt),
            value: counts[hourFormatter.format(dt)] ?? 0,
          ),
        )
        .toList();
  }

  static List<HourlyAttendance> fromJsonList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (entry) => HourlyAttendance(
            hour: entry['hour']?.toString() ?? '',
            value:
                entry['value'] is int
                    ? entry['value'] as int
                    : (entry['value'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();
  }

  static List<HourlyAttendance> mockDay() {
    return List<HourlyAttendance>.generate(_baseHourlyDistribution.length, (
      index,
    ) {
      final hour = _hourStart + index;
      final total = _baseHourlyDistribution[index].values.fold<int>(
        0,
        (previousValue, element) => previousValue + element,
      );
      return HourlyAttendance(
        hour: '${hour.toString().padLeft(2, '0')}:00',
        value: total,
      );
    });
  }
}

enum AttendanceRole {
  instructor,
  aprendiz,
  funcionario,
  visitante,
  desconocido,
}

AttendanceRole parseAttendanceRole(dynamic raw) {
  final normalized = raw?.toString().trim().toLowerCase() ?? '';
  switch (normalized) {
    case 'instructor':
    case 'instructores':
      return AttendanceRole.instructor;
    case 'aprendiz':
    case 'aprendices':
      return AttendanceRole.aprendiz;
    case 'funcionario':
    case 'funcionarios':
      return AttendanceRole.funcionario;
    case 'visitante':
    case 'visitantes':
      return AttendanceRole.visitante;
    default:
      return AttendanceRole.desconocido;
  }
}

extension AttendanceRoleDetails on AttendanceRole {
  bool get isTracked => this != AttendanceRole.desconocido;

  String get label {
    switch (this) {
      case AttendanceRole.instructor:
        return 'Instructor';
      case AttendanceRole.aprendiz:
        return 'Aprendiz';
      case AttendanceRole.funcionario:
        return 'Funcionario';
      case AttendanceRole.visitante:
        return 'Visitante';
      case AttendanceRole.desconocido:
        return 'Desconocido';
    }
  }

  String get analyticsKey {
    switch (this) {
      case AttendanceRole.instructor:
        return 'instructores';
      case AttendanceRole.aprendiz:
        return 'aprendices';
      case AttendanceRole.funcionario:
        return 'funcionarios';
      case AttendanceRole.visitante:
        return 'visitantes';
      case AttendanceRole.desconocido:
        return 'desconocido';
    }
  }

  String get code {
    switch (this) {
      case AttendanceRole.instructor:
        return 'INST';
      case AttendanceRole.aprendiz:
        return 'APRE';
      case AttendanceRole.funcionario:
        return 'FUNC';
      case AttendanceRole.visitante:
        return 'VISI';
      case AttendanceRole.desconocido:
        return 'DESC';
    }
  }
}

class AttendanceRecord {
  final AttendanceRole role;
  final String name;
  final DateTime recordedAt;
  final String? sede;

  const AttendanceRecord({
    required this.role,
    required this.name,
    required this.recordedAt,
    this.sede,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final role = parseAttendanceRole(json['rol'] ?? json['role']);
    final rawName = (json['nombre'] ?? json['name'] ?? '').toString().trim();
    final recordedAt =
        _parseDateTime(
          json['timestamp'] ?? json['fecha'] ?? json['created_at'],
        ) ??
        DateTime.now();
    final sede = json['sede']?.toString();

    return AttendanceRecord(
      role: role,
      name: rawName.isNotEmpty ? rawName : role.label,
      recordedAt: recordedAt,
      sede: sede?.isNotEmpty == true ? sede : null,
    );
  }

  /// Parsea un registro del servidor Node.js o Laravel.
  /// Formatos soportados:
  /// - { "id": number, "nombre": string, "rol": string, "hora": "HH:MM:SS AM/PM", "sede": string? }
  /// - { "persona_id": number, "numero_documento": string, "rol": string, "hora_entrada": "HH:MM:SS", "sede": string? }
  /// - { "persona_id": number, "numero_documento": string, "rol": string, "timestamp_entrada": "ISO8601", "sede": string? }
  factory AttendanceRecord.fromServerJson(Map<String, dynamic> json) {
    final role = parseAttendanceRole(json['rol'] ?? json['tipo_persona']);
    final rawName =
        (json['nombre'] ??
                json['nombre_completo'] ??
                json['numero_documento'] ??
                '')
            .toString()
            .trim();

    // Intentar obtener la hora de diferentes campos
    String horaStr = '';
    if (json.containsKey('hora')) {
      horaStr = (json['hora'] ?? '').toString().trim();
    } else if (json.containsKey('hora_entrada')) {
      horaStr = (json['hora_entrada'] ?? '').toString().trim();
    } else if (json.containsKey('timestamp_entrada')) {
      // Si es timestamp, parsearlo directamente
      final timestamp = json['timestamp_entrada'];
      if (timestamp != null) {
        final dt = _parseDateTime(timestamp);
        if (dt != null) {
          return AttendanceRecord(
            role: role,
            name: rawName.isNotEmpty ? rawName : role.label,
            recordedAt: dt,
            sede: json['sede']?.toString(),
          );
        }
      }
    }

    // Parsear sede - puede ser null, string, o objeto anidado
    // El servidor puede enviar sede como string, null, objeto {sede: "nombre"}, o no enviar el campo
    String? sede;
    if (json.containsKey('sede')) {
      final sedeValue = json['sede'];
      if (sedeValue != null) {
        if (sedeValue is Map) {
          // Si es un objeto, intentar obtener el campo 'sede' o 'nombre'
          sede =
              (sedeValue['sede'] ?? sedeValue['nombre'] ?? '')
                  .toString()
                  .trim();
          sede = sede.isNotEmpty ? sede : null;
        } else {
          final sedeRaw = sedeValue.toString().trim();
          sede = sedeRaw.isNotEmpty ? sedeRaw : null;
        }
      } else {
        sede = null;
      }
    } else {
      sede = null;
    }

    // Sede parseada (sin logs para evitar spam)

    // Convertir hora del servidor (formato "HH:MM:SS AM/PM") a DateTime
    final recordedAt = _parseServerHora(horaStr) ?? DateTime.now();

    return AttendanceRecord(
      role: role,
      name: rawName.isNotEmpty ? rawName : role.label,
      recordedAt: recordedAt,
      sede: sede,
    );
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  /// Parsea una hora en formato "HH:MM:SS AM/PM" del servidor Node.js.
  /// Convierte a DateTime usando la fecha actual.
  static DateTime? _parseServerHora(String horaStr) {
    if (horaStr.isEmpty) return null;

    try {
      // Formato esperado: "10:35:45 AM" o "2:05:30 PM"
      final parts = horaStr.split(' ');
      if (parts.length != 2) return null;

      final timePart = parts[0].trim();
      final ampm = parts[1].trim().toUpperCase();

      final timeComponents = timePart.split(':');
      if (timeComponents.length < 2) return null;

      var hour = int.tryParse(timeComponents[0]);
      final minute = int.tryParse(timeComponents[1]);
      final second =
          timeComponents.length > 2 ? int.tryParse(timeComponents[2]) ?? 0 : 0;

      if (hour == null || minute == null) return null;

      // Convertir a formato 24 horas
      if (ampm == 'PM' && hour != 12) {
        hour += 12;
      } else if (ampm == 'AM' && hour == 12) {
        hour = 0;
      }

      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute, second);
    } catch (e) {
      return null;
    }
  }

  static List<AttendanceRecord> mockWeek({
    DateTime? reference,
    double multiplier = 1.0,
  }) {
    final ref = reference ?? DateTime.now();
    final startOfWeek = DateTime(
      ref.year,
      ref.month,
      ref.day,
    ).subtract(Duration(days: ref.weekday - DateTime.monday));

    final records = <AttendanceRecord>[];
    for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
      final day = startOfWeek.add(Duration(days: dayOffset));
      final num rawFactor = (multiplier + (dayOffset - 3) * 0.045).clamp(
        0.6,
        1.4,
      );
      final factor = rawFactor.toDouble();
      records.addAll(_generateDayRecords(day, factor));
    }
    return records;
  }

  static List<AttendanceRecord> _generateDayRecords(
    DateTime day,
    double factor,
  ) {
    final List<AttendanceRecord> records = [];
    for (var index = 0; index < _baseHourlyDistribution.length; index++) {
      final hour = _hourStart + index;
      final slotStart = DateTime(day.year, day.month, day.day, hour);
      final roleMap = _baseHourlyDistribution[index];
      roleMap.forEach((role, baseCount) {
        final count = math.max(0, (baseCount * factor).round());
        for (var i = 0; i < count; i++) {
          records.add(
            AttendanceRecord(
              role: role,
              name:
                  '${role.code}-${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}H${hour.toString().padLeft(2, '0')}-${i + 1}',
              recordedAt: slotStart.add(Duration(minutes: i % 5)),
              sede: 'Centro Agroindustrial',
            ),
          );
        }
      });
    }
    return records;
  }
}

const int _hourStart = 8;

final List<Map<AttendanceRole, int>> _baseHourlyDistribution = [
  {
    AttendanceRole.aprendiz: 24,
    AttendanceRole.instructor: 2,
    AttendanceRole.funcionario: 3,
    AttendanceRole.visitante: 1,
  },
  {
    AttendanceRole.aprendiz: 22,
    AttendanceRole.instructor: 1,
    AttendanceRole.funcionario: 3,
    AttendanceRole.visitante: 1,
  },
  {
    AttendanceRole.aprendiz: 20,
    AttendanceRole.instructor: 1,
    AttendanceRole.funcionario: 3,
    AttendanceRole.visitante: 1,
  },
  {
    AttendanceRole.aprendiz: 26,
    AttendanceRole.instructor: 2,
    AttendanceRole.funcionario: 4,
    AttendanceRole.visitante: 1,
  },
  {
    AttendanceRole.aprendiz: 28,
    AttendanceRole.instructor: 1,
    AttendanceRole.funcionario: 4,
    AttendanceRole.visitante: 2,
  },
  {
    AttendanceRole.aprendiz: 24,
    AttendanceRole.instructor: 1,
    AttendanceRole.funcionario: 3,
    AttendanceRole.visitante: 1,
  },
  {
    AttendanceRole.aprendiz: 21,
    AttendanceRole.instructor: 1,
    AttendanceRole.funcionario: 3,
    AttendanceRole.visitante: 1,
  },
  {
    AttendanceRole.aprendiz: 18,
    AttendanceRole.instructor: 1,
    AttendanceRole.funcionario: 2,
    AttendanceRole.visitante: 1,
  },
  {
    AttendanceRole.aprendiz: 15,
    AttendanceRole.instructor: 1,
    AttendanceRole.funcionario: 2,
    AttendanceRole.visitante: 0,
  },
  {
    AttendanceRole.aprendiz: 12,
    AttendanceRole.instructor: 1,
    AttendanceRole.funcionario: 1,
    AttendanceRole.visitante: 0,
  },
  {
    AttendanceRole.aprendiz: 9,
    AttendanceRole.instructor: 0,
    AttendanceRole.funcionario: 1,
    AttendanceRole.visitante: 0,
  },
];
