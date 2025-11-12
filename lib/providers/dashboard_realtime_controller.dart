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
             reverbAppKey:
                 (config ?? AppConfig.fromEnvironment()).reverbAppKey,
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
        'Total registros: ${data.records.length}',
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
      // Log detallado del payload recibido
      AppLogger.info(
        '📥 Payload recibido en controlador: $payload',
        tag: 'Realtime',
      );

      // Asegurar que siempre tengamos datos actuales
      // Si no hay datos, cargar desde la API primero
      if (_latest == null || _latest!.records.isEmpty) {
        AppLogger.info(
          '⚠️ No hay datos iniciales o están vacíos, cargando desde API...',
          tag: 'Realtime',
        );
        // Cargar datos de forma asíncrona pero no esperar
        loadInitialData()
            .then((loadedData) {
              AppLogger.info(
                '✅ Datos iniciales cargados: ${loadedData.records.length} registros',
                tag: 'Realtime',
              );
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

      final current = _latest!;

      // Manejar evento visitante.actualizado
      if (payload['event'] == 'visitante.actualizado') {
        final data = payload['data'] ?? payload;
        final tipo = data['tipo']?.toString().toLowerCase();
        final registroJson = data;

        if (tipo == 'entrada' || tipo == 'salida') {
          // Convertir el registro a AttendanceRecord
          AttendanceRecord record;
          try {
            record = AttendanceRecord.fromServerJson(registroJson);
          } catch (e) {
            AppLogger.warn(
              'Error al parsear registro del evento visitante.actualizado: $e',
              tag: 'Realtime',
            );
            return;
          }

          AppLogger.info(
            '📥 Evento visitante.actualizado: ${record.name} (${record.role.label}) - Tipo: $tipo',
            tag: 'Realtime',
          );

          // Verificar si el registro ya existe para evitar duplicados
          // Comparar por nombre, rol y timestamp (dentro de un rango de 1 minuto)
          final recordExists = current.records.any((existing) {
            return existing.name == record.name &&
                existing.role == record.role &&
                (existing.recordedAt
                        .difference(record.recordedAt)
                        .abs()
                        .inMinutes <
                    1);
          });

          if (recordExists) {
            AppLogger.debug(
              '⚠️ Registro duplicado detectado, ignorando: ${record.name} (${record.role.label})',
              tag: 'Realtime',
            );
            return;
          }

          // Agregar el nuevo registro a los existentes
          // applyRecord crea una nueva lista con el registro agregado
          final updated = current.applyRecord(record);
          _latest = updated;

          AppLogger.info(
            '📝 Registro agregado - Total registros: ${updated.records.length} (antes: ${current.records.length})',
            tag: 'Realtime',
          );

          AppLogger.info(
            '📊 Datos actualizados - Instructores: ${updated.instructores}, '
            'Aprendices: ${updated.aprendices}, Funcionarios: ${updated.funcionarios}, '
            'Visitantes: ${updated.visitantes}',
            tag: 'Realtime',
          );

          _streamController.add(updated);
          _statusController.add(SocketStatus.connected);
          _updateResumeToken();
          return;
        }
      }

      // Manejar evento estadisticas.actualizadas (tiene prioridad)
      if (payload['event'] == 'estadisticas.actualizadas') {
        final data = payload['data'] ?? payload;
        AppLogger.info(
          '📊 Evento estadisticas.actualizadas recibido',
          tag: 'Realtime',
        );

        // Actualizar con las estadísticas recibidas del backend
        // Estas estadísticas tienen prioridad sobre los cálculos locales
        final updated = current.mergeFromSocket(data);
        _latest = updated;

        AppLogger.info(
          '📊 Estadísticas actualizadas - Instructores: ${updated.instructores}, '
          'Aprendices: ${updated.aprendices}, Funcionarios: ${updated.funcionarios}, '
          'Visitantes: ${updated.visitantes}',
          tag: 'Realtime',
        );

        _streamController.add(updated);
        _statusController.add(SocketStatus.connected);
        _updateResumeToken();
        return;
      }

      // Compatibilidad: Si hay un registro nuevo del servidor Node.js
      if (payload.containsKey('record')) {
        final registroJson = payload['record'];
        if (registroJson is Map<String, dynamic>) {
          final record = AttendanceRecord.fromServerJson(registroJson);

          AppLogger.info(
            '📥 Nuevo registro recibido por WebSocket: ${record.name} (${record.role.label})',
            tag: 'Realtime',
          );

          // Verificar duplicados también para el formato de compatibilidad
          final recordExists = current.records.any((existing) {
            return existing.name == record.name &&
                existing.role == record.role &&
                (existing.recordedAt
                        .difference(record.recordedAt)
                        .abs()
                        .inMinutes <
                    1);
          });

          if (recordExists) {
            AppLogger.debug(
              '⚠️ Registro duplicado detectado (formato compatibilidad), ignorando: ${record.name}',
              tag: 'Realtime',
            );
            return;
          }

          final updated = current.applyRecord(record);
          _latest = updated;

          AppLogger.info(
            '📊 Datos actualizados - Instructores: ${updated.instructores}, '
            'Aprendices: ${updated.aprendices}, Funcionarios: ${updated.funcionarios}, '
            'Visitantes: ${updated.visitantes}, '
            'Total registros: ${updated.records.length}',
            tag: 'Realtime',
          );

          _streamController.add(updated);
          _statusController.add(SocketStatus.connected);
          _updateResumeToken();
          return;
        }
      }

      // Para otros tipos de payload, intentar procesarlos de diferentes maneras
      AppLogger.info(
        '🔄 Procesando payload genérico - Intentando diferentes formatos',
        tag: 'Realtime',
      );

      // Intentar procesar como estadísticas directas
      if (payload.containsKey('instructores') ||
          payload.containsKey('aprendices') ||
          payload.containsKey('funcionarios') ||
          payload.containsKey('visitantes')) {
        AppLogger.info(
          '📊 Detectado formato de estadísticas directas en payload',
          tag: 'Realtime',
        );
        final updated = current.mergeFromSocket(payload);
        _latest = updated;
        _streamController.add(updated);
        _statusController.add(SocketStatus.connected);
        _updateResumeToken();
        AppLogger.info(
          '✅ Estadísticas actualizadas desde payload - '
          'Instructores: ${updated.instructores}, '
          'Aprendices: ${updated.aprendices}, '
          'Funcionarios: ${updated.funcionarios}, '
          'Visitantes: ${updated.visitantes}',
          tag: 'Realtime',
        );
        return;
      }

      // Intentar procesar con mergeFromSocket (método genérico)
      try {
        final updated = current.mergeFromSocket(payload);
        // Solo actualizar si hay cambios reales
        if (updated.instructores != current.instructores ||
            updated.aprendices != current.aprendices ||
            updated.funcionarios != current.funcionarios ||
            updated.visitantes != current.visitantes ||
            updated.records.length != current.records.length) {
          _latest = updated;
          _streamController.add(updated);
          _statusController.add(SocketStatus.connected);
          _updateResumeToken();
          AppLogger.info(
            '✅ Datos actualizados desde payload genérico - '
            'Instructores: ${updated.instructores}, '
            'Aprendices: ${updated.aprendices}, '
            'Funcionarios: ${updated.funcionarios}, '
            'Visitantes: ${updated.visitantes}',
            tag: 'Realtime',
          );
        } else {
          AppLogger.debug(
            '⚠️ Payload procesado pero no hay cambios en los datos',
            tag: 'Realtime',
          );
        }
      } catch (e) {
        AppLogger.warn(
          '⚠️ No se pudo procesar el payload con mergeFromSocket: $e',
          tag: 'Realtime',
        );
        // Intentar al menos loguear el payload para debugging
        AppLogger.debug('Payload no procesado: $payload', tag: 'Realtime');
      }
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
