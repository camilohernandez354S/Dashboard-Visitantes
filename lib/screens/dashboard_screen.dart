import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../providers/dashboard_realtime_controller.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../theme/admin_theme.dart';
import '../widgets/daily_trend_panel.dart';
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

  @override
  void initState() {
    super.initState();
    _realtimeController = DashboardRealtimeController();
    _startClock();
    _initializeDashboard();
    _setupRealtimeStreams();
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
    _realtimeController.startRealtime();
    _socketStatusStream = _realtimeController.socketStatus;
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

    final baselineData = _latestData ?? _initialData ?? DashboardData.mock();

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
                        padding: const EdgeInsets.symmetric(horizontal: 14),
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
                _buildExecutiveSummary(baselineData),
                const SizedBox(height: 16),
                Expanded(child: DailyTrendPanel(data: baselineData.hourly)),
                const SizedBox(height: 14),
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
        const {'Modelo': 12, 'Centro': 9, 'Km 11': 6},
        const [9, 11, 10, 12, 13, 14, 15],
      ),
      (
        'Aprendiz',
        data.aprendices,
        Icons.school_rounded,
        AdminTheme.successGreen,
        data.variationFor('aprendices'),
        const {'Modelo': 48, 'Centro': 62, 'Km 11': 35},
        const [120, 125, 130, 140, 150, 145, 155],
      ),
      (
        'Funcionario',
        data.funcionarios,
        Icons.badge_rounded,
        AdminTheme.warningAmber,
        data.variationFor('funcionarios'),
        const {'Modelo': 8, 'Centro': 10, 'Km 11': 5},
        const [18, 20, 19, 22, 24, 23, 25],
      ),
      (
        'Visitante',
        data.visitantes,
        Icons.directions_walk_rounded,
        AdminTheme.infoTeal,
        data.variationFor('visitantes'),
        const {'Modelo': 3, 'Centro': 3, 'Km 11': 2},
        const [5, 6, 5, 7, 8, 7, 9],
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

  Widget _buildExecutiveSummary(DashboardData data) {
    final total = data.weeklyTotal;
    final variation = data.variationFor('aprendices');
    final sedeCentro = 0.48; // Placeholder mientras llegan datos reales.

    return Container(
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
            'Resumen ejecutivo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AdminTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Esta semana se registraron $total asistencias en total, '
            'con un crecimiento del ${variation.toStringAsFixed(1)} % frente a la semana anterior. '
            'La sede Centro concentró aproximadamente el ${(sedeCentro * 100).toStringAsFixed(0)} % de los registros, '
            'seguida por las sedes Modelo y Km 11.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AdminTheme.textMuted,
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
