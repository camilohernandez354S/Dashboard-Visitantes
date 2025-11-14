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
       _socketService =
           socketService ??
           SocketService(
             url:
                 (config ?? AppConfig.fromEnvironment()).wsDashboardUrl
                     ?.toString(),
             reverbAppKey: (config ?? AppConfig.fromEnvironment()).reverbAppKey,
             channels: const ['visitantes', 'estadisticas-visitantes'],
           ) {
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
    AppLogger.info(
      '📥 Cargando datos iniciales del dashboard desde API HTTP',
      tag: 'Realtime',
    );
    try {
      final data = await ApiService.fetchDashboardData();
      _latest = data;
      // Emitir al stream para que los listeners actualicen la UI
      _streamController.add(data);
      _updateResumeToken();
      AppLogger.info(
        '✅ Datos iniciales cargados exitosamente - '
        'Instructores: ${data.instructores}, '
        'Aprendices: ${data.aprendices}, '
        'Funcionarios: ${data.funcionarios}, '
        'Visitantes: ${data.visitantes}, '
        'Asistencias hoy: ${data.asistenciasHoy}, '
        'Personas dentro total: ${data.personasDentroData?['total'] ?? 0}',
        tag: 'Realtime',
      );

      // Verificar que los datos se emitieron correctamente
      if (data.records.isEmpty) {
        AppLogger.warn(
          '⚠️ Se cargaron datos pero no hay registros. '
          'Esto puede indicar que el endpoint no retornó registros o están vacíos.',
          tag: 'Realtime',
        );
      }

      return data;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Error al cargar datos iniciales desde API HTTP',
        tag: 'Realtime',
        err: e,
      );
      AppLogger.debug('Stack trace: $stackTrace', tag: 'Realtime');
      // Si hay error, retornar datos vacíos en lugar de lanzar excepción
      final emptyData = DashboardData.fromRecords([]);
      _latest = emptyData;
      _streamController.add(emptyData);
      AppLogger.warn(
        '⚠️ Retornando datos vacíos debido al error. '
        'El dashboard se mostrará vacío hasta que se carguen datos.',
        tag: 'Realtime',
      );
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
      // Filtrar mensajes de protocolo Pusher que no son eventos de aplicación
      final event = payload['event']?.toString();
      if (event != null &&
          (event.startsWith('pusher:') ||
              event.startsWith('pusher_internal:'))) {
        // Ignorar mensajes de protocolo Pusher (pong, ping, subscription_succeeded, etc.)
        // No loguear para evitar spam de logs
        return;
      }

      // Log solo en modo debug para eventos de aplicación
      AppLogger.debug('📥 Payload recibido: $payload', tag: 'Realtime');

      // Asegurar que siempre tengamos datos actuales
      // Si no hay datos, cargar desde la API primero
      if (_latest == null) {
        // Cargar datos de forma asíncrona pero no esperar
        loadInitialData()
            .then((loadedData) {
              // Procesar el payload nuevamente con los datos cargados
              _onSocketPayload(payload);
            })
            .catchError((e) {
              AppLogger.error(
                'Error al cargar datos iniciales: $e',
                tag: 'Realtime',
                err: e,
              );
            });
        return;
      }

      // Manejar evento estadisticas.actualizadas (tiene máxima prioridad)
      // Cuando llegan estadísticas actualizadas, recargar desde el endpoint
      if (payload['event'] == 'estadisticas.actualizadas') {
        AppLogger.info(
          '📊 Evento estadisticas.actualizadas recibido, recargando desde endpoint',
          tag: 'Realtime',
        );
        // Recargar datos desde el endpoint en lugar de usar mergeFromSocket
        loadInitialData()
            .then((updated) {
              _latest = updated;
              _streamController.add(updated);
              _statusController.add(SocketStatus.connected);
              _updateResumeToken();
            })
            .catchError((e) {
              AppLogger.error(
                'Error al recargar estadísticas desde endpoint: $e',
                tag: 'Realtime',
                err: e,
              );
            });
        return;
      }

      // Manejar evento visitante.actualizado
      // En lugar de agregar registros, recargar estadísticas desde el endpoint
      if (payload['event'] == 'visitante.actualizado') {
        final data = payload['data'] ?? payload;
        final tipo = data['tipo']?.toString().toLowerCase();

        if (tipo == 'entrada' || tipo == 'salida') {
          AppLogger.info(
            '📥 Evento visitante.actualizado ($tipo) recibido, recargando estadísticas desde endpoint',
            tag: 'Realtime',
          );

          // Recargar desde el endpoint en lugar de procesar el registro
          // Esto asegura que siempre tengamos los datos correctos del backend
          loadInitialData()
              .then((updated) {
                _latest = updated;
                _streamController.add(updated);
                _statusController.add(SocketStatus.connected);
                _updateResumeToken();
              })
              .catchError((e) {
                AppLogger.error(
                  'Error al recargar estadísticas desde endpoint: $e',
                  tag: 'Realtime',
                  err: e,
                );
              });
          return;
        }
      }

      // Si el payload contiene datos de estadísticas (roles, personas_dentro, asistencias_hoy)
      // recargar desde el endpoint para asegurar consistencia
      if (payload.containsKey('roles') ||
          payload.containsKey('personas_dentro') ||
          payload.containsKey('asistencias_hoy')) {
        AppLogger.info(
          '📊 Detectado payload con estadísticas, recargando desde endpoint',
          tag: 'Realtime',
        );
        loadInitialData()
            .then((updated) {
              _latest = updated;
              _streamController.add(updated);
              _statusController.add(SocketStatus.connected);
              _updateResumeToken();
            })
            .catchError((e) {
              AppLogger.error(
                'Error al recargar estadísticas desde endpoint: $e',
                tag: 'Realtime',
                err: e,
              );
            });
        return;
      }

      // Ignorar otros tipos de payload que no sean estadísticas
      // No procesar registros individuales, solo usar datos del endpoint
      AppLogger.debug(
        '⚠️ Payload ignorado (no es estadísticas): $payload',
        tag: 'Realtime',
      );
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
