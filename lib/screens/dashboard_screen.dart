import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../providers/dashboard_realtime_controller.dart';
import '../services/api_service.dart' show DashboardData, AttendanceRole;
import '../services/socket_service.dart';
import '../theme/admin_theme.dart';
import '../widgets/daily_trend_panel.dart';
import '../widgets/hourly_entries_chart.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardRealtimeController _realtimeController;
  late final Stream<SocketStatus> _socketStatusStream;

  DashboardData? _initialData;
  DashboardData? _latestData;
  bool _loading = true;
  String? _errorMessage;
  DateTime _currentTime = DateTime.now();
  DateTime? _lastRefresh;
  Timer? _clockTimer;
  bool _isFullscreen = false;
  StreamSubscription<DashboardData>? _realtimeDataSubscription;

  @override
  void initState() {
    super.initState();
    _realtimeController = DashboardRealtimeController();
    _startClock();
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
      // ignore: avoid_print
      print('🔄 [DashboardScreen] Iniciando carga de datos desde API...');
      final result = await _realtimeController.loadInitialData();
      if (!mounted) return;

      // ignore: avoid_print
      print(
        '✅ [DashboardScreen] Datos recibidos - '
        'Instructores: ${result.instructores}, '
        'Aprendices: ${result.aprendices}, '
        'Total registros: ${result.records.length}',
      );

      setState(() {
        _initialData = result;
        _latestData = result;
        _lastRefresh = DateTime.now();
        _loading = false;
        _errorMessage = null;
      });

      // ignore: avoid_print
      print('✅ [DashboardScreen] Estado actualizado en la UI');
    } catch (e, stackTrace) {
      if (!mounted) return;
      // ignore: avoid_print
      print('❌ [DashboardScreen] Error al cargar datos: $e');
      // ignore: avoid_print
      print('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  void _setupRealtimeStreams() {
    // Iniciar conexión WebSocket
    _realtimeController.startRealtime();
    _socketStatusStream = _realtimeController.socketStatus;

    // ═══════════════════════════════════════════════════════════
    // SUSCRIBIRSE AL STREAM DE DATOS EN TIEMPO REAL
    // ═══════════════════════════════════════════════════════════
    // Esto permite que la UI se actualice automáticamente
    // cuando lleguen nuevos registros por WebSocket
    _realtimeDataSubscription = _realtimeController.stream.listen(
      (newData) {
        if (!mounted) return;

        // ignore: avoid_print
        print(
          '🔄 Actualización recibida del stream - '
          'Instructores: ${newData.instructores}, '
          'Aprendices: ${newData.aprendices}, '
          'Total registros: ${newData.records.length}',
        );

        // Actualizar estado cuando lleguen nuevos datos
        setState(() {
          // Comparar valores anteriores y nuevos para detectar cambios
          final previousInstructores = _latestData?.instructores ?? 0;
          final previousAprendices = _latestData?.aprendices ?? 0;
          final previousFuncionarios = _latestData?.funcionarios ?? 0;
          final previousVisitantes = _latestData?.visitantes ?? 0;
          final previousAsistenciasHoy = _latestData?.asistenciasHoy ?? 0;

          _latestData = newData;
          _lastRefresh = DateTime.now();

          // Si aún no hay datos iniciales, establecerlos
          if (_initialData == null) {
            _initialData = newData;
          }

          // Limpiar error si había uno
          _errorMessage = null;
          _loading = false;

          // Log de actualización con los valores de las tarjetas principales
          // ignore: avoid_print
          print(
            '✅ UI actualizada - '
            'Instructores: $previousInstructores → ${newData.instructores}, '
            'Aprendices: $previousAprendices → ${newData.aprendices}, '
            'Funcionarios: $previousFuncionarios → ${newData.funcionarios}, '
            'Visitantes: $previousVisitantes → ${newData.visitantes}, '
            'Asistencias hoy: $previousAsistenciasHoy → ${newData.asistenciasHoy}',
          );
        });
      },
      onError: (error) {
        if (!mounted) return;
        // ignore: avoid_print
        print('❌ Error en stream de datos en tiempo real: $error');
        // No establecer error aquí para no bloquear la UI
        // El error solo se muestra si falla la carga inicial
      },
    );
  }

  Future<void> _handleManualRefresh() async {
    await _realtimeController.manualRefresh();
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
            children: const [
              CircularProgressIndicator(color: AdminTheme.primaryBlue),
              SizedBox(height: 16),
              Text(
                'Cargando dashboard...',
                style: TextStyle(fontSize: 16, color: AdminTheme.textMuted),
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
                const Icon(
                  Icons.error_outline_rounded,
                  size: 72,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No se pudo cargar la información',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AdminTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _initializeDashboard,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminTheme.primaryBlue,
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
                  const Text('Dashboard de Visitantes SENA'),
                ],
              ),
              actions: [
                StreamBuilder<SocketStatus>(
                  stream: _socketStatusStream,
                  initialData: SocketStatus.connecting,
                  builder: (context, snapshot) {
                    final status = snapshot.data ?? SocketStatus.idle;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _buildSocketStatusPill(status),
                    );
                  },
                ),
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
                ),
                IconButton(
                  tooltip: 'Actualizar manualmente',
                  onPressed: _handleManualRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
                IconButton(
                  tooltip: 'Modo pantalla completa',
                  onPressed: _toggleFullscreen,
                  icon: const Icon(Icons.fullscreen),
                ),
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
          final availableWidth = constraints.maxWidth - (horizontalPadding * 2);

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Monitoreo en tiempo real de asistencia por sede — Centro Agroindustrial del Guaviare',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AdminTheme.textMuted,
                          ),
                        ),
                        if (_isFullscreen) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.topRight,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AdminTheme.appBar,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
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
                          height: MediaQuery.of(context).size.height * 0.4,
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
          );
        },
      ),
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFF2F5F9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
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
    final metrics = [
      (
        'Instructor',
        data.instructores,
        Icons.person_3_rounded,
        AdminTheme.primaryBlue,
        data.variationFor('instructores'),
        data.getBreakdownBySede(AttendanceRole.instructor),
        data.getWeeklyTrend(AttendanceRole.instructor),
      ),
      (
        'Aprendiz',
        data.aprendices,
        Icons.school_rounded,
        AdminTheme.successGreen,
        data.variationFor('aprendices'),
        data.getBreakdownBySede(AttendanceRole.aprendiz),
        data.getWeeklyTrend(AttendanceRole.aprendiz),
      ),
      (
        'Funcionario',
        data.funcionarios,
        Icons.badge_rounded,
        AdminTheme.warningAmber,
        data.variationFor('funcionarios'),
        data.getBreakdownBySede(AttendanceRole.funcionario),
        data.getWeeklyTrend(AttendanceRole.funcionario),
      ),
      (
        'Visitante',
        data.visitantes,
        Icons.directions_walk_rounded,
        AdminTheme.infoTeal,
        data.variationFor('visitantes'),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminTheme.panelBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas del día',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AdminTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Asistencias hoy',
                    data.asistenciasHoy,
                    Icons.event_available_rounded,
                    AdminTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Personas dentro',
                    totalPersonasDentro,
                    Icons.people_rounded,
                    AdminTheme.successGreen,
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
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
        '© ${DateTime.now().year} SENA - Dashboard de Visitantes',
        style: const TextStyle(
          fontSize: 12,
          color: AdminTheme.textMuted,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSocketStatusPill(SocketStatus status) {
    final (Color color, String label) = switch (status) {
      SocketStatus.connected => (const Color(0xFF20C26D), 'En línea'),
      SocketStatus.connecting => (Colors.amber, 'Conectando'),
      SocketStatus.reconnecting => (const Color(0xFFE83E8C), 'Reintentando'),
      SocketStatus.disconnected => (const Color(0xFFD64545), 'Sin conexión'),
      SocketStatus.idle => (const Color(0xFF9E9E9E), 'Inactivo'),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder:
          (child, animation) => ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: FadeTransition(opacity: animation, child: child),
          ),
      child: Container(
        key: ValueKey(label),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white54),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
