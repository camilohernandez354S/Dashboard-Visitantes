import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../utils/logger.dart';

enum SocketStatus { idle, connecting, connected, reconnecting, disconnected }

/// Endpoint WebSocket configurable via `--dart-define=WS_URL=...`
/// Por defecto usa ws://localhost (mismo servidor que HTTP pero con protocolo ws://)
const String defaultSocketUrl = String.fromEnvironment(
  'WS_URL',
  defaultValue: 'ws://localhost:80',
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
      return 'ws://localhost';
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

      _statusController.add(SocketStatus.connected);
      _startPing();
      AppLogger.info(
        '✅ WebSocket conectado, esperando confirmación de Pusher...',
        tag: 'Socket',
      );
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

    // Laravel Reverb usa el formato: ws://host:port/app/{REVERB_APP_KEY}
    // Construir la URL completa con el path /app/{key}
    Uri finalUri = base;
    final path = '/app/$_reverbAppKey';

    // Si la URL base no tiene el path correcto, agregarlo
    if (base.path.isEmpty ||
        base.path == '/' ||
        !base.path.startsWith('/app/')) {
      finalUri = base.replace(path: path);
      AppLogger.debug('🔗 Agregando path de Reverb: $path', tag: 'Socket');
    }

    final result = finalUri;
    AppLogger.info(
      '🔗 URI WebSocket construida: $result (URL base normalizada: $normalizedUrl)',
      tag: 'Socket',
    );
    return result;
  }

  void _handleMessage(dynamic event) {
    try {
      final dynamic decoded = event is String ? jsonDecode(event) : event;

      // Log del mensaje raw recibido para debugging
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
    if (_channel == null || _isSubscribed) {
      return;
    }

    AppLogger.info(
      '📡 Suscribiéndose a canales: ${_channels.join(", ")}',
      tag: 'Socket',
    );

    for (final channel in _channels) {
      final subscribeMessage = {
        'event': 'pusher:subscribe',
        'data': {'channel': channel},
      };
      _sendMessage(subscribeMessage);
      AppLogger.debug(
        '📤 Enviado pusher:subscribe para canal: $channel',
        tag: 'Socket',
      );
    }
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
    if (event == 'pusher:connection_established') {
      AppLogger.info(
        '✅ Conexión Pusher establecida: ${message['data']}',
        tag: 'Socket',
      );
      // Una vez que la conexión está establecida, suscribirse a los canales
      _subscribeToChannels();
      return;
    }

    if (event == 'pusher_internal:subscription_succeeded') {
      final channelName = message['channel']?.toString() ?? 'desconocido';
      AppLogger.info(
        '✅ Suscripción exitosa al canal: $channelName',
        tag: 'Socket',
      );
      _isSubscribed = true;
      return;
    }

    if (event == 'pusher:error') {
      AppLogger.error('❌ Error de Pusher: ${message['data']}', tag: 'Socket');
      return;
    }

    if (eventId != null) {
      _sendMessage({'type': 'ack', 'eventId': eventId});
    }

    // Manejar eventos de los canales visitantes y estadisticas-visitantes
    // También manejar eventos sin canal específico si tienen el evento correcto
    if (channel == 'visitantes' ||
        channel == 'estadisticas-visitantes' ||
        event == 'visitante.actualizado' ||
        event == 'estadisticas.actualizadas') {
      if (event == 'visitante.actualizado') {
        final data = message['data'] ?? message;
        AppLogger.info(
          '✅ Evento visitante.actualizado recibido - Data: $data',
          tag: 'Socket',
        );
        // El evento contiene información de entrada/salida
        _controller.add({'event': 'visitante.actualizado', 'data': data});
        return;
      } else if (event == 'estadisticas.actualizadas') {
        final data = message['data'] ?? message;
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
        _sendMessage({'type': 'pong'});
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
    AppLogger.error(
      '📋 Detalles del error - Tipo: ${error.runtimeType}, URL: $_url',
      tag: 'Socket',
    );
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

    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_manuallyClosed) return;
      AppLogger.info('Intentando reconectar...', tag: 'Socket');
      _openConnection();
    });
  }

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
      _sendMessage({'type': 'ping'});
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
