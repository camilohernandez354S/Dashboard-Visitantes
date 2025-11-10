import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_realtime_controller.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/color_utils.dart';
import '../widgets/combined_chart.dart';
import '../widgets/stat_card.dart';

/// Dashboard principal sin scroll, estilo corporativo.
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
        backgroundColor: const Color(0xFFF4F7F4),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.senaPrimary),
              const SizedBox(height: 16),
              const Text(
                'Cargando dashboard...',
                style: TextStyle(fontSize: 16, color: Color(0xFF5F5F5F)),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null && _latestData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F7F4),
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
                    color: Color(0xFF606060),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _initializeDashboard,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final baselineData = _latestData ?? _dashboardData ?? DashboardData.mock();
    final effectiveStream = _dashboardStream;
    final statusStream = _socketStatusStream;

    return StreamBuilder<DashboardData>(
      stream: effectiveStream,
      initialData: baselineData,
      builder: (context, snapshot) {
        final data = snapshot.data ?? baselineData;
        final bool isRealtimeTick =
            snapshot.connectionState == ConnectionState.active ||
            snapshot.connectionState == ConnectionState.done;
        final lastRefresh = isRealtimeTick ? DateTime.now() : _lastRefresh;
        final showIndicator = lastRefresh != null;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F7F4),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 76,
            titleSpacing: 24,
            title: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.senaPrimary.withOpacity(0.85),
                        AppTheme.senaPrimary.withOpacity(0.65),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.senaPrimary.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.dashboard_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Dashboard de Visitantes SENA',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2B2B2B),
                  ),
                ),
              ],
            ),
            actions: [
              if (statusStream != null)
                StreamBuilder<SocketStatus>(
                  stream: statusStream,
                  initialData: SocketStatus.connecting,
                  builder: (context, statusSnapshot) {
                    final status = statusSnapshot.data ?? SocketStatus.idle;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildSocketStatusPill(status),
                    );
                  },
                ),
              if (showIndicator)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AnimatedOpacity(
                    opacity: _contentVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 18,
                            color: Color(0xFF5F5F5F),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('HH:mm:ss').format(_currentTime),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3D3D3D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = (constraints.maxWidth * 0.06).clamp(
                24.0,
                64.0,
              );
              final verticalPadding = (constraints.maxHeight * 0.04).clamp(
                24.0,
                64.0,
              );
              final isCompact = constraints.maxWidth < 900;

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: AnimatedOpacity(
                        opacity: _contentVisible ? 1 : 0,
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.easeIn,
                        child: _buildCardsSection(constraints, data, isCompact),
                      ),
                    ),
                    SizedBox(
                      height: (constraints.maxHeight * 0.04).clamp(18.0, 32.0),
                    ),
                    Expanded(
                      flex: 5,
                      child: CombinedChart(
                        data: data.weekly,
                        barColor: AppTheme.senaPrimary,
                        lineColor: const Color(0xFF4D6CFA),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          floatingActionButton: _buildRefreshFab(),
        );
      },
    );
  }

  Widget _buildCardsSection(
    BoxConstraints constraints,
    DashboardData data,
    bool isCompact,
  ) {
    final cards = [
      StatCard(
        title: 'Aprendices',
        value: data.aprendices,
        icon: Icons.school_rounded,
        color: const Color(0xFF80BFFF),
        variation: data.variationFor('aprendices'),
      ),
      StatCard(
        title: 'Funcionarios',
        value: data.funcionarios,
        icon: Icons.badge_rounded,
        color: const Color(0xFFFFD88D),
        variation: data.variationFor('funcionarios'),
      ),
      StatCard(
        title: 'Visitantes',
        value: data.visitantes,
        icon: Icons.groups_rounded,
        color: const Color(0xFF9EE6B4),
        variation: data.variationFor('visitantes'),
      ),
    ];

    if (!isCompact) {
      final gap = (constraints.maxWidth * 0.025).clamp(18.0, 42.0);
      return Row(
        children: [
          Expanded(child: cards[0]),
          SizedBox(width: gap),
          Expanded(child: cards[1]),
          SizedBox(width: gap),
          Expanded(child: cards[2]),
        ],
      );
    }

    final verticalGap = (constraints.maxHeight * 0.03).clamp(16.0, 28.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        cards[0],
        SizedBox(height: verticalGap),
        cards[1],
        SizedBox(height: verticalGap),
        cards[2],
      ],
    );
  }

  Widget _buildRefreshFab() {
    return FloatingActionButton.extended(
      onPressed: _handleManualRefresh,
      backgroundColor: AppTheme.senaPrimary,
      label: Row(
        children: const [
          Icon(Icons.refresh_rounded),
          SizedBox(width: 8),
          Text('Actualizar'),
        ],
      ),
    );
  }

  Widget _buildSocketStatusPill(SocketStatus status) {
    final (Color color, String label) = switch (status) {
      SocketStatus.connected => (const Color(0xFF20C26D), 'Tiempo real'),
      SocketStatus.connecting => (const Color(0xFF4D6CFA), 'Conectando...'),
      SocketStatus.reconnecting => (const Color(0xFFE5A900), 'Reintentando...'),
      SocketStatus.disconnected => (const Color(0xFFD64545), 'Sin conexión'),
      SocketStatus.idle => (const Color(0xFF9E9E9E), 'Inactivo'),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color.darken(0.15),
            ),
          ),
        ],
      ),
    );
  }
}
