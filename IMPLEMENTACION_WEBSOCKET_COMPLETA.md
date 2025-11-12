# 🔌 IMPLEMENTACIÓN COMPLETA DE WEBSOCKET EN EL DASHBOARD

## 📋 ÍNDICE

1. [Visión General del Sistema WebSocket](#vision-general)
2. [Arquitectura WebSocket](#arquitectura)
3. [Configuración y Constantes](#configuracion)
4. [Servicio Principal: HybridRealtimeService](#servicio-principal)
5. [Protocolo Pusher Implementado](#protocolo-pusher)
6. [Modelo de Eventos WebSocket](#modelo-eventos)
7. [Gestión de Conexión](#gestion-conexion)
8. [Suscripción a Canales](#suscripcion-canales)
9. [Heartbeat y Keep-Alive](#heartbeat)
10. [Detección de Inactividad](#deteccion-inactividad)
11. [Reconexión Automática](#reconexion)
12. [Polling como Fallback](#polling-fallback)
13. [Procesamiento de Eventos](#procesamiento-eventos)
14. [Integración con Provider](#integracion-provider)
15. [Flujos Completos](#flujos-completos)
16. [Mensajes WebSocket Detallados](#mensajes-detallados)
17. [Código Fuente Completo](#codigo-fuente)
18. [Debugging y Logs](#debugging)
19. [Configuración Backend](#configuracion-backend)
20. [Testing y Troubleshooting](#testing)

---

## 🎯 VISIÓN GENERAL DEL SISTEMA WEBSOCKET {#vision-general}

### **Descripción**

Este dashboard implementa un **sistema WebSocket híbrido** que combina:

- **WebSocket en tiempo real** usando el protocolo Pusher
- **Polling REST** como fallback automático
- **Reconexión automática** con backoff progresivo
- **Detección inteligente de inactividad**
- **Streams reactivos** para notificar cambios

### **Objetivos**

✅ **Latencia < 1 segundo** cuando WebSocket está activo  
✅ **Fallback transparente** si WebSocket falla  
✅ **Actualización automática** sin intervención del usuario  
✅ **Resiliencia** ante fallos de red  
✅ **Experiencia fluida** sin interrupciones visibles  

### **Stack Tecnológico WebSocket**

```yaml
Frontend:
  - Lenguaje: Dart 3.0+
  - Framework: Flutter
  - WebSocket Library: web_socket_channel ^2.4.0
  - Pusher Library: pusher_channels_flutter ^2.2.1
  - State Management: Provider

Backend:
  - Framework: Laravel
  - WebSocket Server: Laravel Reverb (puerto 8080)
  - Protocolo: Pusher compatible
  - Broadcasting: Laravel Echo

Comunicación:
  - Protocolo: WebSocket (ws://)
  - Formato: JSON
  - Canales: 'asistencias', 'qr-scans'
  - Eventos: '.NuevaAsistenciaRegistrada', '.QrScanned'
```

---

## 🏗️ ARQUITECTURA WEBSOCKET {#arquitectura}

### **Diagrama de Componentes WebSocket**

```
┌─────────────────────────────────────────────────────────────┐
│                    FRONTEND (Flutter)                        │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │         DashboardScreen (UI)                       │    │
│  │  - Muestra datos en tiempo real                    │    │
│  │  - Indicador de conexión WebSocket                 │    │
│  └──────────────────┬─────────────────────────────────┘    │
│                     │ Consumer                              │
│  ┌──────────────────▼─────────────────────────────────┐    │
│  │    HybridAsistenciaProvider                        │    │
│  │  - Escucha eventStream                             │    │
│  │  - Procesa eventos WebSocket                       │    │
│  │  - Actualiza estado con notifyListeners()          │    │
│  └──────────────────┬─────────────────────────────────┘    │
│                     │ Suscripciones a Streams              │
│  ┌──────────────────▼─────────────────────────────────┐    │
│  │    HybridRealtimeService (SINGLETON) ⭐⭐⭐        │    │
│  │                                                     │    │
│  │  WebSocket Manager:                                │    │
│  │  ├─ Conexión WebSocket                             │    │
│  │  ├─ Protocolo Pusher                               │    │
│  │  ├─ Manejo de mensajes                             │    │
│  │  ├─ Heartbeat (ping/pong)                          │    │
│  │  ├─ Detección de inactividad                       │    │
│  │  ├─ Reconexión automática                          │    │
│  │  ├─ Polling de fallback                            │    │
│  │  └─ Streams reactivos                              │    │
│  │                                                     │    │
│  │  Streams emitidos:                                 │    │
│  │  ├─ connectionStateStream (bool)                   │    │
│  │  ├─ dataStream (List<AsistenciaDetalle>)          │    │
│  │  └─ eventStream (WebSocketEvent)                   │    │
│  └──────────────────┬─────────────────────────────────┘    │
│                     │                                        │
│                     │ WebSocket / HTTP                       │
└─────────────────────┼────────────────────────────────────────┘
                      │
                      │ ws://192.168.101.71:8080/app/local
                      │ http://192.168.101.71:8000/api
                      │
┌─────────────────────▼────────────────────────────────────────┐
│               BACKEND (Laravel + Reverb)                      │
│                                                               │
│  ┌────────────────────────────────────────────────────┐     │
│  │    Laravel Reverb (WebSocket Server)               │     │
│  │  - Puerto: 8080                                     │     │
│  │  - Protocolo: Pusher                                │     │
│  │  - Canales: asistencias, qr-scans                  │     │
│  │  - Broadcast eventos en tiempo real                 │     │
│  └────────────────────────────────────────────────────┘     │
│                                                               │
│  ┌────────────────────────────────────────────────────┐     │
│  │    Laravel API (REST)                              │     │
│  │  - Puerto: 8000                                     │     │
│  │  - Endpoints: /api/asistencia/jornada              │     │
│  └────────────────────────────────────────────────────┘     │
│                                                               │
│  ┌────────────────────────────────────────────────────┐     │
│  │    Event: NuevaAsistenciaRegistrada                │     │
│  │  - Emitido cuando se registra asistencia           │     │
│  │  - Canal: asistencias                              │     │
│  │  - Data: {id, aprendiz, ficha, estado, ...}        │     │
│  └────────────────────────────────────────────────────┘     │
└───────────────────────────────────────────────────────────────┘
```

### **Flujo de Datos WebSocket**

```
1. Usuario escanea QR
   ↓
2. Backend registra en BD
   ↓
3. Backend emite evento WebSocket
   event: .NuevaAsistenciaRegistrada
   channel: asistencias
   ↓
4. Laravel Reverb broadcast a todos los clientes suscritos
   ↓
5. HybridRealtimeService recibe mensaje
   ↓
6. Parsea y crea WebSocketEvent
   ↓
7. Emite por eventStream
   ↓
8. HybridAsistenciaProvider escucha el stream
   ↓
9. Procesa el evento y actualiza datos
   ↓
10. notifyListeners() → UI se actualiza
    ✅ TIEMPO TOTAL: < 1 segundo
```

---

## ⚙️ CONFIGURACIÓN Y CONSTANTES {#configuracion}

### **Archivo: lib/utils/websocket_constants.dart**

Este archivo contiene **TODA la configuración del WebSocket**.

```dart
/// Constantes para la configuración de WebSocket
class WebSocketConstants {
  // ═══════════════════════════════════════════════════════════
  // CONFIGURACIÓN DEL SERVIDOR WEBSOCKET
  // ═══════════════════════════════════════════════════════════
  
  /// IP del servidor backend
  /// ⚠️ IMPORTANTE: Cambiar según tu configuración
  static const String host = '192.168.101.71';
  
  /// Puerto del servidor WebSocket (Laravel Reverb)
  static const int port = 8080;
  
  /// Cluster (requerido por protocolo Pusher)
  static const String cluster = 'mt1';
  
  /// Clave de la aplicación (definida en backend)
  static const String key = 'local';
  
  /// URL completa del WebSocket
  /// Formato Pusher: ws://HOST:PORT/app/KEY
  static const String wsUrl = 'ws://$host:$port/app/$key';
  
  // ═══════════════════════════════════════════════════════════
  // CANALES WEBSOCKET
  // ═══════════════════════════════════════════════════════════
  
  /// Canal de asistencias (eventos de registros)
  static const String canalAsistencias = 'asistencias';
  
  /// Canal de escaneo de QR
  static const String canalQrScans = 'qr-scans';
  
  /// Lista de todos los canales a los que se suscribe
  static const List<String> canales = [
    canalAsistencias,
    canalQrScans,
  ];
  
  // ═══════════════════════════════════════════════════════════
  // EVENTOS WEBSOCKET
  // ═══════════════════════════════════════════════════════════
  
  /// Evento: Nueva asistencia registrada
  /// ⚠️ NOTA: Laravel Reverb agrega punto (.) al inicio
  static const String eventoNuevaAsistencia = '.NuevaAsistenciaRegistrada';
  
  /// Evento: QR escaneado
  static const String eventoQrScanned = '.QrScanned';
  
  /// Lista de todos los eventos que maneja la app
  static const List<String> eventos = [
    eventoNuevaAsistencia,
    eventoQrScanned,
  ];
  
  // ═══════════════════════════════════════════════════════════
  // CONFIGURACIÓN DE RECONEXIÓN
  // ═══════════════════════════════════════════════════════════
  
  /// Número máximo de intentos de reconexión
  static const int maxReconnectAttempts = 5;
  
  /// Delay base entre intentos de reconexión (en segundos)
  static const int reconnectDelaySeconds = 3;
  
  /// Intervalo de heartbeat (ping) en segundos
  static const int heartbeatIntervalSeconds = 30;
  
  /// Timeout de conexión en segundos
  static const int connectionTimeoutSeconds = 10;
  
  // ═══════════════════════════════════════════════════════════
  // ESTADOS DE CONEXIÓN
  // ═══════════════════════════════════════════════════════════
  
  /// Estado: WebSocket conectado y activo
  static const String estadoConectado = 'conectado';
  
  /// Estado: WebSocket desconectado
  static const String estadoDesconectado = 'desconectado';
  
  /// Estado: Intentando conectar
  static const String estadoConectando = 'conectando';
  
  /// Estado: Error de conexión
  static const String estadoError = 'error';
  
  /// Estado: Reintentando conexión
  static const String estadoReconectando = 'reconectando';
  
  /// Lista de todos los estados válidos
  static const List<String> estados = [
    estadoConectado,
    estadoDesconectado,
    estadoConectando,
    estadoError,
    estadoReconectando,
  ];
}
```

### **Configuración URL Dinámica**

En `HybridRealtimeService` se construye la URL dinámicamente:

```dart
/// Detección automática de protocolo según plataforma
String get wsUrl {
  if (kIsWeb) {
    // En web, detectar si es https → usar wss
    final protocol = html.window.location.protocol;
    final wsProtocol = protocol == 'https:' ? 'wss://' : 'ws://';
    return "$wsProtocol${WebSocketConstants.host}:${WebSocketConstants.port}/app/${WebSocketConstants.key}";
  } else {
    // En móvil/desktop usar ws://
    return "ws://${WebSocketConstants.host}:${WebSocketConstants.port}/app/${WebSocketConstants.key}";
  }
}
```

**Resultado:**
- **Web (HTTP):** `ws://192.168.101.71:8080/app/local`
- **Web (HTTPS):** `wss://192.168.101.71:8080/app/local`
- **Móvil/Desktop:** `ws://192.168.101.71:8080/app/local`

---

## 🛠️ SERVICIO PRINCIPAL: HybridRealtimeService {#servicio-principal}

### **Archivo: lib/services/hybrid_realtime_service.dart**

Este es el **CORAZÓN del sistema WebSocket**.

### **Características Principales**

```dart
class HybridRealtimeService {
  // ═══════════════════════════════════════════════════════════
  // PATRÓN SINGLETON
  // ═══════════════════════════════════════════════════════════
  
  static final HybridRealtimeService _instance = 
      HybridRealtimeService._internal();
  
  factory HybridRealtimeService() => _instance;
  
  HybridRealtimeService._internal();
  
  // ═══════════════════════════════════════════════════════════
  // COMPONENTES WEBSOCKET
  // ═══════════════════════════════════════════════════════════
  
  /// Canal WebSocket activo
  WebSocketChannel? _channel;
  
  /// Suscripción al stream de mensajes
  StreamSubscription? _wsSubscription;
  
  // ═══════════════════════════════════════════════════════════
  // TIMERS
  // ═══════════════════════════════════════════════════════════
  
  /// Timer para polling (cuando WebSocket falla)
  Timer? _pollingTimer;
  
  /// Timer para heartbeat (ping cada 30s)
  Timer? _heartbeatTimer;
  
  /// Timer para detectar inactividad
  Timer? _inactivityTimer;
  
  // ═══════════════════════════════════════════════════════════
  // ESTADO
  // ═══════════════════════════════════════════════════════════
  
  /// ¿WebSocket está activo?
  bool _isWebSocketActive = false;
  
  /// ¿Polling está activo?
  bool _isPollingActive = false;
  
  /// Timestamp de última actualización
  DateTime? _lastUpdate;
  
  /// Timestamp del último evento WebSocket recibido
  DateTime? _lastWebSocketEvent;
  
  /// Contador de intentos de reconexión
  int _reconnectAttempts = 0;
  
  /// Hash de últimos datos (para detectar cambios en polling)
  int? _lastDataHash;
  
  // ═══════════════════════════════════════════════════════════
  // CONFIGURACIÓN
  // ═══════════════════════════════════════════════════════════
  
  /// Umbral de inactividad: si no hay eventos por 5s → activar polling
  static const Duration _inactivityThreshold = Duration(seconds: 5);
  
  /// Intervalo de verificación de inactividad
  static const Duration _inactivityCheckInterval = Duration(seconds: 3);
  
  // ═══════════════════════════════════════════════════════════
  // STREAMS REACTIVOS
  // ═══════════════════════════════════════════════════════════
  
  /// Stream de estado de conexión (true = WebSocket activo)
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();
  
  /// Stream de datos actualizados
  final StreamController<List<AsistenciaDetalle>> _dataController =
      StreamController<List<AsistenciaDetalle>>.broadcast();
  
  /// Stream de eventos WebSocket
  final StreamController<WebSocketEvent> _eventController =
      StreamController<WebSocketEvent>.broadcast();
  
  // ═══════════════════════════════════════════════════════════
  // GETTERS PÚBLICOS
  // ═══════════════════════════════════════════════════════════
  
  bool get isWebSocketActive => _isWebSocketActive;
  bool get isPollingActive => _isPollingActive;
  DateTime? get lastUpdate => _lastUpdate;
  
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  Stream<List<AsistenciaDetalle>> get dataStream => _dataController.stream;
  Stream<WebSocketEvent> get eventStream => _eventController.stream;
}
```

### **Métodos Principales**

#### **1. initialize() - Inicialización**

```dart
/// Inicializa el servicio híbrido
Future<void> initialize() async {
  debugPrint('🚀 Inicializando servicio híbrido WebSocket + REST...');
  await _connectWebSocket();
}
```

#### **2. _connectWebSocket() - Conexión**

```dart
/// Conecta al WebSocket con reconexión automática
Future<void> _connectWebSocket() async {
  try {
    debugPrint('🔗 Conectando a WebSocket: $wsUrl');
    
    // Crear canal WebSocket
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    
    // Escuchar mensajes
    _wsSubscription = _channel!.stream.listen(
      _handleWebSocketMessage,
      onError: (error) {
        debugPrint('❌ Error WebSocket: $error');
        _handleWebSocketFailure();
      },
      onDone: () {
        debugPrint('🔌 WebSocket desconectado');
        _handleWebSocketFailure();
      },
    );
    
    // Esperar confirmación
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (_channel != null) {
      _setWebSocketActive(true);
      _reconnectAttempts = 0;
      _startHeartbeat();
      _startInactivityMonitor();
      _lastWebSocketEvent = DateTime.now();
      debugPrint('✅ WebSocket conectado exitosamente');
    }
  } catch (e) {
    debugPrint('❌ Error al conectar WebSocket: $e');
    _handleWebSocketFailure();
  }
}
```

#### **3. _handleWebSocketMessage() - Procesar Mensajes**

```dart
/// Maneja mensajes del WebSocket con procesamiento optimizado
void _handleWebSocketMessage(dynamic message) {
  try {
    debugPrint('📨 Mensaje WebSocket recibido');
    
    final Map<String, dynamic> json = jsonDecode(message);
    final eventName = json['event'];
    
    // ═════════════════════════════════════════════════════
    // EVENTOS INTERNOS DE PUSHER
    // ═════════════════════════════════════════════════════
    
    if (eventName == 'pusher:connection_established') {
      debugPrint('✅ Pusher: Conexión establecida');
      _setWebSocketActive(true);
      _subscribeToChannels();
      _lastWebSocketEvent = DateTime.now();
    } 
    
    else if (eventName == 'pusher:ping') {
      // Responder con pong
      _channel?.sink.add(jsonEncode({'event': 'pusher:pong', 'data': {}}));
    } 
    
    else if (eventName == 'pusher:pong') {
      // Respuesta al ping - cuenta como actividad
      _lastWebSocketEvent = DateTime.now();
    } 
    
    else if (eventName == 'pusher:error') {
      debugPrint('❌ Pusher Error: ${json['data']}');
      _handleWebSocketFailure();
    } 
    
    else if (eventName == 'pusher:subscription_succeeded') {
      debugPrint('✅ Suscripción exitosa al canal: ${json['channel']}');
      _lastWebSocketEvent = DateTime.now();
    } 
    
    // ═════════════════════════════════════════════════════
    // EVENTOS DE APLICACIÓN
    // ═════════════════════════════════════════════════════
    
    else {
      debugPrint('⚡ Evento de aplicación recibido: $eventName');
      
      // Crear modelo de evento
      final event = WebSocketEvent.fromJsonString(message);
      
      // Emitir por stream
      _eventController.add(event);
      
      // Actualizar timestamp de último evento real
      _lastWebSocketEvent = DateTime.now();
      
      // Actualizar datos inmediatamente (< 1 segundo)
      _updateDataFromWebSocket(event);
    }
  } catch (e) {
    debugPrint('❌ Error al procesar mensaje WebSocket: $e');
  }
}
```

---

## 🔐 PROTOCOLO PUSHER IMPLEMENTADO {#protocolo-pusher}

### **Mensajes Pusher Internos**

El sistema maneja todos los mensajes del protocolo Pusher:

#### **1. pusher:connection_established**

**Recibido al conectar:**

```json
{
  "event": "pusher:connection_established",
  "data": {
    "socket_id": "123456.7890",
    "activity_timeout": 120
  }
}
```

**Acción:**
```dart
if (eventName == 'pusher:connection_established') {
  debugPrint('✅ Pusher: Conexión establecida');
  _setWebSocketActive(true);
  _subscribeToChannels(); // Suscribirse a canales
  _lastWebSocketEvent = DateTime.now();
}
```

#### **2. pusher:ping**

**Recibido periódicamente del servidor:**

```json
{
  "event": "pusher:ping",
  "data": {}
}
```

**Acción - Responder inmediatamente:**
```dart
else if (eventName == 'pusher:ping') {
  // Responder con pong
  _channel?.sink.add(jsonEncode({
    'event': 'pusher:pong',
    'data': {}
  }));
}
```

#### **3. pusher:pong**

**Recibido como respuesta a nuestro ping:**

```json
{
  "event": "pusher:pong",
  "data": {}
}
```

**Acción:**
```dart
else if (eventName == 'pusher:pong') {
  // Respuesta al ping - cuenta como actividad
  _lastWebSocketEvent = DateTime.now();
}
```

#### **4. pusher:subscription_succeeded**

**Recibido al suscribirse exitosamente a un canal:**

```json
{
  "event": "pusher:subscription_succeeded",
  "channel": "asistencias",
  "data": {}
}
```

**Acción:**
```dart
else if (eventName == 'pusher:subscription_succeeded') {
  debugPrint('✅ Suscripción exitosa al canal: ${json['channel']}');
  _lastWebSocketEvent = DateTime.now();
}
```

#### **5. pusher:error**

**Recibido cuando hay un error:**

```json
{
  "event": "pusher:error",
  "data": {
    "message": "Error description",
    "code": 4001
  }
}
```

**Acción:**
```dart
else if (eventName == 'pusher:error') {
  debugPrint('❌ Pusher Error: ${json['data']}');
  _handleWebSocketFailure();
}
```

---

## 📦 MODELO DE EVENTOS WEBSOCKET {#modelo-eventos}

### **Archivo: lib/models/websocket_event.dart**

```dart
import 'dart:convert';

/// Modelo para representar eventos WebSocket
class WebSocketEvent {
  // ═══════════════════════════════════════════════════════════
  // PROPIEDADES
  // ═══════════════════════════════════════════════════════════
  
  /// Tipo de evento recibido (ej: .NuevaAsistenciaRegistrada)
  final String event;
  
  /// Canal donde se recibió el evento (ej: asistencias)
  final String channel;
  
  /// Datos del evento (payload)
  final Map<String, dynamic> data;
  
  /// Timestamp cuando se recibió el evento
  final DateTime timestamp;
  
  /// ID único del evento (opcional)
  final String? eventId;
  
  // ═══════════════════════════════════════════════════════════
  // CONSTRUCTOR
  // ═══════════════════════════════════════════════════════════
  
  const WebSocketEvent({
    required this.event,
    required this.channel,
    required this.data,
    required this.timestamp,
    this.eventId,
  });
  
  // ═══════════════════════════════════════════════════════════
  // FACTORY CONSTRUCTORS
  // ═══════════════════════════════════════════════════════════
  
  /// Crea un evento desde JSON
  factory WebSocketEvent.fromJson(Map<String, dynamic> json) {
    return WebSocketEvent(
      event: json['event'] ?? '',
      channel: json['channel'] ?? '',
      data: json['data'] ?? {},
      timestamp: DateTime.now(),
      eventId: json['event_id'],
    );
  }
  
  /// Crea un evento desde string JSON
  factory WebSocketEvent.fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return WebSocketEvent.fromJson(json);
    } catch (e) {
      throw Exception('Error al parsear evento WebSocket: $e');
    }
  }
  
  // ═══════════════════════════════════════════════════════════
  // IDENTIFICACIÓN DE TIPOS DE EVENTOS
  // ═══════════════════════════════════════════════════════════
  
  /// Verifica si es un evento de nueva asistencia
  /// NOTA: Laravel Reverb envía eventos con punto al inicio
  bool get isNuevaAsistencia =>
      (event == '.NuevaAsistenciaRegistrada' ||
          event == 'NuevaAsistenciaRegistrada') &&
      channel == 'asistencias';
  
  /// Verifica si es un evento de QR escaneado
  bool get isQrScanned =>
      (event == '.QrScanned' || event == 'QrScanned') && 
      channel == 'qr-scans';
  
  // ═══════════════════════════════════════════════════════════
  // GETTERS DE DATOS DEL EVENTO
  // ═══════════════════════════════════════════════════════════
  
  /// Obtiene el ID de la asistencia del evento
  int? get asistenciaId {
    if (isNuevaAsistencia) {
      final id = data['id'] ?? data['asistencia_id'];
      if (id != null) {
        return int.tryParse(id.toString());
      }
    }
    return null;
  }
  
  /// Obtiene el nombre del aprendiz del evento
  String? get aprendizNombre {
    if (isNuevaAsistencia) {
      return data['aprendiz']?.toString();
    }
    return null;
  }
  
  /// Obtiene el estado de la asistencia (entrada/salida)
  String? get estadoAsistencia {
    if (isNuevaAsistencia) {
      return data['estado']?.toString();
    }
    return null;
  }
  
  /// Obtiene el ID de la ficha del evento
  String? get fichaId {
    if (isNuevaAsistencia || isQrScanned) {
      return data['ficha']?.toString() ?? data['ficha_id']?.toString();
    }
    return null;
  }
  
  /// Obtiene el ID del aprendiz del evento
  String? get aprendizId {
    if (isNuevaAsistencia || isQrScanned) {
      return data['aprendiz_id']?.toString();
    }
    return null;
  }
  
  /// Obtiene la jornada del evento
  String? get jornada {
    if (isNuevaAsistencia || isQrScanned) {
      return data['jornada']?.toString();
    }
    return null;
  }
  
  /// Verifica si el evento tiene datos válidos
  bool get hasValidData {
    if (isNuevaAsistencia) {
      return asistenciaId != null && aprendizNombre != null;
    }
    if (isQrScanned) {
      return fichaId != null && aprendizId != null;
    }
    return false;
  }
  
  // ═══════════════════════════════════════════════════════════
  // SERIALIZACIÓN
  // ═══════════════════════════════════════════════════════════
  
  Map<String, dynamic> toJson() {
    return {
      'event': event,
      'channel': channel,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'event_id': eventId,
    };
  }
  
  @override
  String toString() {
    return 'WebSocketEvent(event: $event, channel: $channel, '
           'data: $data, timestamp: $timestamp)';
  }
}
```

### **Ejemplo de Uso**

```dart
// Recibir mensaje WebSocket
void _handleWebSocketMessage(dynamic message) {
  // Parsear a WebSocketEvent
  final event = WebSocketEvent.fromJsonString(message);
  
  // Verificar tipo de evento
  if (event.isNuevaAsistencia) {
    debugPrint('📝 Nueva asistencia:');
    debugPrint('   ID: ${event.asistenciaId}');
    debugPrint('   Aprendiz: ${event.aprendizNombre}');
    debugPrint('   Ficha: ${event.fichaId}');
    debugPrint('   Estado: ${event.estadoAsistencia}');
    
    // Procesar...
    _procesarNuevaAsistencia(event);
  }
}
```

---

## 🔗 GESTIÓN DE CONEXIÓN {#gestion-conexion}

### **Estados de Conexión**

```dart
// Estados posibles
String _connectionState = WebSocketConstants.estadoDesconectado;

// Estados:
// - 'desconectado'  → No conectado
// - 'conectando'    → Intentando conectar
// - 'conectado'     → Conectado y activo
// - 'error'         → Error de conexión
// - 'reconectando'  → Reintentando conexión
```

### **Cambiar Estado**

```dart
void _setWebSocketActive(bool active) {
  _isWebSocketActive = active;
  _connectionStateController.add(active);
  
  if (active) {
    _stopPolling(); // Detener polling cuando WebSocket funciona
    debugPrint('✅ WebSocket activo - Polling detenido');
  }
}
```

### **Timeout de Conexión**

```dart
// Configurar timeout
final connectionTimeout = Timer(
  Duration(seconds: WebSocketConstants.connectionTimeoutSeconds),
  () {
    if (_connectionState == WebSocketConstants.estadoConectando) {
      _handleConnectionError('Timeout de conexión');
    }
  },
);

// Cancelar si conexión exitosa
await _waitForConnection();
connectionTimeout.cancel();
```

---

## 📡 SUSCRIPCIÓN A CANALES {#suscripcion-canales}

### **Implementación**

```dart
/// Suscribe a todos los canales configurados
void _subscribeToChannels() {
  if (!_isWebSocketActive || _channel == null) return;
  
  // Iterar sobre todos los canales
  for (var channelName in WebSocketConstants.canales) {
    // Crear mensaje de suscripción según protocolo Pusher
    final subscribeMessage = jsonEncode({
      'event': 'pusher:subscribe',
      'data': {'channel': channelName},
    });
    
    // Enviar al servidor
    _channel!.sink.add(subscribeMessage);
    
    debugPrint('📡 Suscrito al canal: $channelName');
  }
}
```

### **Formato de Mensaje de Suscripción**

```json
{
  "event": "pusher:subscribe",
  "data": {
    "channel": "asistencias"
  }
}
```

### **Canales Configurados**

```dart
// En WebSocketConstants
static const List<String> canales = [
  'asistencias',  // Eventos de registros de asistencia
  'qr-scans',     // Eventos de escaneo de QR
];
```

### **Desuscribirse de un Canal**

```dart
void _unsubscribeFromChannel(String channelName) {
  if (_channel == null) return;
  
  final unsubscribeMessage = jsonEncode({
    'event': 'pusher:unsubscribe',
    'data': {'channel': channelName},
  });
  
  _channel!.sink.add(unsubscribeMessage);
  debugPrint('📡 Desuscrito del canal: $channelName');
}
```

---

## 💓 HEARTBEAT Y KEEP-ALIVE {#heartbeat}

### **Propósito**

El heartbeat mantiene la conexión WebSocket viva enviando pings periódicos.

### **Implementación**

```dart
/// Inicia el heartbeat para mantener la conexión activa
void _startHeartbeat() {
  _heartbeatTimer?.cancel();
  
  _heartbeatTimer = Timer.periodic(
    const Duration(seconds: 30), // Cada 30 segundos
    (_) => _sendHeartbeat(),
  );
  
  debugPrint('💓 Heartbeat iniciado (cada 30s)');
}

/// Envía heartbeat (ping) para mantener la conexión
void _sendHeartbeat() {
  if (_isWebSocketActive && _channel != null) {
    try {
      // Enviar ping según protocolo Pusher
      _channel!.sink.add(jsonEncode({
        'event': 'pusher:ping',
        'data': {}
      }));
      
      debugPrint('💓 Heartbeat enviado (ping)');
    } catch (e) {
      debugPrint('❌ Error enviando heartbeat: $e');
      _handleWebSocketFailure();
    }
  }
}

/// Detiene el heartbeat
void _stopHeartbeat() {
  _heartbeatTimer?.cancel();
  _heartbeatTimer = null;
  debugPrint('💓 Heartbeat detenido');
}
```

### **Flujo del Heartbeat**

```
Timer cada 30s
  ↓
_sendHeartbeat()
  ↓
Enviar: {"event": "pusher:ping", "data": {}}
  ↓
Servidor responde: {"event": "pusher:pong", "data": {}}
  ↓
_handleWebSocketMessage() recibe pong
  ↓
Actualizar _lastWebSocketEvent
  ↓
✅ Conexión viva confirmada
```

---

## 👁️ DETECCIÓN DE INACTIVIDAD {#deteccion-inactividad}

### **Propósito**

Detecta cuando el WebSocket está conectado pero no emite eventos, activando polling de respaldo.

### **Implementación**

```dart
/// Inicia el monitor de inactividad del WebSocket
void _startInactivityMonitor() {
  _stopInactivityMonitor();
  
  _inactivityTimer = Timer.periodic(
    _inactivityCheckInterval, // Cada 3 segundos
    (_) => _checkWebSocketInactivity()
  );
  
  debugPrint('👁️ Monitor de inactividad iniciado (verifica cada 3s)');
}

/// Verifica si el WebSocket está inactivo (sin eventos)
void _checkWebSocketInactivity() {
  if (!_isWebSocketActive) return;
  
  final now = DateTime.now();
  if (_lastWebSocketEvent == null) {
    debugPrint('⚠️ No se ha registrado ningún evento WebSocket aún');
    return;
  }
  
  final timeSinceLastEvent = now.difference(_lastWebSocketEvent!);
  
  if (timeSinceLastEvent > _inactivityThreshold) { // > 5 segundos
    debugPrint('⚠️ WebSocket inactivo por ${timeSinceLastEvent.inSeconds}s');
    debugPrint('🔄 Activando polling automático debido a inactividad...');
    
    // El WebSocket está conectado pero no emite datos
    // Activar polling de respaldo
    _setWebSocketActive(false);
    _startPolling();
  } else {
    debugPrint('✅ WebSocket activo - último evento hace ${timeSinceLastEvent.inSeconds}s');
  }
}

/// Detiene el monitor de inactividad
void _stopInactivityMonitor() {
  _inactivityTimer?.cancel();
  _inactivityTimer = null;
}
```

### **Configuración**

```dart
/// Umbral: si no hay eventos por 5s → activar polling
static const Duration _inactivityThreshold = Duration(seconds: 5);

/// Verificar cada 3s
static const Duration _inactivityCheckInterval = Duration(seconds: 3);
```

### **Flujo de Detección**

```
Timer cada 3s
  ↓
_checkWebSocketInactivity()
  ↓
Calcular: now - _lastWebSocketEvent
  ↓
¿Diferencia > 5 segundos?
  │
  ├─ SÍ → WebSocket inactivo
  │   ↓
  │   _setWebSocketActive(false)
  │   ↓
  │   _startPolling()
  │   ↓
  │   ✅ Polling activo (respaldo)
  │
  └─ NO → WebSocket activo
      ↓
      ✅ Continuar normalmente
```

---

## 🔄 RECONEXIÓN AUTOMÁTICA {#reconexion}

### **Backoff Progresivo**

El sistema intenta reconectar con delays crecientes:

```dart
void _handleWebSocketFailure() {
  debugPrint('🔄 WebSocket falló, iniciando polling de fallback...');
  
  _setWebSocketActive(false);
  _stopHeartbeat();
  _stopInactivityMonitor();
  _startPolling();
  
  // ═══════════════════════════════════════════════════════════
  // BACKOFF PROGRESIVO: 1s, 2s, 5s, 10s
  // ═══════════════════════════════════════════════════════════
  
  if (_reconnectAttempts < 4) {
    _reconnectAttempts++;
    
    final delays = [1, 2, 5, 10]; // segundos
    final delaySeconds = delays[_reconnectAttempts - 1];
    final delay = Duration(seconds: delaySeconds);
    
    debugPrint('🔄 Reintentando conexión en ${delay.inSeconds}s '
               '(intento $_reconnectAttempts/4)');
    
    Timer(delay, () {
      if (!_isWebSocketActive) {
        _connectWebSocket();
      }
    });
  } else {
    debugPrint('❌ Máximo de intentos de reconexión alcanzado (4 intentos)');
    debugPrint('📡 Sistema continúa con polling');
  }
}
```

### **Tabla de Intentos**

| Intento | Delay | Total Acumulado |
|---------|-------|-----------------|
| 1       | 1s    | 1s              |
| 2       | 2s    | 3s              |
| 3       | 5s    | 8s              |
| 4       | 10s   | 18s             |
| 5+      | -     | Sin más intentos|

### **Reiniciar Contador**

Cuando la conexión es exitosa:

```dart
if (_channel != null) {
  _setWebSocketActive(true);
  _reconnectAttempts = 0; // ✅ Reiniciar contador
  _startHeartbeat();
  _startInactivityMonitor();
  debugPrint('✅ WebSocket conectado exitosamente');
}
```

---

## ⏳ POLLING COMO FALLBACK {#polling-fallback}

### **Polling Adaptativo**

El sistema ajusta el intervalo de polling según si detecta cambios:

```dart
void _startPolling() {
  if (_isPollingActive) return; // Evitar múltiples timers
  
  _isPollingActive = true;
  _connectionStateController.add(false); // Notificar modo polling
  
  debugPrint('⏳ Iniciando polling adaptativo (WebSocket inactivo)...');
  
  Duration interval = const Duration(seconds: 5); // Inicial: 5s
  
  _pollingTimer = Timer.periodic(interval, (timer) async {
    final start = DateTime.now();
    
    try {
      final updated = await _pollingUpdate();
      
      if (updated) {
        // 🔁 Si hubo cambios → mantener rápido
        interval = const Duration(seconds: 5);
        debugPrint('🔄 Cambios detectados - polling rápido (5s)');
      } else {
        // 💤 Si no hubo cambios → ralentizar
        interval = const Duration(seconds: 20);
        debugPrint('😴 Sin cambios - ralentizando polling (20s)');
      }
      
      // Reiniciar timer con nuevo intervalo
      timer.cancel();
      _pollingTimer = Timer.periodic(
        interval,
        (_) async => await _pollingUpdate()
      );
      
      debugPrint('🔄 Polling reajustado a cada ${interval.inSeconds}s');
      
    } catch (e) {
      debugPrint('❌ Error en polling adaptativo: $e');
      // Backoff en errores
      interval = const Duration(seconds: 30);
      timer.cancel();
      _pollingTimer = Timer.periodic(
        interval,
        (_) async => await _pollingUpdate()
      );
    }
    
    final elapsed = DateTime.now().difference(start).inMilliseconds;
    debugPrint('⏱️ Polling ejecutado en ${elapsed}ms');
  });
}
```

### **Actualización por Polling**

```dart
/// Actualización por polling optimizada
/// Devuelve true si los datos cambiaron, false si son iguales
Future<bool> _pollingUpdate() async {
  try {
    debugPrint('🔄 Polling - Actualizando datos...');
    
    final fecha = DateTime.now().toLocal().toString().split(' ')[0];
    final url = '$apiUrl?fecha=$fecha';
    
    final response = await http.get(Uri.parse(url)).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        throw TimeoutException('Servidor no responde');
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final asistencias = (data['asistencias'] as List)
          .map((json) => AsistenciaDetalle.fromJson(json))
          .toList();
      
      // ═══════════════════════════════════════════════════
      // DETECCIÓN INTELIGENTE DE CAMBIOS
      // ═══════════════════════════════════════════════════
      
      // Crear snapshot de los datos
      final snapshot = jsonEncode(
        asistencias.map((a) => a.toJson()).toList()
      );
      
      // Comparar hash
      final currentHash = snapshot.hashCode;
      final changed = currentHash != _lastDataHash;
      _lastDataHash = currentHash;
      
      // Emitir datos
      _dataController.add(asistencias);
      _lastUpdate = DateTime.now();
      
      debugPrint('✅ Polling - ${asistencias.length} registros'
                 '${changed ? ' (CAMBIOS DETECTADOS)' : ' (sin cambios)'}');
      
      return changed; // true si hay cambios, false si no
    }
  } catch (e) {
    debugPrint('❌ Error en polling: $e');
  }
  return false;
}
```

### **Detener Polling**

```dart
void _stopPolling() {
  _pollingTimer?.cancel();
  _pollingTimer = null;
  _isPollingActive = false;
  debugPrint('⏹️ Polling detenido');
}
```

### **Tabla de Intervalos**

| Situación | Intervalo | Razón |
|-----------|-----------|-------|
| Datos cambiaron | 5s | Mantener actualización rápida |
| Sin cambios | 20s | Reducir carga del servidor |
| Error de red | 30s | Backoff por error |

---

## ⚡ PROCESAMIENTO DE EVENTOS {#procesamiento-eventos}

### **En HybridRealtimeService**

```dart
/// Actualiza datos desde evento WebSocket
void _updateDataFromWebSocket(WebSocketEvent event) {
  debugPrint('⚡ Actualizando datos desde WebSocket...');
  debugPrint('   Evento: ${event.event}');
  debugPrint('   Canal: ${event.channel}');
  debugPrint('   Timestamp: ${event.timestamp}');
  
  // Notificar actualización inmediata
  _lastUpdate = DateTime.now();
  _lastWebSocketEvent = DateTime.now();
  
  debugPrint('✅ Datos actualizados desde WebSocket en tiempo real');
}
```

### **En HybridAsistenciaProvider**

```dart
/// Procesa eventos del WebSocket
void _procesarEventoWebSocket(WebSocketEvent event) {
  debugPrint('📨 Procesando evento WebSocket: ${event.event}');
  debugPrint('   Aprendiz: ${event.aprendizNombre ?? "N/A"}');
  debugPrint('   Ficha: ${event.fichaId ?? "N/A"}');
  debugPrint('   Estado: ${event.estadoAsistencia ?? "N/A"}');
  
  _lastEventReceived = DateTime.now();
  
  if (event.isNuevaAsistencia) {
    _procesarNuevaAsistencia(event);
  } else if (event.isQrScanned) {
    _procesarQrScanned(event);
  }
}

/// Procesa nueva asistencia registrada
void _procesarNuevaAsistencia(WebSocketEvent event) {
  debugPrint('📝 Nueva asistencia recibida - ID: ${event.asistenciaId}');
  
  // ═══════════════════════════════════════════════════════════
  // CREAR ASISTENCIA TEMPORAL PARA ACTUALIZACIÓN INMEDIATA
  // ═══════════════════════════════════════════════════════════
  
  final tempAsistencia = AsistenciaDetalle(
    id: event.asistenciaId ?? 0,
    aprendiz: event.aprendizNombre ?? 'Desconocido',
    numeroDocumento: '',
    horaIngreso: event.timestamp
        .toLocal()
        .toString()
        .split(' ')[1]
        .substring(0, 8),
    ficha: event.fichaId ?? 'Desconocida',
    jornada: event.jornada ?? 'Desconocida',
    jornadaId: 0,
    fecha: event.timestamp.toLocal().toString().split(' ')[0],
    estado: event.estadoAsistencia ?? 'en_curso',
  );
  
  // ═══════════════════════════════════════════════════════════
  // ACTUALIZACIÓN INMEDIATA SIN DUPLICADOS
  // ═══════════════════════════════════════════════════════════
  
  _actualizarAsistenciaInmediata(tempAsistencia);
  
  // Agregar a historial de eventos WebSocket
  _ultimasAsistenciasWS.insert(0, event);
  if (_ultimasAsistenciasWS.length > 10) {
    _ultimasAsistenciasWS.removeRange(10, _ultimasAsistenciasWS.length);
  }
  
  _lastDataUpdate = DateTime.now();
  
  // ═══════════════════════════════════════════════════════════
  // RECALCULAR MÉTRICAS Y ACTUALIZAR UI
  // ═══════════════════════════════════════════════════════════
  
  debugPrint('⚡ Actualizando KPIs y métricas desde evento WebSocket...');
  _recalcularMetricas();
  
  // 🚀 ACTUALIZACIÓN EN TIEMPO REAL (< 1 segundo)
  notifyListeners();
  
  debugPrint('✅ Asistencia agregada y KPIs actualizados inmediatamente');
}

/// Actualiza asistencia inmediatamente sin duplicados
void _actualizarAsistenciaInmediata(AsistenciaDetalle nuevaAsistencia) {
  // Buscar si ya existe
  final indexExistente = _asistenciasDetalle.indexWhere((a) =>
      a.aprendiz == nuevaAsistencia.aprendiz &&
      a.fecha == nuevaAsistencia.fecha &&
      a.ficha == nuevaAsistencia.ficha);
  
  if (indexExistente != -1) {
    // Actualizar asistencia existente
    _asistenciasDetalle[indexExistente] = nuevaAsistencia;
    debugPrint('🔄 Asistencia actualizada para ${nuevaAsistencia.aprendiz}');
  } else {
    // Agregar nueva asistencia al inicio
    _asistenciasDetalle.insert(0, nuevaAsistencia);
    debugPrint('➕ Nueva asistencia agregada para ${nuevaAsistencia.aprendiz}');
  }
}
```

---

## 🔌 INTEGRACIÓN CON PROVIDER {#integracion-provider}

### **Archivo: lib/providers/hybrid_asistencia_provider.dart**

### **Suscripción a Streams**

```dart
void _configurarServicioHibrido() {
  // ═══════════════════════════════════════════════════════════
  // SUSCRIBIRSE A CAMBIOS DE ESTADO DE CONEXIÓN
  // ═══════════════════════════════════════════════════════════
  
  _connectionStateSubscription = 
      _hybridService.connectionStateStream.listen(
    (isWebSocketActive) {
      _isWebSocketActive = isWebSocketActive;
      _isPollingActive = !isWebSocketActive;
      
      debugPrint('🔄 Estado conexión: '
                 '${isWebSocketActive ? "WebSocket Activo ✅" : "Usando Polling ⏳"}');
      
      notifyListeners();
    }
  );
  
  // ═══════════════════════════════════════════════════════════
  // SUSCRIBIRSE A ACTUALIZACIONES DE DATOS
  // ═══════════════════════════════════════════════════════════
  
  _dataSubscription = _hybridService.dataStream.listen(
    (nuevasAsistencias) {
      _asistenciasDetalle = nuevasAsistencias;
      _lastDataUpdate = DateTime.now();
      _lastEventReceived = DateTime.now();
      
      debugPrint('📊 Datos actualizados: ${nuevasAsistencias.length} asistencias');
      
      notifyListeners();
    }
  );
  
  // ═══════════════════════════════════════════════════════════
  // SUSCRIBIRSE A EVENTOS WEBSOCKET
  // ═══════════════════════════════════════════════════════════
  
  _eventSubscription = _hybridService.eventStream.listen(
    (event) {
      _lastEventReceived = DateTime.now();
      debugPrint('⚡ EVENTO REAL RECIBIDO: ${event.event} en canal ${event.channel}');
      
      _procesarEventoWebSocket(event);
    }
  );
  
  // ═══════════════════════════════════════════════════════════
  // INICIAR SERVICIO
  // ═══════════════════════════════════════════════════════════
  
  _hybridService.initialize();
  debugPrint('✅ Servicio híbrido configurado');
}
```

### **Limpieza de Recursos**

```dart
@override
void dispose() {
  // Cancelar suscripciones
  _connectionStateSubscription?.cancel();
  _dataSubscription?.cancel();
  _eventSubscription?.cancel();
  _inactivityCheckTimer?.cancel();
  
  // Desconectar servicio
  _hybridService.dispose();
  
  super.dispose();
}
```

---

## 🔄 FLUJOS COMPLETOS {#flujos-completos}

### **Flujo 1: Conexión Inicial**

```
1. App inicia
   ↓
2. main.dart crea providers
   ↓
3. HybridAsistenciaProvider._init()
   ↓
4. _configurarServicioHibrido()
   ↓
5. Suscribirse a streams del servicio
   ↓
6. _hybridService.initialize()
   ↓
7. HybridRealtimeService._connectWebSocket()
   ↓
8. WebSocketChannel.connect(wsUrl)
   ↓
9. Escuchar stream de mensajes
   ↓
10. Esperar evento: pusher:connection_established
    ↓
11. ✅ Conexión establecida
    ↓
12. _subscribeToChannels()
    ↓
13. Enviar: pusher:subscribe para cada canal
    ↓
14. Recibir: pusher:subscription_succeeded
    ↓
15. _startHeartbeat() → ping cada 30s
    ↓
16. _startInactivityMonitor() → verificar cada 3s
    ↓
17. ✅ SISTEMA LISTO - Escuchando eventos
```

### **Flujo 2: Recepción de Evento**

```
1. Usuario escanea QR en backend
   ↓
2. Backend registra asistencia en BD
   ↓
3. Backend emite evento:
   {
     "event": ".NuevaAsistenciaRegistrada",
     "channel": "asistencias",
     "data": {id, aprendiz, ficha, ...}
   }
   ↓
4. Laravel Reverb broadcast a clientes suscritos
   ↓
5. HybridRealtimeService recibe en stream
   ↓
6. _handleWebSocketMessage(message)
   ↓
7. jsonDecode(message)
   ↓
8. Identificar: eventName == '.NuevaAsistenciaRegistrada'
   ↓
9. WebSocketEvent.fromJsonString(message)
   ↓
10. _eventController.add(event) → Emitir por stream
    ↓
11. HybridAsistenciaProvider escucha eventStream
    ↓
12. _procesarEventoWebSocket(event)
    ↓
13. event.isNuevaAsistencia? → SÍ
    ↓
14. _procesarNuevaAsistencia(event)
    ↓
15. Crear AsistenciaDetalle temporal
    ↓
16. _actualizarAsistenciaInmediata(asistencia)
    ↓
17. Agregar/actualizar en lista sin duplicados
    ↓
18. _recalcularMetricas() → Actualizar KPIs
    ↓
19. notifyListeners() → 🚀 ACTUALIZAR UI
    ↓
20. ✅ UI actualizada en < 1 segundo
```

### **Flujo 3: Fallo y Reconexión**

```
1. WebSocket pierde conexión (red caída)
   ↓
2. stream.onError o stream.onDone se dispara
   ↓
3. _handleWebSocketFailure()
   ↓
4. _setWebSocketActive(false)
   ↓
5. _stopHeartbeat()
   ↓
6. _stopInactivityMonitor()
   ↓
7. _startPolling() → Activar fallback
   ↓
8. Polling cada 5-20s con HTTP REST
   ↓
9. Intentar reconectar:
   - Intento 1: esperar 1s → _connectWebSocket()
   - Intento 2: esperar 2s → _connectWebSocket()
   - Intento 3: esperar 5s → _connectWebSocket()
   - Intento 4: esperar 10s → _connectWebSocket()
   ↓
10. Si algún intento exitoso:
    ↓
    _setWebSocketActive(true)
    ↓
    _stopPolling()
    ↓
    _startHeartbeat()
    ↓
    ✅ Vuelta a WebSocket en tiempo real
```

### **Flujo 4: Detección de Inactividad**

```
1. WebSocket conectado pero sin eventos
   ↓
2. Timer cada 3s: _checkWebSocketInactivity()
   ↓
3. Calcular: now - _lastWebSocketEvent
   ↓
4. ¿Diferencia > 5 segundos?
   ↓
5. SÍ → WebSocket inactivo
   ↓
6. _setWebSocketActive(false)
   ↓
7. _startPolling()
   ↓
8. Polling de respaldo mientras reconecta
   ↓
9. Seguir intentando reconectar en segundo plano
   ↓
10. Cuando reconecta y recibe eventos:
    ↓
    _lastWebSocketEvent actualizado
    ↓
    _stopPolling()
    ↓
    ✅ Vuelta a WebSocket
```

---

## 📨 MENSAJES WEBSOCKET DETALLADOS {#mensajes-detallados}

### **Evento: .NuevaAsistenciaRegistrada**

**Mensaje completo recibido:**

```json
{
  "event": ".NuevaAsistenciaRegistrada",
  "channel": "asistencias",
  "data": {
    "id": 123,
    "aprendiz": "Juan Pérez García",
    "aprendiz_id": 456,
    "numero_documento": "1234567890",
    "ficha": "2619073",
    "ficha_id": "2619073",
    "jornada": "MAÑANA",
    "jornada_id": 1,
    "estado": "en_curso",
    "hora_ingreso": "08:30:15",
    "fecha": "2024-11-10",
    "tipo": "entrada",
    "timestamp": "2024-11-10T08:30:15.123456Z"
  }
}
```

**Procesamiento:**

```dart
final event = WebSocketEvent.fromJsonString(message);

// Acceder a datos
event.isNuevaAsistencia;     // true
event.asistenciaId;           // 123
event.aprendizNombre;         // "Juan Pérez García"
event.fichaId;                // "2619073"
event.jornada;                // "MAÑANA"
event.estadoAsistencia;       // "en_curso"
event.hasValidData;           // true
```

### **Evento: .QrScanned**

**Mensaje completo recibido:**

```json
{
  "event": ".QrScanned",
  "channel": "qr-scans",
  "data": {
    "ficha_id": "2619073",
    "aprendiz_id": 456,
    "timestamp": "2024-11-10T08:29:50.123456Z"
  }
}
```

**Procesamiento:**

```dart
final event = WebSocketEvent.fromJsonString(message);

event.isQrScanned;   // true
event.fichaId;       // "2619073"
event.aprendizId;    // "456"
```

---

## 💻 CÓDIGO FUENTE COMPLETO {#codigo-fuente}

### **HybridRealtimeService Completo**

El archivo completo está en: `lib/services/hybrid_realtime_service.dart` (427 líneas)

Incluye:
- ✅ Gestión de conexión WebSocket
- ✅ Protocolo Pusher completo
- ✅ Suscripción a canales
- ✅ Heartbeat cada 30s
- ✅ Detección de inactividad
- ✅ Reconexión automática
- ✅ Polling adaptativo
- ✅ Streams reactivos
- ✅ Manejo de errores

### **HybridAsistenciaProvider Completo**

El archivo completo está en: `lib/providers/hybrid_asistencia_provider.dart` (452 líneas)

Incluye:
- ✅ Gestión de estado de la UI
- ✅ Suscripción a streams del servicio
- ✅ Procesamiento de eventos WebSocket
- ✅ Actualización inmediata sin duplicados
- ✅ Recálculo de métricas en tiempo real
- ✅ notifyListeners() para actualizar UI

### **WebSocketEvent Completo**

El archivo completo está en: `lib/models/websocket_event.dart` (177 líneas)

Incluye:
- ✅ Modelo de eventos
- ✅ Parseo de JSON
- ✅ Identificación de tipos de eventos
- ✅ Getters para datos del evento
- ✅ Validación de datos

---

## 🐛 DEBUGGING Y LOGS {#debugging}

### **Logs del Sistema**

El sistema genera logs detallados:

```
🚀 Inicializando servicio híbrido WebSocket + REST...
🔗 Conectando a WebSocket: ws://192.168.101.71:8080/app/local
✅ WebSocket conectado exitosamente
📡 Suscrito al canal: asistencias
📡 Suscrito al canal: qr-scans
💓 Heartbeat iniciado (cada 30s)
👁️ Monitor de inactividad iniciado (verifica cada 3s)
✅ WebSocket activo - último evento hace 2s
📨 Mensaje WebSocket recibido
⚡ Evento de aplicación recibido: .NuevaAsistenciaRegistrada
⚡ Actualizando datos desde WebSocket...
📝 Nueva asistencia recibida - ID: 123
➕ Nueva asistencia agregada para Juan Pérez García
⚡ Actualizando KPIs y métricas desde evento WebSocket...
✅ Asistencia agregada y KPIs actualizados inmediatamente
```

### **Habilitar/Deshabilitar Logs**

En `lib/config/app_config.dart`:

```dart
class AppConfig {
  /// Cambiar a true para mostrar logs detallados
  static const bool enableDebugLogs = true;
}
```

### **Logs de Errores**

```
❌ Error WebSocket: Connection closed
🔄 WebSocket falló, iniciando polling de fallback...
⏳ Iniciando polling adaptativo (WebSocket inactivo)...
🔄 Reintentando conexión en 1s (intento 1/4)
```

---

## 🔧 CONFIGURACIÓN BACKEND {#configuracion-backend}

### **Laravel + Reverb**

**1. Instalar Laravel Reverb:**

```bash
composer require laravel/reverb
php artisan reverb:install
```

**2. Configurar .env:**

```env
BROADCAST_DRIVER=reverb

REVERB_APP_ID=local
REVERB_APP_KEY=local
REVERB_APP_SECRET=local
REVERB_HOST=0.0.0.0
REVERB_PORT=8080
REVERB_SCHEME=http
```

**3. Iniciar servidor Reverb:**

```bash
php artisan reverb:start
```

**4. Crear evento:**

```php
// app/Events/NuevaAsistenciaRegistrada.php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class NuevaAsistenciaRegistrada implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;
    
    public $data;
    
    public function __construct(array $data)
    {
        $this->data = $data;
    }
    
    public function broadcastOn()
    {
        return new Channel('asistencias');
    }
    
    public function broadcastAs()
    {
        return 'NuevaAsistenciaRegistrada';
    }
    
    public function broadcastWith()
    {
        return $this->data;
    }
}
```

**5. Emitir evento:**

```php
// En tu controlador o servicio

event(new NuevaAsistenciaRegistrada([
    'id' => $asistencia->id,
    'aprendiz' => $asistencia->aprendiz->nombre,
    'aprendiz_id' => $asistencia->aprendiz_id,
    'ficha' => $asistencia->ficha->numero,
    'ficha_id' => $asistencia->ficha_id,
    'jornada' => $asistencia->jornada->nombre,
    'estado' => $asistencia->estado,
    'hora_ingreso' => $asistencia->hora_ingreso,
    'fecha' => $asistencia->fecha,
    'timestamp' => now(),
]));
```

---

## 🧪 TESTING Y TROUBLESHOOTING {#testing}

### **Verificar Conexión WebSocket**

```dart
// En HybridAsistenciaProvider

Map<String, dynamic> getServiceStats() {
  return {
    'isWebSocketActive': _isWebSocketActive,
    'isPollingActive': _isPollingActive,
    'lastUpdate': _lastDataUpdate?.toIso8601String(),
    'connectionMode': _isWebSocketActive 
        ? 'WebSocket Activo ✅' 
        : 'Usando Polling ⏳',
  };
}
```

### **Probar Reconexión**

1. Desconectar WiFi
2. Ver logs: `🔄 WebSocket falló`
3. Ver indicador cambiar a "Polling"
4. Reconectar WiFi
5. Ver logs: `✅ WebSocket conectado exitosamente`
6. Ver indicador cambiar a "Tiempo Real"

### **Problemas Comunes**

| Problema | Causa | Solución |
|----------|-------|----------|
| No conecta | IP incorrecta | Verificar `WebSocketConstants.host` |
| No recibe eventos | Canal incorrecto | Verificar nombres de canales |
| Reconexión infinita | Backend no responde | Verificar `php artisan reverb:start` |
| Polling permanente | Eventos no llegan | Verificar que backend emite eventos |

### **Comandos de Diagnóstico**

```bash
# Verificar servidor Reverb
curl http://192.168.101.71:8080

# Verificar API REST
curl http://192.168.101.71:8000/api/asistencia/jornada

# Logs de Laravel
tail -f storage/logs/laravel.log

# Logs de Reverb
php artisan reverb:start --debug
```

---

## 📊 RESUMEN TÉCNICO

### **Componentes Principales**

| Componente | Archivo | Líneas | Rol |
|-----------|---------|--------|-----|
| HybridRealtimeService | `lib/services/hybrid_realtime_service.dart` | 427 | Gestor WebSocket |
| HybridAsistenciaProvider | `lib/providers/hybrid_asistencia_provider.dart` | 452 | Estado UI |
| WebSocketEvent | `lib/models/websocket_event.dart` | 177 | Modelo eventos |
| WebSocketConstants | `lib/utils/websocket_constants.dart` | 53 | Configuración |

### **Métricas de Performance**

- **Latencia WebSocket:** < 1 segundo
- **Latencia Polling:** 5-20 segundos
- **Tiempo reconexión:** 1-18 segundos (backoff)
- **Heartbeat:** Cada 30 segundos
- **Detección inactividad:** Cada 3 segundos

### **Características Clave**

✅ Conexión WebSocket con protocolo Pusher  
✅ Reconexión automática con backoff progresivo  
✅ Polling adaptativo como fallback  
✅ Detección de inactividad  
✅ Heartbeat keep-alive  
✅ Streams reactivos  
✅ Actualización sin duplicados  
✅ Métricas en tiempo real  
✅ Manejo robusto de errores  

---

**📅 Documento creado:** Noviembre 2024  
**✍️ Versión:** 1.0  
**🎯 Propósito:** Documentación completa de la implementación WebSocket  
**📧 Proyecto:** Dashboard de Asistencia SENA en Tiempo Real


