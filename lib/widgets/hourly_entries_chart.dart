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
        height: 320,
        decoration: BoxDecoration(
          color: AdminTheme.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AdminTheme.panelBorder, width: 1.5),
          boxShadow: AdminTheme.cardShadow,
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AdminTheme.bondiBlue),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        height: 320,
        decoration: BoxDecoration(
          color: AdminTheme.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AdminTheme.panelBorder, width: 1.5),
          boxShadow: AdminTheme.cardShadow,
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Error al cargar datos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AdminTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AdminTheme.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(
                backgroundColor: AdminTheme.bondiBlue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
        color: AdminTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.panelBorder.withOpacity(0.5), width: 1),
        boxShadow: AdminTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(20),
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
                            Icon(
                              Icons.access_time_rounded,
                              color: AdminTheme.bondiBlue,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ingresos por hora',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AdminTheme.textDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Personas que han ingresado en cada hora',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AdminTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_data!.fecha.isNotEmpty)
                          Text(
                            'Datos del ${_data!.fecha}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                      Text(
                        'Total: ${NumberFormat.decimalPattern().format(totalEntradas)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AdminTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Promedio: ${promedio.toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AdminTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 300,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxValue,
                    minY: 0,
                    barTouchData: BarTouchData(
                      enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AdminTheme.regalBlue,
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
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: 0.2,
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
                          reservedSize: 52,
                          interval: _calculateInterval(maxValue),
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const SizedBox();
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
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
                          reservedSize: 52,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= labels.length) {
                              return const SizedBox();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                labels[index],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AdminTheme.textDark,
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
                        color: AdminTheme.panelBorder,
                        strokeWidth: 1.5,
                        dashArray: [5, 5],
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
                            width: 28,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                            color: isMax
                                ? AdminTheme.bondiBlue
                                : AdminTheme.bondiBlue.withOpacity(0.6),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxValue,
                              color: AdminTheme.panelBorder.withOpacity(0.3),
                            ),
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
