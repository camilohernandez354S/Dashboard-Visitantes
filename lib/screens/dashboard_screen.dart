import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../providers/dashboard_realtime_controller.dart';
import '../services/api_service.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_chart_panel.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardRealtimeController _realtimeController;
  DashboardData? _dashboardData;
  DashboardData? _latestData;
  Stream<DashboardData>? _dashboardStream;
  Stream<SocketStatus>? _socketStatusStream;
  bool _loading = true;
  String? _errorMessage;
  bool _contentVisible = false;
  DateTime _currentTime = DateTime.now();
  DateTime? _lastRefresh;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _realtimeController = DashboardRealtimeController();
    _startClock();
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
    if (!mounted) return;
    _setupRealtimeStreams();
  }

  Future<void> _refreshFromApi({bool initial = false}) async {
    if (initial) {
      setState(() {
        _loading = true;
        _errorMessage = null;
        _contentVisible = false;
      });
    }

    try {
      final result = await _realtimeController.loadInitialData();
      if (!mounted) return;
      setState(() {
        _dashboardData = result;
        _latestData = result;
        _lastRefresh = DateTime.now();
        _loading = false;
        _contentVisible = true;
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
    setState(() {
      _dashboardStream = _realtimeController.stream.map((data) {
        final now = DateTime.now();
        if (mounted) {
          _dashboardData = data;
          _latestData = data;
          _contentVisible = true;
          _lastRefresh = now;
        } else {
          _dashboardData = data;
          _latestData = data;
          _lastRefresh = now;
        }
        return data;
      });
      _socketStatusStream = _realtimeController.socketStatus;
    });
  }

  Future<void> _handleManualRefresh() async {
    await _realtimeController.manualRefresh();
    if (_dashboardStream == null) {
      _setupRealtimeStreams();
    } else {
      _realtimeController.startRealtime();
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _realtimeController.dispose();
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

    final baselineData = _latestData ?? _dashboardData ?? DashboardData.mock();

    return StreamBuilder<DashboardData>(
      stream: _dashboardStream,
      initialData: baselineData,
      builder: (context, snapshot) {
        final data = snapshot.data ?? baselineData;
        final bool realtimeTick =
            snapshot.connectionState == ConnectionState.active ||
            snapshot.connectionState == ConnectionState.done;
        final lastRefresh = realtimeTick ? DateTime.now() : _lastRefresh;
        final lastRefreshLabel =
            lastRefresh != null
                ? DateFormat('HH:mm:ss').format(lastRefresh)
                : null;

        return Scaffold(
          backgroundColor: AdminTheme.background,
          appBar: AppBar(
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
              if (_socketStatusStream != null)
                StreamBuilder<SocketStatus>(
                  stream: _socketStatusStream,
                  initialData: SocketStatus.connecting,
                  builder: (context, statusSnapshot) {
                    final status = statusSnapshot.data ?? SocketStatus.idle;
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
            ],
          ),
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
              final availableWidth =
                  constraints.maxWidth - (horizontalPadding * 2);
              final cardTooltip =
                  lastRefreshLabel == null
                      ? null
                      : 'Última actualización: $lastRefreshLabel';

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Flexible(
                      flex: 3,
                      child: AnimatedOpacity(
                        opacity: _contentVisible ? 1 : 0,
                        duration: const Duration(milliseconds: 450),
                        child: _buildMetricCards(
                          availableWidth,
                          data,
                          cardTooltip,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      flex: 5,
                      child: FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        child: AdminChartPanel(
                          data: data.weekly,
                          barColor: AdminTheme.accentLime,
                          lineColor: AdminTheme.appBar,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildFooter(),
                  ],
                ),
              );
            },
          ),
        );
      },
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
      ),
      (
        'Aprendiz',
        data.aprendices,
        Icons.school_rounded,
        AdminTheme.successGreen,
        data.variationFor('aprendices'),
      ),
      (
        'Funcionario',
        data.funcionarios,
        Icons.badge_rounded,
        AdminTheme.warningAmber,
        data.variationFor('funcionarios'),
      ),
      (
        'Visitante',
        data.visitantes,
        Icons.directions_walk_rounded,
        AdminTheme.infoTeal,
        data.variationFor('visitantes'),
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
          for (var i = 0; i < metrics.length; i++)
            SizedBox(
              width: itemWidth,
              child: FadeInDown(
                duration: const Duration(milliseconds: 480),
                delay: Duration(milliseconds: 80 * i),
                child: StatCard(
                  title: metrics[i].$1,
                  value: metrics[i].$2,
                  icon: metrics[i].$3,
                  color: metrics[i].$4,
                  variation: metrics[i].$5,
                  tooltip: tooltip,
                ),
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white54),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
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
    );
  }
}
