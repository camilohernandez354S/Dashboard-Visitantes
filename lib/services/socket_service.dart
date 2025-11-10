import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../utils/logger.dart';

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
  bool _manuallyClosed = false;

  /// Stream con los datos decodificados provenientes del WebSocket.
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  bool get isConnected => _channel != null;

  /// Inicia la conexión WebSocket si hay URL disponible y retorna el stream.
  Stream<Map<String, dynamic>> connect() {
    if (_url.isEmpty) {
      AppLogger.warn(
        'WS_URL no configurado. Se omitirá la conexión WebSocket.',
        tag: 'Socket',
      );
      return _controller.stream;
    }

    _manuallyClosed = false;
    _openConnection();
    return _controller.stream;
  }

  void _openConnection() {
    _cancelTimers();
    _closeSocket();

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_url));
      AppLogger.info('Conectado al WebSocket $_url', tag: 'Socket');

      _socketSubscription = _channel!.stream.listen(
        _handleMessage,
        onDone: _handleDone,
        onError: _handleError,
        cancelOnError: false,
      );
    } catch (error) {
      _handleError(error);
    }
  }

  void _handleMessage(dynamic event) {
    try {
      final dynamic decoded = event is String ? jsonDecode(event) : event;
      if (decoded is Map) {
        final mappedEntry = decoded.map<String, dynamic>((key, value) {
          if (value is num) {
            return MapEntry(key.toString(), value);
          }
          return MapEntry(key.toString(), value);
        });
        AppLogger.debug('Datos recibidos: $mappedEntry', tag: 'Socket');
        _controller.add(mappedEntry);
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

  void _handleDone() {
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _channel = null;

    if (_manuallyClosed) {
      return;
    }

    AppLogger.warn('Conexión cerrada, programando reintento', tag: 'Socket');
    _scheduleReconnect();
  }

  void _handleError(Object error) {
    AppLogger.error('Error en socket', tag: 'Socket', err: error);
    _closeSocket();
    if (_manuallyClosed) {
      return;
    }
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
  }

  void _closeSocket() {
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  /// Cierra la conexión y libera recursos.
  void dispose() {
    _manuallyClosed = true;
    _cancelTimers();
    _closeSocket();
    _controller.close();
  }
}
