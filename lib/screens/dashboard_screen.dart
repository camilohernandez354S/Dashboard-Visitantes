import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../providers/dashboard_realtime_controller.dart';
import '../services/api_service.dart' show DashboardData, AttendanceRole;
import '../theme/admin_theme.dart';
import '../widgets/daily_trend_panel.dart';
import '../widgets/hourly_entries_chart.dart';
import '../widgets/recent_records_panel.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardRealtimeController _realtimeController;

  DashboardData? _initialData;
  DashboardData? _latestData;
  bool _loading = true;
  String? _errorMessage;
  DateTime _currentTime = DateTime.now();
  DateTime? _lastRefresh;
  Timer? _clockTimer;
  Timer? _autoRefreshTimer;
  bool _isFullscreen = false;
  StreamSubscription<DashboardData>? _realtimeDataSubscription;

  // Intervalo de actualización automática (30 segundos)
  static const Duration _autoRefreshInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _realtimeController = DashboardRealtimeController();
    _startClock();
    _startAutoRefresh();
    // ═══════════════════════════════════════════════════════════
    // ORDEN DE INICIALIZACIÓN CRÍTICO:
    // 1. Primero configurar los streams (para escuchar actualizaciones)
    // 2. Luego cargar datos iniciales
    // ═══════════════════════════════════════════════════════════
    _setupRealtimeStreams();
    _initializeDashboard();
  }

  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _currentTime = DateTime.now());
    });
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) {
      if (!mounted) return;
      // Actualizar datos automáticamente sin mostrar loading
      _refreshFromApi(initial: false);
    });
  }

  Future<void> _initializeDashboard() async {
    await _refreshFromApi(initial: true);
  }

  Future<void> _refreshFromApi({bool initial = false}) async {
    if (initial) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final result = await _realtimeController.loadInitialData();
      if (!mounted) return;

      setState(() {
        _initialData = result;
        _latestData = result;
        _lastRefresh = DateTime.now();
        _loading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  void _setupRealtimeStreams() {
    // Iniciar conexión WebSocket
    _realtimeController.startRealtime();

    // ═══════════════════════════════════════════════════════════
    // SUSCRIBIRSE AL STREAM DE DATOS EN TIEMPO REAL
    // ═══════════════════════════════════════════════════════════
    // Esto permite que la UI se actualice automáticamente
    // cuando lleguen nuevos registros por WebSocket
    _realtimeDataSubscription = _realtimeController.stream.listen(
      (newData) {
        if (!mounted) return;

        // Actualizar estado cuando lleguen nuevos datos
        setState(() {
          _latestData = newData;
          _lastRefresh = DateTime.now();

          // Si aún no hay datos iniciales, establecerlos
          if (_initialData == null) {
            _initialData = newData;
          }

          // Limpiar error si había uno
          _errorMessage = null;
          _loading = false;
        });
      },
      onError: (error) {
        if (!mounted) return;
        // No establecer error aquí para no bloquear la UI
        // El error solo se muestra si falla la carga inicial
      },
    );
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _autoRefreshTimer?.cancel();
    // Cancelar suscripción al stream de datos
    _realtimeDataSubscription?.cancel();
    _realtimeController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AdminTheme.background,
        body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AdminTheme.bondiBlue),
                  const SizedBox(height: 20),
                  Text(
                    'Cargando información...',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AdminTheme.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Por favor espere un momento',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AdminTheme.textMuted,
                    ),
                  ),
                ],
              ),
        ),
      );
    }

    if (_errorMessage != null && _latestData == null) {
      return Scaffold(
        backgroundColor: AdminTheme.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No se pudo cargar la información',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AdminTheme.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AdminTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _initializeDashboard,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminTheme.bondiBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final baselineData =
        _latestData ?? _initialData ?? DashboardData.fromRecords([]);

    final appBar =
        _isFullscreen
            ? null
            : AppBar(
              titleSpacing: 20,
              title: Row(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.18),
                    ),
                    child: const Icon(
                      Icons.dashboard_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('Control de Ingreso y Salida'),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('HH:mm:ss').format(_currentTime),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            );

    final scaffold = Scaffold(
      backgroundColor: Colors.transparent,
      appBar: appBar,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = (constraints.maxWidth * 0.05).clamp(
            24.0,
            60.0,
          );
          final verticalPadding = (constraints.maxHeight * 0.05).clamp(
            18.0,
            32.0,
          );
          final panelWidth = 400.0;
          // Calcular ancho disponible considerando el panel lateral
          final availableWidth = (constraints.maxWidth - (horizontalPadding * 2) - panelWidth).clamp(400.0, double.infinity);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: horizontalPadding,
                    right: 0,
                    top: verticalPadding,
                    bottom: verticalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sistema de Control de Ingreso y Salida',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: AdminTheme.textDark,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Monitoreo en tiempo real de personas que ingresan y salen del Centro Agroindustrial del Guaviare',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AdminTheme.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        size: 16,
                                        color: AdminTheme.bondiBlue,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Este sistema registra automáticamente cada entrada y salida de personas',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AdminTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (_isFullscreen) ...[
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.topRight,
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AdminTheme.bondiBlue,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: _toggleFullscreen,
                                    icon: const Icon(Icons.fullscreen_exit_rounded),
                                    label: const Text('Salir de pantalla completa'),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              _buildMetricCards(
                                availableWidth,
                                baselineData,
                                _lastRefresh != null
                                    ? 'Última actualización: ${DateFormat('HH:mm:ss').format(_lastRefresh!)}'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              _buildStatisticsPanel(baselineData, availableWidth),
                              const SizedBox(height: 16),
                              const HourlyEntriesChart(),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.25,
                                child: DailyTrendPanel(data: baselineData.hourly),
                              ),
                              const SizedBox(height: 14),
                            ],
                          ),
                        ),
                      ),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
              RecentRecordsPanel(
                updateStream: _realtimeController.stream,
                initialData: baselineData,
                socketStream: _realtimeController.socketService.stream,
              ),
            ],
          );
        },
      ),
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AdminTheme.background,
      ),
      child: scaffold,
    );
  }

  Widget _buildMetricCards(
    double availableWidth,
    DashboardData data,
    String? tooltip,
  ) {
    final spacing = 18.0;

    // Calcular el total para obtener porcentajes
    final total =
        data.instructores +
        data.aprendices +
        data.funcionarios +
        data.visitantes;

    // Función para calcular el porcentaje del total
    double percentageOfTotal(int value) {
      if (total == 0) return 0.0;
      return (value / total * 100);
    }

    final metrics = [
      (
        'Instructor',
        data.instructores,
        Icons.person_3_rounded,
        AdminTheme.regalBlue,  // Azul profundo para instructores
        percentageOfTotal(data.instructores),
        data.getBreakdownBySede(AttendanceRole.instructor),
        data.getWeeklyTrend(AttendanceRole.instructor),
      ),
      (
        'Aprendiz',
        data.aprendices,
        Icons.school_rounded,
        AdminTheme.bondiBlue,  // Azul vibrante para aprendices
        percentageOfTotal(data.aprendices),
        data.getBreakdownBySede(AttendanceRole.aprendiz),
        data.getWeeklyTrend(AttendanceRole.aprendiz),
      ),
      (
        'Funcionario',
        data.funcionarios,
        Icons.badge_rounded,
        AdminTheme.warningAmber,  // Naranja para funcionarios
        percentageOfTotal(data.funcionarios),
        data.getBreakdownBySede(AttendanceRole.funcionario),
        data.getWeeklyTrend(AttendanceRole.funcionario),
      ),
      (
        'Visitante',
        data.visitantes,
        Icons.directions_walk_rounded,
        AdminTheme.successGreen,  // Verde para visitantes
        percentageOfTotal(data.visitantes),
        data.getBreakdownBySede(AttendanceRole.visitante),
        data.getWeeklyTrend(AttendanceRole.visitante),
      ),
    ];

    int columns;
    if (availableWidth >= 1300) {
      columns = 4;
    } else if (availableWidth >= 860) {
      columns = 2;
    } else {
      columns = 1;
    }

    final itemWidth = ((availableWidth - (spacing * (columns - 1))) / columns)
        .clamp(220.0, 520.0);

    return Align(
      alignment: Alignment.topCenter,
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final metric in metrics)
            SizedBox(
              width: itemWidth,
              child: StatCard(
                title: metric.$1,
                value: metric.$2,
                icon: metric.$3,
                color: metric.$4,
                variation: metric.$5,
                tooltip: tooltip,
                breakdown: metric.$6,
                trend: metric.$7,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatisticsPanel(DashboardData data, double availableWidth) {
    final List<Widget> statisticsWidgets = [];

    // Agregar tarjeta de asistencias hoy - SIEMPRE mostrar, incluso si es 0
    final personasDentro = data.personasDentroData;
    final totalPersonasDentro =
        personasDentro != null
            ? (personasDentro['total'] as num?)?.toInt() ?? 0
            : 0;

    // Mostrar siempre el panel de estadísticas del día
    statisticsWidgets.add(
      Container(
        decoration: BoxDecoration(
          color: AdminTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AdminTheme.panelBorder.withOpacity(0.5), width: 1),
          boxShadow: AdminTheme.cardShadow,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 20,
                  color: AdminTheme.bondiBlue,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumen del día de hoy',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AdminTheme.textDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total de ingresos y personas actualmente dentro',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AdminTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Ingresos registrados hoy',
                    data.asistenciasHoy,
                    Icons.login_rounded,
                    AdminTheme.bondiBlue,  // Azul vibrante para asistencias
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Personas actualmente dentro',
                    totalPersonasDentro,
                    Icons.people_rounded,
                    AdminTheme.successGreen,  // Verde para personas dentro
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (statisticsWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children:
          statisticsWidgets
              .map(
                (widget) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: widget,
                ),
              )
              .toList(),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AdminTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormat.decimalPattern().format(value),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Align(
      alignment: Alignment.center,
      child: Text(
        '© ${DateTime.now().year} SENA - Sistema de Control de Ingreso y Salida',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AdminTheme.textMuted,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
