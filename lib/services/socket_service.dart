import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../utils/logger.dart';

enum SocketStatus { idle, connecting, connected, reconnecting, disconnected }

/// Endpoint WebSocket configurable via `--dart-define=WS_URL=...`
/// Por defecto usa ws://localhost:8080 (puerto 8080)
const String defaultSocketUrl = String.fromEnvironment(
  'WS_URL',
  defaultValue: 'ws://localhost:8080',
);

/// Servicio encargado de gestionar la conexión WebSocket del dashboard.
/// Implementa el protocolo Pusher para Laravel Reverb.
class SocketService {
  SocketService({String? url, String? reverbAppKey, List<String>? channels})
    : _url = _initializeUrl(url ?? defaultSocketUrl),
      _reverbAppKey = reverbAppKey ?? 'local',
      _channels = channels ?? const ['visitantes', 'estadisticas-visitantes'];

  static String _initializeUrl(String inputUrl) {
    AppLogger.debug(
      '🔧 SocketService inicializado con URL: $inputUrl (default: $defaultSocketUrl)',
      tag: 'Socket',
    );
    final normalized = _normalizeWebSocketUrl(inputUrl);
    AppLogger.info(
      '✅ SocketService URL final normalizada: $normalized',
      tag: 'Socket',
    );
    return normalized;
  }

  /// Normaliza la URL de WebSocket, convirtiendo http:// a ws:// y https:// a wss://
  static String _normalizeWebSocketUrl(String url) {
    if (url.isEmpty) {
      return 'ws://localhost:8080';
    }

    String normalized = url.trim();

    // Convertir http:// a ws:// automáticamente si es necesario
    if (normalized.startsWith('http://')) {
      normalized = normalized.replaceFirst('http://', 'ws://');
      AppLogger.info(
        '🔄 URL convertida de http:// a ws://: $normalized',
        tag: 'Socket',
      );
    } else if (normalized.startsWith('https://')) {
      normalized = normalized.replaceFirst('https://', 'wss://');
      AppLogger.info(
        '🔄 URL convertida de https:// a wss://: $normalized',
        tag: 'Socket',
      );
    } else if (!normalized.startsWith('ws://') &&
        !normalized.startsWith('wss://')) {
      // Si no tiene scheme, agregar ws://
      if (!normalized.contains('://')) {
        normalized = 'ws://$normalized';
        AppLogger.info(
          '🔄 URL sin scheme, agregando ws://: $normalized',
          tag: 'Socket',
        );
      }
    }

    AppLogger.debug(
      '✅ URL normalizada: $normalized (original: $url)',
      tag: 'Socket',
    );

    return normalized;
  }

  final String _url;
  final String _reverbAppKey;
  final List<String> _channels;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSubscription;
  bool _isSubscribed = false;
  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _manuallyClosed = false;
  String? _resumeToken;

  static const Duration _pingInterval = Duration(seconds: 30);

  /// Stream con los datos decodificados provenientes del WebSocket.
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  bool get isConnected => _channel != null;

  final StreamController<SocketStatus> _statusController =
      StreamController<SocketStatus>.broadcast();

  Stream<SocketStatus> get statusStream => _statusController.stream;

  /// Inicia la conexión WebSocket si hay URL disponible y retorna el stream.
  Stream<Map<String, dynamic>> connect({String? resumeToken}) {
    if (_url.isEmpty) {
      AppLogger.warn(
        'WS_URL no configurado. Se omitirá la conexión WebSocket.',
        tag: 'Socket',
      );
      _statusController.add(SocketStatus.idle);
      return _controller.stream;
    }

    _manuallyClosed = false;
    if (resumeToken != null && resumeToken.isNotEmpty) {
      _resumeToken = resumeToken;
    }
    _openConnection();
    return _controller.stream;
  }

  void updateResumeToken(String? token) {
    if (token == null || token.isEmpty) {
      return;
    }
    _resumeToken = token;
  }

  void _openConnection() {
    _cancelTimers();
    _closeSocket();

    try {
      _statusController.add(SocketStatus.connecting);
      final uri = _buildUri();
      AppLogger.info(
        '🔌 Intentando conectar al WebSocket: $uri',
        tag: 'Socket',
      );

      _channel = WebSocketChannel.connect(uri);
      AppLogger.info('✅ Canal WebSocket creado', tag: 'Socket');

      _socketSubscription = _channel!.stream.listen(
        _handleMessage,
        onDone: _handleDone,
        onError: _handleError,
        cancelOnError: false,
      );

      // Resetear flag de suscripción al reconectar
      _isSubscribed = false;

      // Solo intentar suscribirse si la URL tiene el path /app/ (Laravel Reverb)
      // Para servidores simples (Node.js), no es necesario suscribirse
      if (uri.path.startsWith('/app/')) {
        // Es Laravel Reverb, esperar confirmación de conexión o timeout
        AppLogger.info(
          '✅ WebSocket conectado, esperando confirmación de Pusher...',
          tag: 'Socket',
        );
        _statusController.add(SocketStatus.connected);

        // Intentar suscribirse después de un breve delay si no se recibe connection_established
        Timer(const Duration(milliseconds: 1000), () {
          if (_channel != null && !_isSubscribed) {
            AppLogger.info(
              '⏱️ No se recibió pusher:connection_established, intentando suscribirse de todas formas...',
              tag: 'Socket',
            );
            _subscribeToChannels();
          }
        });
      } else {
        // Servidor simple (Node.js), no necesita suscripción
        AppLogger.info(
          '✅ Servidor WebSocket simple detectado, no requiere suscripción a canales',
          tag: 'Socket',
        );
        _isSubscribed = true; // Marcar como "suscrito" para evitar reintentos
        _statusController.add(SocketStatus.connected);
      }

      _startPing();
    } catch (error) {
      AppLogger.error(
        '❌ Error al conectar WebSocket: $error',
        tag: 'Socket',
        err: error,
      );
      _handleError(error);
    }
  }

  Uri _buildUri() {
    // Asegurarse de que _url esté normalizada (por si acaso)
    final normalizedUrl = _normalizeWebSocketUrl(_url);
    if (normalizedUrl != _url) {
      AppLogger.warn(
        '⚠️ URL no estaba normalizada. Normalizando: $_url → $normalizedUrl',
        tag: 'Socket',
      );
    }

    AppLogger.debug('🔗 Construyendo URI desde: $normalizedUrl', tag: 'Socket');

    final base = Uri.parse(normalizedUrl);

    // Verificar que el scheme sea ws:// o wss://
    if (base.scheme != 'ws' && base.scheme != 'wss') {
      AppLogger.error(
        '❌ Scheme inválido para WebSocket: ${base.scheme}. Debe ser ws:// o wss://',
        tag: 'Socket',
      );
      throw ArgumentError(
        'URL de WebSocket debe usar scheme ws:// o wss://, recibido: ${base.scheme}://',
      );
    }

    // Si la URL ya tiene un path (como /app/local), usarla tal cual
    // Esto permite soportar tanto Laravel Reverb como servidores WebSocket simples
    if (base.path.isNotEmpty && base.path != '/') {
      AppLogger.info(
        '🔗 URL ya tiene path: ${base.path}, usando tal cual',
        tag: 'Socket',
      );
      return base;
    }

    // Si no tiene path y tenemos una clave de aplicación, agregar path de Reverb
    // Laravel Reverb siempre requiere el path /app/{appKey}, incluso si es 'local'
    // Solo omitir el path si explícitamente se indica que es un servidor simple
    if (_reverbAppKey.isNotEmpty && base.path.isEmpty) {
      final path = '/app/$_reverbAppKey';
      // Agregar query parameters requeridos por el protocolo Pusher
      final queryParameters = {
        'protocol': '7',
        'client': 'js',
        'version': '1.0',
        ...base.queryParameters, // Preservar query params existentes si los hay
      };
      final finalUri = base.replace(
        path: path,
        queryParameters: queryParameters,
      );
      AppLogger.info(
        '🔗 Agregando path de Reverb: $path (clave: $_reverbAppKey)',
        tag: 'Socket',
      );
      AppLogger.info('🔗 URI WebSocket construida: $finalUri', tag: 'Socket');
      return finalUri;
    }

    // Si ya tiene path o no hay clave de app, usar la URL tal cual
    AppLogger.info('🔗 Usando URI sin modificar: $base', tag: 'Socket');
    return base;
  }

  void _handleMessage(dynamic event) {
    try {
      final dynamic decoded = event is String ? jsonDecode(event) : event;

      // Log del mensaje raw recibido para debugging (solo en debug mode)
      AppLogger.debug('📨 Mensaje WebSocket recibido: $decoded', tag: 'Socket');

      if (decoded is Map) {
        final mappedEntry = decoded.map<String, dynamic>(
          (key, value) => MapEntry(key.toString(), value),
        );
        _processStructuredMessage(mappedEntry);
      } else {
        AppLogger.warn('Mensaje no compatible: $decoded', tag: 'Socket');
      }
    } catch (error) {
      AppLogger.error(
        'Error al decodificar mensaje',
        tag: 'Socket',
        err: error,
      );
    }
  }

  /// Suscribe a los canales usando el protocolo Pusher
  void _subscribeToChannels() {
    if (_channel == null) {
      AppLogger.warn(
        '⚠️ No hay canal WebSocket disponible para suscribirse',
        tag: 'Socket',
      );
      return;
    }

    AppLogger.info(
      '📡 Suscribiéndose a canales: ${_channels.join(", ")}',
      tag: 'Socket',
    );

    for (final channel in _channels) {
      // Laravel Reverb usa el formato estándar de Pusher
      final subscribeMessage = {
        'event': 'pusher:subscribe',
        'data': {'channel': channel},
      };
      _sendMessage(subscribeMessage);
      AppLogger.info(
        '📤 Enviado pusher:subscribe para canal: $channel',
        tag: 'Socket',
      );
    }

    // No marcar como suscrito todavía, esperar confirmación
    AppLogger.info(
      '⏳ Esperando confirmación de suscripción a canales...',
      tag: 'Socket',
    );
  }

  void _processStructuredMessage(Map<String, dynamic> message) {
    final type = message['type']?.toString();
    final event = message['event']?.toString();
    final channel = message['channel']?.toString();
    final eventId = message.remove('eventId');

    // Log detallado del mensaje para debugging
    AppLogger.debug(
      '🔍 Procesando mensaje - type: $type, event: $event, channel: $channel',
      tag: 'Socket',
    );
    AppLogger.debug('📋 Contenido completo: $message', tag: 'Socket');

    // Manejar eventos del protocolo Pusher
    // Pusher puede enviar connection_established como evento o como tipo
    if (event == 'pusher:connection_established' ||
        type == 'pusher:connection_established' ||
        (message.containsKey('data') &&
            message['data'] is Map &&
            (message['data'] as Map).containsKey('socket_id'))) {
      AppLogger.info(
        '✅ Conexión Pusher establecida: ${message['data']}',
        tag: 'Socket',
      );
      // Una vez que la conexión está establecida, suscribirse a los canales
      _subscribeToChannels();
      return;
    }

    if (event == 'pusher_internal:subscription_succeeded' ||
        event == 'pusher:subscription_succeeded' ||
        type == 'pusher_internal:subscription_succeeded') {
      final channelName = message['channel']?.toString() ?? 'desconocido';
      AppLogger.info(
        '✅ Suscripción exitosa al canal: $channelName',
        tag: 'Socket',
      );
      // Marcar como suscrito solo si todos los canales están suscritos
      // Por ahora, marcamos como suscrito cuando recibamos al menos una confirmación
      _isSubscribed = true;
      _statusController.add(SocketStatus.connected);
      return;
    }

    if (event == 'pusher:error') {
      final errorData = message['data'];
      final errorCode = errorData is Map ? errorData['code'] : null;
      final errorMessage = errorData is Map
          ? errorData['message']
          : errorData?.toString() ?? 'Error desconocido';

      AppLogger.error(
        '❌ Error de Pusher: $errorMessage (Código: $errorCode)',
        tag: 'Socket',
      );

      // Manejar error de formato de mensaje inválido
      if (errorCode == 4200 ||
          errorMessage.toString().contains('Invalid message format')) {
        AppLogger.warn(
          '⚠️ Formato de mensaje inválido detectado. Esto puede ser por mensajes ping/pong incorrectos.',
          tag: 'Socket',
        );
        // No cerrar la conexión, solo loguear el warning
        return;
      }

      // Manejar error específico de aplicación no existente
      if (errorCode == 4001 ||
          errorMessage.toString().contains('Application does not exist')) {
        _lastErrorWasAppNotFound = true;
        AppLogger.error(
          '❌ La aplicación con clave "$_reverbAppKey" no existe en el servidor Reverb',
          tag: 'Socket',
        );
        AppLogger.error(
          '🔴 ERROR DE CONFIGURACIÓN: El servidor Reverb no reconoce la aplicación.\n'
          '   Esto indica un problema de configuración en el backend Laravel.\n\n'
          '📋 PASOS PARA SOLUCIONAR:\n'
          '   1. Abre el archivo .env de tu backend Laravel\n'
          '   2. Asegúrate de que estas variables estén definidas (NO como "..."):\n'
          '      REVERB_APP_ID=$_reverbAppKey\n'
          '      REVERB_APP_KEY=$_reverbAppKey\n'
          '      REVERB_APP_SECRET=$_reverbAppKey\n'
          '      REVERB_HOST=0.0.0.0\n'
          '      REVERB_SERVER_PORT=8080\n'
          '      BROADCAST_DRIVER=reverb\n\n'
          '   3. Si usas Docker, verifica que el puerto 8080 esté mapeado\n'
          '   4. Detén el servidor Reverb actual (Ctrl+C)\n'
          '   5. Reinicia el servidor: php artisan reverb:start\n'
          '   6. Verifica que no haya errores al iniciar\n\n'
          '   Si la clave es diferente a "local", configura Flutter con:\n'
          '   --dart-define=REVERB_APP_KEY=tu_clave_real',
          tag: 'Socket',
        );
        // Cerrar la conexión y NO reintentar hasta que se corrija la configuración
        _closeSocket();
        _statusController.add(SocketStatus.disconnected);
        // Aumentar significativamente el delay antes de reintentar
        // para evitar spam de logs cuando hay un error de configuración
        _scheduleReconnectWithDelay(const Duration(seconds: 30));
        return;
      }

      return;
    }

    if (eventId != null) {
      _sendMessage({'type': 'ack', 'eventId': eventId});
    }

    // Manejar eventos de los canales visitantes y estadisticas-visitantes
    // También manejar eventos sin canal específico si tienen el evento correcto
    // Laravel Reverb puede enviar eventos con diferentes formatos
    if (channel == 'visitantes' ||
        channel == 'estadisticas-visitantes' ||
        channel == 'entrada-salida' ||
        event == 'visitante.actualizado' ||
        event == 'estadisticas.actualizadas' ||
        event == 'AsistenciaRegistrada' ||
        event == 'asistencia.registrada' ||
        event == 'EntradaSalidaRegistrada' ||
        event == 'entrada-salida.registrada') {
      if (event == 'visitante.actualizado' ||
          event == 'AsistenciaRegistrada' ||
          event == 'asistencia.registrada' ||
          event == 'EntradaSalidaRegistrada' ||
          event == 'entrada-salida.registrada') {
        // Extraer datos del evento - puede venir en diferentes formatos
        dynamic data = message['data'];
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (e) {
            AppLogger.warn(
              '⚠️ No se pudo parsear data como JSON: $e',
              tag: 'Socket',
            );
            data = message;
          }
        } else if (data == null) {
          data = message;
        }

        // Formatear y mostrar información destacada del evento
        final tipo = data['tipo']?.toString() ?? 'desconocido';
        final visitante = data['visitante'] is Map
            ? Map<String, dynamic>.from(data['visitante'] as Map)
            : null;
        final visitanteId = visitante?['id']?.toString() ?? 'N/A';
        final visitanteNombre = visitante?['nombre']?.toString() ?? 'N/A';
        final visitanteDocumento = visitante?['documento']?.toString() ?? 'N/A';
        final visitanteRol = visitante?['rol']?.toString() ?? 'N/A';
        final horaEntrada = visitante?['hora_entrada']?.toString();
        final horaSalida = visitante?['hora_salida']?.toString();
        final hora = horaEntrada ?? horaSalida ?? 'N/A';
        final timestamp = data['timestamp']?.toString() ?? 'N/A';

        // Log destacado con la información solicitada
        AppLogger.info(
          '\n'
          '═══════════════════════════════════════════════════════════\n'
          '📥 EVENTO DE VISITANTE RECIBIDO\n'
          '═══════════════════════════════════════════════════════════\n'
          'Tipo: $tipo\n'
          'ID: $visitanteId\n'
          'Nombre: $visitanteNombre\n'
          'Documento: $visitanteDocumento\n'
          'Rol: $visitanteRol\n'
          'Hora: $hora\n'
          'Timestamp: $timestamp\n'
          '═══════════════════════════════════════════════════════════\n'
          'JSON Completo:\n'
          '═══════════════════════════════════════════════════════════',
          tag: 'Socket',
        );
        AppLogger.info('📋 ${jsonEncode(data)}', tag: 'Socket');

        // El evento contiene información de entrada/salida
        _controller.add({'event': 'visitante.actualizado', 'data': data});
        return;
      } else if (event == 'estadisticas.actualizadas') {
        dynamic data = message['data'];
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (e) {
            AppLogger.warn(
              '⚠️ No se pudo parsear data como JSON: $e',
              tag: 'Socket',
            );
            data = message;
          }
        } else if (data == null) {
          data = message;
        }

        AppLogger.info(
          '✅ Evento estadisticas.actualizadas recibido - Data: $data',
          tag: 'Socket',
        );
        // El evento contiene estadísticas actualizadas
        _controller.add({'event': 'estadisticas.actualizadas', 'data': data});
        return;
      }
    }

    switch (type) {
      case 'heartbeat':
        AppLogger.debug('Heartbeat recibido', tag: 'Socket');
        // Pusher usa el formato de evento para pong
        _sendMessage({'event': 'pusher:pong', 'data': {}});
        return;
      case 'pong':
        return;
      case 'snapshot':
        final payload = message['payload'];
        if (payload is Map<String, dynamic>) {
          _controller.add(Map<String, dynamic>.from(payload));
        } else if (payload is List) {
          _controller.add({'records': payload});
        }
        return;
      case 'ack':
        return;
      case 'error':
        AppLogger.error(
          'Socket error payload: ${message['message']}',
          tag: 'Socket',
        );
        return;
      case 'event':
        final payload = message['payload'];
        if (payload is Map<String, dynamic>) {
          _controller.add(Map<String, dynamic>.from(payload));
        }
        return;
      case 'nuevo_registro':
        // Manejar mensaje del servidor Node.js (compatibilidad)
        final registro = message['registro'];
        if (registro is Map<String, dynamic>) {
          AppLogger.info(
            'Nuevo registro recibido: ${registro['nombre']} (${registro['rol']})',
            tag: 'Socket',
          );
          _controller.add({'record': registro});
        }
        return;
      case 'connection':
        AppLogger.debug('Mensaje de conexión recibido', tag: 'Socket');
        return;
      default:
        // Si el mensaje tiene un campo 'event' pero no se procesó arriba, intentar procesarlo
        if (event != null) {
          AppLogger.info(
            '📤 Enviando mensaje con event: $event al controlador',
            tag: 'Socket',
          );
          _controller.add(message);
          return;
        }

        // Si no tiene type pero tiene datos útiles, enviarlo de todas formas
        if (message.containsKey('data') ||
            message.containsKey('registro') ||
            message.containsKey('records') ||
            message.containsKey('instructores') ||
            message.containsKey('aprendices') ||
            message.containsKey('funcionarios') ||
            message.containsKey('visitantes')) {
          AppLogger.info(
            '📤 Enviando mensaje con datos útiles al controlador: $message',
            tag: 'Socket',
          );
          _controller.add(message);
          return;
        }

        message.remove('type');
        if (message.isEmpty) {
          AppLogger.debug(
            '⚠️ Mensaje vacío después de remover type',
            tag: 'Socket',
          );
          return;
        }
        AppLogger.info(
          '📤 Enviando mensaje genérico al controlador: $message',
          tag: 'Socket',
        );
        _controller.add(message);
    }
  }

  void _sendMessage(Map<String, dynamic> message) {
    final channel = _channel;
    if (channel == null) {
      return;
    }
    try {
      channel.sink.add(jsonEncode(message));
    } catch (error) {
      AppLogger.error(
        'No se pudo enviar mensaje WS',
        tag: 'Socket',
        err: error,
      );
    }
  }

  void _handleDone() {
    AppLogger.warn(
      '🔌 Conexión WebSocket cerrada por el servidor',
      tag: 'Socket',
    );
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _channel = null;

    if (_manuallyClosed) {
      AppLogger.debug(
        'Conexión cerrada manualmente, no se reintentará',
        tag: 'Socket',
      );
      return;
    }

    AppLogger.warn(
      '⚠️ Conexión cerrada inesperadamente, programando reintento en 5s',
      tag: 'Socket',
    );
    _statusController.add(SocketStatus.reconnecting);
    _scheduleReconnect();
  }

  void _handleError(Object error) {
    AppLogger.error('❌ Error en socket: $error', tag: 'Socket', err: error);

    // Obtener la URI que se intentó usar
    Uri? attemptedUri;
    try {
      attemptedUri = _buildUri();
    } catch (e) {
      AppLogger.error('❌ Error al construir URI: $e', tag: 'Socket', err: e);
    }

    AppLogger.error(
      '📋 Detalles del error:\n'
      '   - Tipo: ${error.runtimeType}\n'
      '   - URL base: $_url\n'
      '   - URI intentada: ${attemptedUri ?? "N/A"}\n'
      '   - REVERB_APP_KEY: $_reverbAppKey',
      tag: 'Socket',
    );

    // Si el error es de conexión, puede ser que el puerto esté mal
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('connection refused') ||
        errorStr.contains('failed to connect') ||
        errorStr.contains('network is unreachable') ||
        errorStr.contains('connection closed') ||
        errorStr.contains('websocket')) {
      AppLogger.warn(
        '⚠️ Error de conexión detectado. Verifica que el servidor WebSocket esté corriendo.',
        tag: 'Socket',
      );

      // Determinar qué tipo de servidor se espera según la URL
      if (attemptedUri != null) {
        final isReverbServer =
            attemptedUri.path.startsWith('/app/') || _reverbAppKey.isNotEmpty;

        if (isReverbServer) {
          final port = attemptedUri.port;
          AppLogger.info(
            '💡 Laravel Reverb detectado. Verifica:\n'
            '   1. Que Reverb esté corriendo: php artisan reverb:start\n'
            '   2. Que REVERB_SERVER_PORT=$port en tu .env (o el puerto que uses)\n'
            '   3. Que REVERB_APP_KEY=$_reverbAppKey coincida con tu .env\n'
            '   4. Que la URL sea accesible: $attemptedUri\n'
            '   5. Si usas Docker, asegúrate de mapear el puerto $port correctamente\n'
            '   6. Verifica que Reverb esté escuchando en el puerto correcto',
            tag: 'Socket',
          );
        } else {
          AppLogger.info(
            '💡 Servidor WebSocket simple detectado. Verifica:\n'
            '   1. Que el servidor esté corriendo\n'
            '   2. Que esté escuchando en: $attemptedUri\n'
            '   3. Que el puerto esté correctamente configurado',
            tag: 'Socket',
          );
        }
      } else {
        AppLogger.info(
          '💡 No se pudo construir la URI. Verifica la configuración de WS_URL.',
          tag: 'Socket',
        );
      }
    }

    _closeSocket();
    if (_manuallyClosed) {
      return;
    }
    _statusController.add(SocketStatus.reconnecting);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null && _reconnectTimer!.isActive) {
      return;
    }

    // Si hay un error de aplicación no existente, aumentar el delay para evitar spam
    final delay = _lastErrorWasAppNotFound
        ? const Duration(seconds: 15)
        : const Duration(seconds: 5);

    _scheduleReconnectWithDelay(delay);
  }

  void _scheduleReconnectWithDelay(Duration delay) {
    if (_reconnectTimer != null && _reconnectTimer!.isActive) {
      return;
    }

    _reconnectTimer = Timer(delay, () {
      if (_manuallyClosed) return;
      _lastErrorWasAppNotFound = false; // Resetear flag
      AppLogger.info('Intentando reconectar...', tag: 'Socket');
      _openConnection();
    });
  }

  bool _lastErrorWasAppNotFound = false;

  void _cancelTimers() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _closeSocket() {
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      // Pusher usa el formato de evento para ping
      _sendMessage({'event': 'pusher:ping', 'data': {}});
    });
  }

  /// Cierra la conexión y libera recursos.
  void dispose() {
    _manuallyClosed = true;
    _cancelTimers();
    _closeSocket();
    _controller.close();
    _statusController.add(SocketStatus.idle);
    _statusController.close();
  }
}
