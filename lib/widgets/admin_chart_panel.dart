import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/admin_theme.dart';
import '../utils/color_utils.dart';

class AdminChartPanel extends StatelessWidget {
  const AdminChartPanel({
    super.key,
    required this.data,
    required this.barColor,
    required this.lineColor,
  });

  final List<WeeklyAttendance> data;
  final Color barColor;
  final Color lineColor;

  List<FlSpot> _buildMovingAverageSpots(List<int> values) {
    if (values.isEmpty) return [];
    final List<double> averages = [];
    const int period = 3;
    for (var i = 0; i < values.length; i++) {
      double sum = 0;
      int count = 0;
      for (var j = i; j > i - period && j >= 0; j--) {
        sum += values[j];
        count++;
      }
      averages.add(sum / count);
    }

    return averages
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('Sin datos para la semana'));
    }

    final values = data.map((e) => e.value).toList();
    final total = values.fold<int>(0, (prev, el) => prev + el);
    final spots = _buildMovingAverageSpots(values);
    final labels = data.map((e) => e.label).toList();
    final maxY = max(values.reduce(max), 10) * 1.2;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminTheme.panelBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📊 Estadísticas semanales',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AdminTheme.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: barColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  'Total semana: $total',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: barColor.darken(0.2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Stack(
              children: [
                BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    minY: 0,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value % 20 != 0) {
                              return const SizedBox();
                            }
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AdminTheme.textMuted,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
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
                                  fontWeight: FontWeight.w500,
                                  color: AdminTheme.textMuted,
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
                      getDrawingHorizontalLine:
                          (value) => FlLine(
                            color: AdminTheme.panelBorder,
                            strokeWidth: 1,
                          ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups:
                        values
                            .asMap()
                            .entries
                            .map(
                              (entry) => BarChartGroupData(
                                x: entry.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: entry.value.toDouble(),
                                    width: 22,
                                    borderRadius: BorderRadius.circular(8),
                                    gradient: LinearGradient(
                                      colors: [
                                        barColor.withOpacity(0.85),
                                        barColor.withOpacity(0.55),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.6),
                                      width: 1,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                  ),
                ),
                IgnorePointer(
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY,
                      minX: 0,
                      maxX: (values.length - 1).toDouble(),
                      titlesData: const FlTitlesData(show: false),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          barWidth: 3,
                          color: lineColor,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: lineColor.withOpacity(0.12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final chartHeight = constraints.maxHeight;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: List.generate(values.length, (index) {
                          final value = values[index];
                          final percent =
                              maxY == 0 ? 0.0 : (value / maxY).clamp(0.0, 1.0);
                          final bottomPadding = (chartHeight * (1 - percent))
                              .clamp(0.0, chartHeight);
                          return Expanded(
                            child: Container(
                              alignment: Alignment.bottomCenter,
                              padding: EdgeInsets.only(
                                bottom: bottomPadding + 18,
                              ),
                              child: Text(
                                '$value',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AdminTheme.textDark,
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
