import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../services/socket_service.dart';

/// Script para probar y documentar los endpoints del backend Laravel
/// Base URL: http://10.7.52.227:8000/api
/// WebSocket: ws://10.7.52.227:8080
class BackendConnectionTester {
  static const String baseUrl = 'http://10.7.52.227:8000/api';
  static const String wsUrl = 'ws://10.7.52.227:8080';
  static const String reverbAppKey = 'local';
  
  static void printSeparator() {
    print('\n${'=' * 80}\n');
  }

  static void printSection(String title) {
    print('\n${'─' * 80}');
    print('📋 $title');
    print('${'─' * 80}\n');
  }

  static void printResponse(String title, int statusCode, Map<String, dynamic> response) {
    printSection(title);
    print('Status Code: $statusCode');
    print('Response Body:');
    print(JsonEncoder.withIndent('  ').convert(response));
  }

  /// 1. GET /websocket/estadisticas
  static Future<void> testGetEstadisticas() async {
    try {
      printSection('1. GET /websocket/estadisticas');
      print('Endpoint: GET $baseUrl/websocket/estadisticas');
      print('Headers: {"Accept": "application/json"}');
      
      final uri = Uri.parse('$baseUrl/websocket/estadisticas');
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('\nResponse Status: ${response.statusCode}');
      print('Response Headers:');
      response.headers.forEach((key, value) {
        print('  $key: $value');
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        printResponse('✅ Respuesta exitosa', response.statusCode, decoded);
        
        print('\n📊 Estructura de datos:');
        if (decoded.containsKey('success')) {
          print('  - success: ${decoded['success']}');
        }
        if (decoded.containsKey('data')) {
          final data = decoded['data'];
          if (data is Map) {
            print('  - data (Map con ${data.length} campos):');
            data.forEach((key, value) {
              print('    • $key: $value (${value.runtimeType})');
            });
          } else if (data is List) {
            print('  - data (List con ${data.length} elementos)');
          } else {
            print('  - data: $data (${data.runtimeType})');
          }
        }
      } else {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        printResponse('❌ Error HTTP ${response.statusCode}', response.statusCode, decoded);
      }
    } catch (e) {
      print('\n❌ Error al realizar GET /websocket/estadisticas:');
      print('  Tipo: ${e.runtimeType}');
      print('  Mensaje: $e');
    }
  }

  /// 2. POST /websocket/entrada
  static Future<void> testPostEntrada() async {
    try {
      printSection('2. POST /websocket/entrada');
      print('Endpoint: POST $baseUrl/websocket/entrada');
      print('Headers: {"Content-Type": "application/json", "Accept": "application/json"}');
      
      final body = {
        'persona_id': 123,
        'nombre': 'Juan Pérez Test',
        'documento': '1234567890',
        'rol': 'VISITANTE',
        'ficha': 'FICHA123',
        'ambiente': 'Ambiente de Prueba',
      };

      print('\nRequest Body:');
      print(JsonEncoder.withIndent('  ').convert(body));

      final uri = Uri.parse('$baseUrl/websocket/entrada');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      print('\nResponse Status: ${response.statusCode}');
      print('Response Headers:');
      response.headers.forEach((key, value) {
        print('  $key: $value');
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        printResponse('✅ Respuesta exitosa', response.statusCode, decoded);
        
        print('\n📋 Estructura de respuesta:');
        if (decoded.containsKey('success')) {
          print('  - success: ${decoded['success']}');
        }
        if (decoded.containsKey('message')) {
          print('  - message: ${decoded['message']}');
        }
        if (decoded.containsKey('visitante')) {
          final visitante = decoded['visitante'] as Map<String, dynamic>;
          print('  - visitante (Map con ${visitante.length} campos):');
          visitante.forEach((key, value) {
            print('    • $key: $value (${value.runtimeType})');
          });
        }
      } else if (response.statusCode == 422) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        printResponse('❌ Error de validación (HTTP 422)', response.statusCode, decoded);
      } else {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        printResponse('❌ Error HTTP ${response.statusCode}', response.statusCode, decoded);
      }
    } catch (e) {
      print('\n❌ Error al realizar POST /websocket/entrada:');
      print('  Tipo: ${e.runtimeType}');
      print('  Mensaje: $e');
    }
  }

  /// 3. POST /websocket/salida
  static Future<void> testPostSalida() async {
    try {
      printSection('3. POST /websocket/salida');
      print('Endpoint: POST $baseUrl/websocket/salida');
      print('Headers: {"Content-Type": "application/json", "Accept": "application/json"}');
      
      final body = {
        'persona_id': 123,
        'nombre': 'Juan Pérez Test',
        'documento': '1234567890',
        'rol': 'VISITANTE',
      };

      print('\nRequest Body:');
      print(JsonEncoder.withIndent('  ').convert(body));

      final uri = Uri.parse('$baseUrl/websocket/salida');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      print('\nResponse Status: ${response.statusCode}');
      print('Response Headers:');
      response.headers.forEach((key, value) {
        print('  $key: $value');
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        printResponse('✅ Respuesta exitosa', response.statusCode, decoded);
        
        print('\n📋 Estructura de respuesta:');
        if (decoded.containsKey('success')) {
          print('  - success: ${decoded['success']}');
        }
        if (decoded.containsKey('message')) {
          print('  - message: ${decoded['message']}');
        }
        if (decoded.containsKey('visitante')) {
          final visitante = decoded['visitante'] as Map<String, dynamic>;
          print('  - visitante (Map con ${visitante.length} campos):');
          visitante.forEach((key, value) {
            print('    • $key: $value (${value.runtimeType})');
          });
        }
      } else if (response.statusCode == 422) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        printResponse('❌ Error de validación (HTTP 422)', response.statusCode, decoded);
      } else {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        printResponse('❌ Error HTTP ${response.statusCode}', response.statusCode, decoded);
      }
    } catch (e) {
      print('\n❌ Error al realizar POST /websocket/salida:');
      print('  Tipo: ${e.runtimeType}');
      print('  Mensaje: $e');
    }
  }

  /// 4. GET /websocket/visitantes-actuales
  static Future<void> testGetVisitantesActuales() async {
    try {
      printSection('4. GET /websocket/visitantes-actuales');
      print('Endpoint: GET $baseUrl/websocket/visitantes-actuales');
      print('Headers: {"Accept": "application/json"}');
      
      final uri = Uri.parse('$baseUrl/websocket/visitantes-actuales');
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('\nResponse Status: ${response.statusCode}');
      print('Response Headers:');
      response.headers.forEach((key, value) {
        print('  $key: $value');
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        printResponse('✅ Respuesta exitosa', response.statusCode, decoded);
        
        print('\n📊 Estructura de datos:');
        if (decoded.containsKey('success')) {
          print('  - success: ${decoded['success']}');
        }
        if (decoded.containsKey('data')) {
          final data = decoded['data'];
          if (data is List) {
            print('  - data (List con ${data.length} elementos)');
            if (data.isNotEmpty) {
              print('    Ejemplo del primer elemento:');
              final first = data.first as Map<String, dynamic>;
              first.forEach((key, value) {
                print('      • $key: $value (${value.runtimeType})');
              });
            }
          } else if (data is Map) {
            print('  - data (Map con ${data.length} campos):');
            data.forEach((key, value) {
              print('    • $key: $value (${value.runtimeType})');
            });
          } else {
            print('  - data: $data (${data.runtimeType})');
          }
        }
      } else {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        printResponse('❌ Error HTTP ${response.statusCode}', response.statusCode, decoded);
      }
    } catch (e) {
      print('\n❌ Error al realizar GET /websocket/visitantes-actuales:');
      print('  Tipo: ${e.runtimeType}');
      print('  Mensaje: $e');
    }
  }

  /// 5. Prueba de conexión WebSocket
  static Future<void> testWebSocketConnection() async {
    try {
      printSection('5. CONEXIÓN WEBSOCKET (Laravel Reverb)');
      print('Endpoint: $wsUrl');
      print('App Key: $reverbAppKey');
      print('Canales: visitantes, estadisticas-visitantes');
      
      final socketService = SocketService(
        url: wsUrl,
        reverbAppKey: reverbAppKey,
        channels: const ['visitantes', 'estadisticas-visitantes'],
      );

      print('\n📡 Intentando conectar al WebSocket...');
      
      // Escuchar eventos del socket
      final subscription = socketService.stream.listen(
        (event) {
          print('\n📨 Evento WebSocket recibido:');
          print(JsonEncoder.withIndent('  ').convert(event));
          
          if (event['event'] == 'visitante.actualizado') {
            print('\n✅ Evento de visitante actualizado recibido');
            final data = event['data'];
            if (data is Map) {
              print('  - Tipo: ${data['tipo'] ?? 'desconocido'}');
              print('  - Visitante: ${data['visitante'] ?? 'N/A'}');
              print('  - Timestamp: ${data['timestamp'] ?? 'N/A'}');
            }
          } else if (event['event'] == 'estadisticas.actualizadas') {
            print('\n✅ Evento de estadísticas actualizadas recibido');
            final data = event['data'];
            if (data is Map) {
              print('  - Estadísticas: ${data['estadisticas'] ?? 'N/A'}');
              print('  - Timestamp: ${data['timestamp'] ?? 'N/A'}');
            }
          }
        },
        onError: (error) {
          print('\n❌ Error en WebSocket: $error');
        },
        onDone: () {
          print('\n🔌 Conexión WebSocket cerrada');
        },
      );

      // Conectar
      socketService.connect();
      
      print('⏳ Esperando conexión y eventos (10 segundos)...');
      await Future.delayed(const Duration(seconds: 10));
      
      print('\n📊 Estado de conexión:');
      print('  - Conectado: ${socketService.isConnected}');
      
      // Esperar un poco más por si hay eventos
      print('\n⏳ Esperando eventos adicionales (5 segundos más)...');
      await Future.delayed(const Duration(seconds: 5));
      
      subscription.cancel();
      socketService.dispose();
      
      print('\n✅ Prueba de WebSocket completada');
    } catch (e) {
      print('\n❌ Error al probar WebSocket:');
      print('  Tipo: ${e.runtimeType}');
      print('  Mensaje: $e');
    }
  }

  /// Ejecuta todas las pruebas REST y luego WebSocket
  static Future<void> runAllTests() async {
    print('\n${'=' * 80}');
    print('🧪 PRUEBAS DE CONEXIÓN AL BACKEND LARAVEL');
    print('Base URL: $baseUrl');
    print('WebSocket URL: $wsUrl');
    print('${'=' * 80}');

    // Pruebas REST
    await testGetEstadisticas();
    await Future.delayed(const Duration(seconds: 1));
    
    await testPostEntrada();
    await Future.delayed(const Duration(seconds: 2));
    
    // Prueba WebSocket después de la entrada (para ver el evento)
    print('\n${'=' * 80}');
    print('📡 INICIANDO PRUEBAS DE WEBSOCKET');
    print('${'=' * 80}');
    await testWebSocketConnection();
    await Future.delayed(const Duration(seconds: 2));
    
    await testPostSalida();
    await Future.delayed(const Duration(seconds: 1));
    
    await testGetVisitantesActuales();

    printSeparator();
    print('✅ Todas las pruebas completadas');
    printSeparator();
  }
}

void main() async {
  try {
    await BackendConnectionTester.runAllTests();
    exit(0);
  } catch (e, stackTrace) {
    print('\n❌ Error fatal: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

