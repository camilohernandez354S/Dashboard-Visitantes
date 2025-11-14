import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../theme/admin_theme.dart';

/// Panel lateral derecho que muestra los últimos 10 registros diarios.
class RecentRecordsPanel extends StatefulWidget {
  final Stream<dynamic>? updateStream;
  final DashboardData? initialData;
  final Stream<Map<String, dynamic>>? socketStream;

  const RecentRecordsPanel({
    super.key,
    this.updateStream,
    this.initialData,
    this.socketStream,
  });

  @override
  State<RecentRecordsPanel> createState() => _RecentRecordsPanelState();
}

class _RecentRecordsPanelState extends State<RecentRecordsPanel> {
  List<DailyRecord> _records = [];
  bool _loading = true;
  String? _errorMessage;
  StreamSubscription<dynamic>? _dashboardStreamSubscription;
  StreamSubscription<Map<String, dynamic>>? _socketStreamSubscription;
  int _consecutiveErrors = 0;
  DateTime? _lastErrorTime;
  static const int _maxConsecutiveErrors = 3;
  static const Duration _errorBackoffDuration = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    // Cargar registros iniciales inmediatamente
    _loadInitialRecords();

    // Escuchar el stream del socket para agregar nuevos registros inmediatamente
    if (widget.socketStream != null) {
      _socketStreamSubscription = widget.socketStream!.listen(
        (payload) {
          _handleSocketEvent(payload);
        },
        onError: (error) {
          // Ignorar errores del stream
        },
      );
    }

    // Escuchar el stream del dashboard para recargar cuando haya cambios
    if (widget.updateStream != null) {
      _dashboardStreamSubscription = widget.updateStream!.listen(
        (data) {
          // Cuando el dashboard se actualiza (por ejemplo, cuando llega un evento visitante.actualizado),
          // recargar los últimos 10 registros desde el endpoint para asegurar que tenemos los datos más recientes
          if (mounted) {
            // Resetear contador de errores si el dashboard se actualizó exitosamente
            _consecutiveErrors = 0;
            _lastErrorTime = null;
            // Recargar registros silenciosamente
            _loadInitialRecords(silent: true);
          }
        },
        onError: (error) {
          // Ignorar errores del stream
        },
      );
    }
  }

  @override
  void dispose() {
    _dashboardStreamSubscription?.cancel();
    _socketStreamSubscription?.cancel();
    super.dispose();
  }

  /// Carga los registros iniciales desde el endpoint
  Future<void> _loadInitialRecords({bool silent = false}) async {
    // Si hay muchos errores consecutivos, esperar antes de intentar de nuevo
    if (_consecutiveErrors >= _maxConsecutiveErrors && _lastErrorTime != null) {
      final timeSinceLastError = DateTime.now().difference(_lastErrorTime!);
      if (timeSinceLastError < _errorBackoffDuration) {
        // Aún estamos en el período de backoff, no intentar cargar
        return;
      }
      // Resetear contador si ya pasó el tiempo de backoff
      _consecutiveErrors = 0;
    }

    if (!silent) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final records = await ApiService.fetchRegistrosDiarios();

      // Si llegamos aquí, la conexión fue exitosa, resetear contador de errores
      _consecutiveErrors = 0;
      _lastErrorTime = null;

      // Ordenar por timestamp descendente (más recientes primero)
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      // Tomar solo los últimos 10
      final last10 = records.take(10).toList();

      if (mounted) {
        setState(() {
          _records = last10;
          _loading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString().toLowerCase();
        final isConnectionError =
            errorStr.contains('timeout') ||
            errorStr.contains('connection') ||
            errorStr.contains('failed host lookup') ||
            errorStr.contains('network') ||
            errorStr.contains('socket');

        if (isConnectionError) {
          // Incrementar contador de errores consecutivos
          _consecutiveErrors++;
          _lastErrorTime = DateTime.now();
        }

        setState(() {
          _loading = false;
          // Error de conexión: mantener lista vacía sin mostrar error
          _errorMessage = null;
        });
      }
    }
  }

  /// Maneja eventos del WebSocket para agregar nuevos registros inmediatamente
  void _handleSocketEvent(Map<String, dynamic> payload) {
    try {
      final event = payload['event']?.toString();

      // Procesar eventos de visitante actualizado
      if (event == 'visitante.actualizado') {
        final data = payload['data'] ?? payload;

        // El data puede ser un Map o estar directamente en el payload
        Map<String, dynamic> eventData;
        if (data is Map<String, dynamic>) {
          eventData = data;
        } else {
          eventData = payload;
        }

        final tipo =
            eventData['tipo']?.toString().toLowerCase() ??
            eventData['tipo_registro']?.toString().toLowerCase() ??
            '';

        if (tipo == 'entrada' || tipo == 'salida') {
          // Convertir el payload del WebSocket a DailyRecord
          final newRecord = _convertSocketPayloadToDailyRecord(eventData);
          if (newRecord != null) {
            _addNewRecord(newRecord);
          }
        }
      }
    } catch (e) {
      // Ignorar errores silenciosamente para no interrumpir el flujo
    }
  }

  /// Convierte el payload del WebSocket a DailyRecord
  DailyRecord? _convertSocketPayloadToDailyRecord(Map<String, dynamic> data) {
    try {
      // Extraer nombre y apellido del visitante
      final visitante = data['visitante'] as Map<String, dynamic>?;
      final nombreCompleto =
          visitante?['nombre']?.toString() ?? data['nombre']?.toString() ?? '';

      // Separar nombre y apellido si vienen juntos
      String nombre = '';
      String apellido = '';
      if (nombreCompleto.isNotEmpty) {
        final partes = nombreCompleto.trim().split(' ');
        if (partes.length >= 2) {
          nombre = partes.first;
          apellido = partes.sublist(1).join(' ');
        } else {
          nombre = nombreCompleto;
          apellido = '';
        }
      }

      // Extraer cargo
      final cargo =
          (visitante?['cargo'] ??
                  visitante?['rol'] ??
                  visitante?['tipo_persona'] ??
                  data['cargo'] ??
                  data['rol'] ??
                  data['tipo_persona'] ??
                  '')
              .toString()
              .trim();

      // Obtener tipo (entrada o salida)
      final tipo = data['tipo']?.toString().toLowerCase() ?? 'entrada';

      // Obtener timestamp
      DateTime timestamp = DateTime.now();
      if (data.containsKey('timestamp')) {
        final ts = data['timestamp'];
        if (ts is String) {
          timestamp = DateTime.tryParse(ts) ?? DateTime.now();
        }
      } else if (data.containsKey('created_at')) {
        final ts = data['created_at'];
        if (ts is String) {
          timestamp = DateTime.tryParse(ts) ?? DateTime.now();
        }
      } else if (visitante != null) {
        if (visitante.containsKey('hora_entrada')) {
          final ts = visitante['hora_entrada'];
          if (ts is String) {
            timestamp = DateTime.tryParse(ts) ?? DateTime.now();
          }
        } else if (visitante.containsKey('hora_salida')) {
          final ts = visitante['hora_salida'];
          if (ts is String) {
            timestamp = DateTime.tryParse(ts) ?? DateTime.now();
          }
        }
      }

      return DailyRecord(
        nombre: nombre,
        apellido: apellido,
        cargo: cargo,
        tipo: tipo,
        timestamp: timestamp,
      );
    } catch (e) {
      return null;
    }
  }

  /// Agrega un nuevo registro al inicio de la lista y mantiene máximo 10
  void _addNewRecord(DailyRecord newRecord) {
    if (!mounted) return;

    setState(() {
      // Verificar si el registro ya existe (por timestamp y nombre) para evitar duplicados
      final exists = _records.any(
        (r) =>
            r.nombreCompleto == newRecord.nombreCompleto &&
            r.timestamp.difference(newRecord.timestamp).abs().inSeconds < 5,
      );

      if (!exists) {
        // Agregar al inicio de la lista
        _records.insert(0, newRecord);

        // Mantener máximo 10 elementos
        if (_records.length > 10) {
          _records = _records.take(10).toList();
        }
      }

      // Limpiar error si había uno
      _errorMessage = null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: AdminTheme.panelBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_buildHeader(), Expanded(child: _buildContent())],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AdminTheme.background,
            AdminTheme.background.withOpacity(0.95),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AdminTheme.panelBorder.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AdminTheme.primaryBlue.withOpacity(0.15),
                  AdminTheme.primaryBlue.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AdminTheme.primaryBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AdminTheme.primaryBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Últimos registros',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AdminTheme.textDark,
                letterSpacing: -0.3,
              ),
            ),
          ),
          // Indicador de actualización automática mejorado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AdminTheme.successGreen.withOpacity(0.15),
                  AdminTheme.successGreen.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AdminTheme.successGreen.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AdminTheme.successGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AdminTheme.successGreen.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
                const Text(
                  'Auto',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AdminTheme.successGreen,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading && _records.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AdminTheme.primaryBlue),
        ),
      );
    }

    if (_errorMessage != null && _records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AdminTheme.textMuted.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar registros',
                style: TextStyle(fontSize: 14, color: AdminTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    if (_records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_rounded,
                size: 48,
                color: AdminTheme.textMuted.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No hay registros',
                style: TextStyle(fontSize: 14, color: AdminTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: _records.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return _buildRecordItem(_records[index], index);
      },
    );
  }

  Widget _buildRecordItem(DailyRecord record, int index) {
    final esEntrada = record.esEntrada;
    final color = esEntrada ? AdminTheme.successGreen : AdminTheme.warningAmber;
    final icon = esEntrada ? Icons.login_rounded : Icons.logout_rounded;
    final label = esEntrada ? 'Entrada' : 'Salida';
    final timeFormat = DateFormat('HH:mm:ss');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AdminTheme.panelBorder.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre completo (jerarquía principal mejorada)
            Text(
              record.nombreCompleto.isNotEmpty
                  ? record.nombreCompleto
                  : 'Sin nombre',
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: AdminTheme.textDark,
                height: 1.35,
                letterSpacing: -0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // Cargo (texto secundario mejorado)
            if (record.cargo.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AdminTheme.textMuted.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.business_rounded,
                      size: 13,
                      color: AdminTheme.textMuted.withOpacity(0.8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      record.cargo,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AdminTheme.textMuted.withOpacity(0.9),
                        height: 1.3,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            // Acción y timestamp mejorados
            Row(
              children: [
                // Tag de acción (entrada/salida) mejorado
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.15),
                        color.withOpacity(0.10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: color.withOpacity(0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 15, color: color),
                      const SizedBox(width: 7),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Timestamp mejorado
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AdminTheme.textMuted.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: AdminTheme.textMuted.withOpacity(0.75),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${timeFormat.format(record.timestamp)} • ${dateFormat.format(record.timestamp)}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AdminTheme.textMuted.withOpacity(0.85),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
