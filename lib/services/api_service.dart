import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// URL base de la API configurada via --dart-define
const String apiBase = String.fromEnvironment('API_BASE_URL', defaultValue: '');

class ApiService {
  /// Obtiene los datos del dashboard desde la API o datos mock
  static Future<Map<String, dynamic>> fetchDashboardData() async {
    // Modo MOCK si no hay API_BASE_URL configurada
    if (apiBase.isEmpty) {
      // ignore: avoid_print
      print('📦 [ApiService] API_BASE_URL vacío → usando datos MOCK');
      await Future.delayed(const Duration(milliseconds: 600));
      return {
        "aprendices": 145,
        "funcionarios": 23,
        "visitantes": 8,
      };
    }

    // Modo API REAL
    final uri = Uri.parse('$apiBase/dashboard');
    // ignore: avoid_print
    print('🌐 [ApiService] Consultando: $uri');

    try {
      final resp = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 6));

      if (resp.statusCode == 200) {
        // ignore: avoid_print
        print('✅ [ApiService] Respuesta exitosa (${resp.statusCode})');
        final json = jsonDecode(resp.body);
        return {
          "aprendices": (json["aprendices"] ?? 0) as int,
          "funcionarios": (json["funcionarios"] ?? 0) as int,
          "visitantes": (json["visitantes"] ?? 0) as int,
        };
      } else {
        // ignore: avoid_print
        print('❌ [ApiService] HTTP ${resp.statusCode}: ${resp.body}');
        throw Exception('Error HTTP ${resp.statusCode}');
      }
    } on TimeoutException {
      // ignore: avoid_print
      print('⏱️ [ApiService] Timeout consultando $uri');
      rethrow;
    } catch (e, s) {
      // ignore: avoid_print
      print('❌ [ApiService] Error inesperado: $e');
      // ignore: avoid_print
      print(s);
      rethrow;
    }
  }
}
