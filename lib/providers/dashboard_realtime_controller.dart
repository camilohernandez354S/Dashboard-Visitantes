import 'dart:async';

import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../utils/logger.dart';

/// Controlador que centraliza la carga inicial y el stream en tiempo real.
class DashboardRealtimeController {
  DashboardRealtimeController({
    SocketService? socketService,
    AppConfig? config,
    Duration reconnectDelay = const Duration(seconds: 5),
  }) : _config = config ?? AppConfig.fromEnvironment(),
       _reconnectDelay = reconnectDelay,
       _socketService = socketService ?? 
           SocketService(url: (config ?? AppConfig.fromEnvironment()).wsDashboardUrl?.toString()) {
    _statusSubscription = _socketService.statusStream.listen((status) {
      if (!_statusController.isClosed) {
        AppLogger.info('Estado socket → $status', tag: 'Realtime');
        _statusController.add(status);
      }
    });
    _statusController.add(SocketStatus.idle);
  }

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
  StreamSubscription<SocketStatus>? _statusSubscription;
  String? _resumeToken;

  Stream<DashboardData> get stream => _streamController.stream;
  Stream<SocketStatus> get socketStatus => _statusController.stream;

  DashboardData? get latest => _latest;
  AppConfig get config => _config;

  /// Obtiene la data inicial desde la API.
  Future<DashboardData> loadInitialData() async {
    AppLogger.info('Cargando datos iniciales del dashboard', tag: 'Realtime');
    try {
      final data = await ApiService.fetchDashboardData();
      _latest = data;
      // Emitir al stream para que los listeners actualicen la UI
      _streamController.add(data);
      _updateResumeToken();
      AppLogger.info(
        '✅ Datos iniciales cargados - Total registros: ${data.records.length}',
        tag: 'Realtime',
      );
      return data;
    } catch (e) {
      AppLogger.error(
        'Error al cargar datos iniciales',
        tag: 'Realtime',
        err: e,
      );
      // Si hay error, retornar datos vacíos en lugar de lanzar excepción
      final emptyData = DashboardData.fromRecords([]);
      _latest = emptyData;
      _streamController.add(emptyData);
      return emptyData;
    }
  }

  /// Inicia la conexión y escucha del socket.
  void startRealtime() {
    if (!_config.hasWebSocket) {
      AppLogger.warn(
        'WS_URL no configurado. WebSocket deshabilitado.',
        tag: 'Realtime',
      );
      _statusController.add(SocketStatus.idle);
      return;
    }

    _statusController.add(SocketStatus.connecting);

    _socketSubscription?.cancel();
    _socketSubscription = _socketService
        .connect(resumeToken: _resumeToken)
        .listen(
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
    try {
      final current = _latest;
      
      // Si hay un registro nuevo del servidor Node.js
      if (payload.containsKey('record')) {
        final registroJson = payload['record'];
        if (registroJson is Map<String, dynamic>) {
          // Convertir el registro del servidor a AttendanceRecord
          final record = AttendanceRecord.fromServerJson(registroJson);
          
          // Si no hay datos actuales, cargar desde la API primero
          if (current == null) {
            loadInitialData().then((data) {
              final updated = data.applyRecord(record);
              _latest = updated;
              _streamController.add(updated);
              _statusController.add(SocketStatus.connected);
              _updateResumeToken();
              AppLogger.info(
                'Registro agregado: ${record.name} (${record.role.label})',
                tag: 'Realtime',
              );
            });
            return;
          }
          
          // Agregar el nuevo registro a los datos actuales
          AppLogger.info(
            '📥 Nuevo registro recibido por WebSocket: ${record.name} (${record.role.label})',
            tag: 'Realtime',
          );
          
          final updated = current.applyRecord(record);
          _latest = updated;
          
          AppLogger.info(
            '📊 Datos actualizados - Instructores: ${updated.instructores}, '
            'Aprendices: ${updated.aprendices}, Funcionarios: ${updated.funcionarios}, '
            'Visitantes: ${updated.visitantes}',
            tag: 'Realtime',
          );
          
          // Emitir al stream para que la UI se actualice
          _streamController.add(updated);
          _statusController.add(SocketStatus.connected);
          _updateResumeToken();
          
          AppLogger.info(
            '✅ Registro agregado y emitido al stream - Total registros: ${updated.records.length}',
            tag: 'Realtime',
          );
          return;
        }
      }
      
      // Para otros tipos de payload, usar el método mergeFromSocket existente
      final baseData = current ?? DashboardData.fromRecords([]);
      final updated = baseData.mergeFromSocket(payload);
      _latest = updated;
      _streamController.add(updated);
      _statusController.add(SocketStatus.connected);
      _updateResumeToken();
      AppLogger.debug('Payload recibido $payload', tag: 'Realtime');
    } catch (e, s) {
      AppLogger.error(
        'Error al procesar payload del socket',
        tag: 'Realtime',
        err: e,
      );
      AppLogger.debug('Stack trace: $s', tag: 'Realtime');
    }
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
    _updateResumeToken();
    return data;
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _socketSubscription?.cancel();
    _statusSubscription?.cancel();
    _socketService.dispose();
    _streamController.close();
    _statusController.close();
  }

  void _updateResumeToken() {
    final token = _latest?.resumeToken;
    if (token == null || token.isEmpty || token == _resumeToken) {
      return;
    }
    _resumeToken = token;
    _socketService.updateResumeToken(token);
  }
}
