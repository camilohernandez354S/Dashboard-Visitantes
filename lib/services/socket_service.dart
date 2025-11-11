import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../utils/logger.dart';

enum SocketStatus { idle, connecting, connected, reconnecting, disconnected }

/// Endpoint WebSocket configurable via `--dart-define=WS_URL=...`
const String defaultSocketUrl = String.fromEnvironment(
  'WS_URL',
  defaultValue: '',
);

/// Servicio encargado de gestionar la conexión WebSocket del dashboard.
class SocketService {
  SocketService({String? url}) : _url = (url ?? defaultSocketUrl).trim();

  final String _url;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSubscription;
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
      _channel = WebSocketChannel.connect(uri);
      AppLogger.info('Conectado al WebSocket $uri', tag: 'Socket');
      _socketSubscription = _channel!.stream.listen(
        _handleMessage,
        onDone: _handleDone,
        onError: _handleError,
        cancelOnError: false,
      );
      _statusController.add(SocketStatus.connected);
      _startPing();
    } catch (error) {
      _handleError(error);
    }
  }

  Uri _buildUri() {
    final base = Uri.parse(_url);
    if (_resumeToken == null || _resumeToken!.isEmpty) {
      return base;
    }
    final query = Map<String, String>.from(base.queryParameters);
    query['since'] = _resumeToken!;
    return base.replace(queryParameters: query);
  }

  void _handleMessage(dynamic event) {
    try {
      final dynamic decoded = event is String ? jsonDecode(event) : event;
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

  void _processStructuredMessage(Map<String, dynamic> message) {
    final type = message['type']?.toString();
    final eventId = message.remove('eventId');

    if (eventId != null) {
      _sendMessage({'type': 'ack', 'eventId': eventId});
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
      default:
        message.remove('type');
        if (message.isEmpty) {
          return;
        }
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
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _channel = null;

    if (_manuallyClosed) {
      return;
    }

    AppLogger.warn('Conexión cerrada, programando reintento', tag: 'Socket');
    _statusController.add(SocketStatus.reconnecting);
    _scheduleReconnect();
  }

  void _handleError(Object error) {
    AppLogger.error('Error en socket', tag: 'Socket', err: error);
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
