import 'dart:async';

import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../utils/logger.dart';

/// Estados de disponibilidad del socket.
enum SocketStatus { idle, connecting, connected, reconnecting, disconnected }

/// Controlador que centraliza la carga inicial y el stream en tiempo real.
class DashboardRealtimeController {
  DashboardRealtimeController({
    SocketService? socketService,
    AppConfig? config,
    Duration reconnectDelay = const Duration(seconds: 5),
  }) : _socketService = socketService ?? SocketService(),
       _config = config ?? AppConfig.fromEnvironment(),
       _reconnectDelay = reconnectDelay;

  final SocketService _socketService;
  final AppConfig _config;
  final Duration _reconnectDelay;

  final StreamController<DashboardData> _streamController =
      StreamController<DashboardData>.broadcast();
  final StreamController<SocketStatus> _statusController =
      StreamController<SocketStatus>.broadcast();

  DashboardData? _latest;
  StreamSubscription<Map<String, dynamic>>? _socketSubscription;
  Timer? _heartbeatTimer;

  Stream<DashboardData> get stream => _streamController.stream;
  Stream<SocketStatus> get socketStatus => _statusController.stream;

  DashboardData? get latest => _latest;
  AppConfig get config => _config;

  /// Obtiene la data inicial desde la API.
  Future<DashboardData> loadInitialData() async {
    AppLogger.info('Cargando datos iniciales del dashboard', tag: 'Realtime');
    final data = await ApiService.fetchDashboardData();
    _latest = data;
    _streamController.add(data);
    return data;
  }

  /// Inicia la conexión y escucha del socket.
  void startRealtime() {
    if (!_config.hasWebSocket) {
      AppLogger.warn(
        'WS_URL no configurado. Permanecerá en modo mock.',
        tag: 'Realtime',
      );
      _statusController.add(SocketStatus.idle);
      return;
    }

    _statusController.add(SocketStatus.connecting);

    _socketSubscription?.cancel();
    _socketSubscription = _socketService.connect().listen(
      _onSocketPayload,
      onError: (error) {
        AppLogger.warn(
          'Error en socket, se intentará reconectar en ${_reconnectDelay.inSeconds}s',
          tag: 'Realtime',
        );
        _statusController.add(SocketStatus.reconnecting);
        _scheduleReconnect();
      },
      onDone: () {
        _statusController.add(SocketStatus.disconnected);
        _scheduleReconnect();
      },
    );
  }

  void _onSocketPayload(Map<String, dynamic> payload) {
    final current = _latest ?? DashboardData.mock();
    final updated = current.mergeFromSocket(payload);
    _latest = updated;
    _streamController.add(updated);
    _statusController.add(SocketStatus.connected);
    AppLogger.debug('Payload recibido $payload', tag: 'Realtime');
  }

  void _scheduleReconnect() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer(_reconnectDelay, () {
      if (_statusController.isClosed) return;
      _statusController.add(SocketStatus.reconnecting);
      startRealtime();
    });
  }

  Future<DashboardData> manualRefresh() async {
    AppLogger.info('Refrescando dashboard manualmente', tag: 'Realtime');
    final data = await ApiService.fetchDashboardData();
    _latest = data;
    _streamController.add(data);
    return data;
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _socketSubscription?.cancel();
    _socketService.dispose();
    _streamController.close();
    _statusController.close();
  }
}
