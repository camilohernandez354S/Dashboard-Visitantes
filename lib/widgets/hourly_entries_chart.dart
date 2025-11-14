import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../theme/admin_theme.dart';

class HourlyEntriesChart extends StatefulWidget {
  const HourlyEntriesChart({super.key});

  @override
  State<HourlyEntriesChart> createState() => _HourlyEntriesChartState();
}

class _HourlyEntriesChartState extends State<HourlyEntriesChart> {
  EntradasPorHoraData? _data;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService.fetchEntradasPorHora();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AdminTheme.panelBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AdminTheme.primaryBlue),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AdminTheme.panelBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar datos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AdminTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AdminTheme.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(
                backgroundColor: AdminTheme.primaryBlue,
              ),
            ),
          ],
        ),
      );
    }

    if (_data == null || _data!.entradas.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildChart();
  }

  Widget _buildChart() {
    final entradas = _data!.entradas;
    final values = entradas.map((e) => e.total.toDouble()).toList();
    final labels = entradas.map((e) => e.hora).toList();
    final maxValue = values.isEmpty
        ? 10.0
        : max(10.0, values.reduce(max) * 1.2);
    final totalEntradas = values.fold<int>(0, (sum, val) => sum + val.toInt());
    final promedio = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a + b) / values.length;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF6FBF7), Color(0xFFE8F4EC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminTheme.panelBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AdminTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.access_time_rounded,
                            color: AdminTheme.primaryBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Entradas por Hora',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AdminTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_data!.fecha.isNotEmpty)
                      Text(
                        'Fecha: ${_data!.fecha}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AdminTheme.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _StatBadge(
                    icon: Icons.people_rounded,
                    label: 'Total: ${NumberFormat.decimalPattern().format(totalEntradas)}',
                    background: const Color(0xFFE6F7EF),
                    foreground: const Color(0xFF009739),
                  ),
                  _StatBadge(
                    icon: Icons.trending_up_rounded,
                    label: 'Promedio: ${promedio.toStringAsFixed(1)}',
                    background: const Color(0xFFFEF3C7),
                    foreground: const Color(0xFFE09A00),
                  ),
                ],
              ),
            ],
          ),
              const SizedBox(height: 24),
              SizedBox(
                height: 380,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxValue,
                    minY: 0,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AdminTheme.primaryBlue,
                        tooltipRoundedRadius: 8,
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final hora = labels[groupIndex];
                          final total = rod.toY.toInt();
                          return BarTooltipItem(
                            '$hora\n$total personas',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          interval: _calculateInterval(maxValue),
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const SizedBox();
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AdminTheme.textMuted,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= labels.length) {
                              return const SizedBox();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                labels[index],
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4A5568),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _calculateInterval(maxValue),
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: values.asMap().entries.map((entry) {
                      final index = entry.key;
                      final value = entry.value;
                      final isMax = value == values.reduce(max);
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: value,
                            width: 24,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                            color: isMax
                                ? AdminTheme.primaryBlue
                                : AdminTheme.primaryBlue.withOpacity(0.7),
                            gradient: isMax
                                ? LinearGradient(
                                    colors: [
                                      AdminTheme.primaryBlue,
                                      AdminTheme.primaryBlue.withOpacity(0.6),
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  )
                                : null,
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static double _calculateInterval(double maxValue) {
    if (maxValue <= 20) return 5;
    if (maxValue <= 50) return 10;
    if (maxValue <= 100) return 20;
    return 50;
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: foreground.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

