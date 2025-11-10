import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/visitors_chart.dart';
import '../theme/app_theme.dart';

/// Pantalla principal del Dashboard - Compacto y profesional
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? data;
  bool loading = true;
  String? error;
  DateTime? lastUpdate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Carga los datos del dashboard
  Future<void> _loadData() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await ApiService.fetchDashboardData();
      setState(() {
        data = result;
        lastUpdate = DateTime.now();
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Estado de carga
    if (loading) {
      return Scaffold(
        backgroundColor: AppTheme.light.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppTheme.senaPrimary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Cargando dashboard...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Estado de error
    if (error != null) {
      return Scaffold(
        backgroundColor: AppTheme.light.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Dashboard de Visitantes SENA'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Ocurrió un error',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.senaPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Extraer datos
    final aprendices = (data?['aprendices'] ?? 0) as int;
    final funcionarios = (data?['funcionarios'] ?? 0) as int;
    final visitantes = (data?['visitantes'] ?? 0) as int;

    return Scaffold(
      backgroundColor: AppTheme.light.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F3E8),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.dashboard,
                color: AppTheme.senaPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Dashboard de Visitantes SENA',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.senaPrimary,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header con última actualización
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (lastUpdate != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatTime(lastUpdate!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Grid de tarjetas de estadísticas más compacto
            LayoutBuilder(
              builder: (context, c) {
                int cols = 3;
                if (c.maxWidth < 800) cols = 2;
                if (c.maxWidth < 500) cols = 1;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título de la sección
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        '📊 Estadísticas en tiempo real',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    
                    // Grid de tarjetas compacto
                    GridView.count(
                      crossAxisCount: cols,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.6, // Cards más proporcionadas
                      children: [
                        StatCard(
                          title: 'Aprendices',
                          value: aprendices,
                          icon: Icons.school,
                          color: Colors.blue,
                        ),
                        StatCard(
                          title: 'Funcionarios',
                          value: funcionarios,
                          icon: Icons.badge,
                          color: Colors.orange,
                        ),
                        StatCard(
                          title: 'Visitantes',
                          value: visitantes,
                          icon: Icons.people,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            // Gráfica semanal compacta
            VisitorsChart(
              data: [80, 120, 95, 110, 140, 90, 60],
              labels: ['L', 'M', 'M', 'J', 'V', 'S', 'D'],
              color: AppTheme.senaPrimary,
            ),

            const SizedBox(height: 20),

            // Footer informativo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Los datos se actualizan automáticamente cada minuto',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadData,
        backgroundColor: AppTheme.senaPrimary,
        icon: const Icon(Icons.refresh),
        label: const Text('Actualizar'),
      ),
    );
  }

  /// Formatea la hora para mostrar
  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }
}
