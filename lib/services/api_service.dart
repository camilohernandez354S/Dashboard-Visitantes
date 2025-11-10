import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// URL base de la API configurada via --dart-define
const String apiBase = String.fromEnvironment('API_BASE_URL', defaultValue: '');

class ApiService {
  /// Obtiene los datos del dashboard desde la API o desde mock.
  /// Siempre retorna datos válidos; si hay error se usan valores mock.
  static Future<DashboardData> fetchDashboardData() async {
    try {
      if (apiBase.isEmpty) {
        // ignore: avoid_print
        print('📦 [ApiService] API_BASE_URL vacío → usando datos MOCK');
        await Future.delayed(const Duration(milliseconds: 350));
        return DashboardData.mock();
      }

      final uri = Uri.parse('$apiBase/dashboard');
      // ignore: avoid_print
      print('🌐 [ApiService] Consultando: $uri');

      final resp = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 6));

      if (resp.statusCode == 200) {
        // ignore: avoid_print
        print('✅ [ApiService] Respuesta exitosa (${resp.statusCode})');
        final dynamic decoded = jsonDecode(resp.body);

        if (decoded is Map<String, dynamic>) {
          return DashboardData.fromJson(decoded);
        }

        throw const FormatException(
          'Formato de respuesta no soportado. Se esperaba un objeto JSON.',
        );
      } else {
        // ignore: avoid_print
        print('❌ [ApiService] HTTP ${resp.statusCode}: ${resp.body}');
        throw Exception('Error HTTP ${resp.statusCode}');
      }
    } on TimeoutException catch (e) {
      // ignore: avoid_print
      print('⏱️ [ApiService] Timeout: $e');
      return DashboardData.mock();
    } catch (e, s) {
      // ignore: avoid_print
      print('❌ [ApiService] Error inesperado: $e');
      // ignore: avoid_print
      print(s);
      return DashboardData.mock();
    }
  }
}

/// Entidad principal con los datos del dashboard.
class DashboardData {
  final int aprendices;
  final int funcionarios;
  final int visitantes;
  final Map<String, double> variations;
  final List<WeeklyAttendance> weekly;

  const DashboardData({
    required this.aprendices,
    required this.funcionarios,
    required this.visitantes,
    required this.variations,
    required this.weekly,
  });

  DashboardData copyWith({
    int? aprendices,
    int? funcionarios,
    int? visitantes,
    Map<String, double>? variations,
    List<WeeklyAttendance>? weekly,
  }) {
    return DashboardData(
      aprendices: aprendices ?? this.aprendices,
      funcionarios: funcionarios ?? this.funcionarios,
      visitantes: visitantes ?? this.visitantes,
      variations: Map.unmodifiable(variations ?? this.variations),
      weekly: List.unmodifiable(weekly ?? this.weekly),
    );
  }

  DashboardData mergeFromSocket(Map<String, dynamic> payload) {
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

    return copyWith(
      aprendices: _asInt(payload['aprendices']) ?? aprendices,
      funcionarios: _asInt(payload['funcionarios']) ?? funcionarios,
      visitantes: _asInt(payload['visitantes']) ?? visitantes,
      variations: updatedVariations ?? variations,
      weekly: updatedWeekly ?? weekly,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final weeklyList =
        (json['weekly'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(WeeklyAttendance.fromJson)
            .toList();

    final variationsMap = <String, double>{};
    if (json['variations'] is Map) {
      (json['variations'] as Map).forEach((key, value) {
        final doubleVal = value is num ? value.toDouble() : 0.0;
        variationsMap[key.toString()] = doubleVal;
      });
    }

    return DashboardData(
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
      weekly: weeklyList.isNotEmpty ? weeklyList : WeeklyAttendance.mockWeek(),
    );
  }

  factory DashboardData.mock() {
    return DashboardData(
      aprendices: 145,
      funcionarios: 23,
      visitantes: 8,
      variations: const {
        'aprendices': 4.5,
        'funcionarios': -2.1,
        'visitantes': 1.3,
      },
      weekly: WeeklyAttendance.mockWeek(),
    );
  }

  int get weeklyTotal => weekly.fold<int>(
    0,
    (previousValue, element) => previousValue + element.value,
  );

  double variationFor(String key) => variations[key] ?? 0.0;
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
