import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Gráfica combinada (barras + línea) para asistencias semanales.
class CombinedChart extends StatelessWidget {
  final List<WeeklyAttendance> data;
  final Color barColor;
  final Color lineColor;

  const CombinedChart({
    super.key,
    required this.data,
    required this.barColor,
    required this.lineColor,
  });

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
      return const Center(
        child: Text('Sin datos para la semana'),
      );
    }

    final values = data.map((e) => e.value).toList();
    final total = values.fold<int>(0, (prev, el) => prev + el);
    final spots = _buildMovingAverageSpots(values);
    final labels = data.map((e) => e.label).toList();
    final maxY = (values.reduce((a, b) => a > b ? a : b) * 1.2).clamp(10, 9999).toDouble();

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 28),
            child: child,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.6),
                  Colors.white.withOpacity(0.45),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 26,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            padding: const EdgeInsets.all(28),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Asistencias semanales',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2B2B2B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: barColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            'Total semana: $total',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: barColor.darken(0.1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Stack(
                        children: [
                          BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: maxY,
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.grey.withOpacity(0.15),
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
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
                                            color: Color(0xFF5F5F5F),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  tooltipRoundedRadius: 12,
                                  getTooltipColor: (group) => Colors.black.withOpacity(0.75),
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    final day = labels[group.x.toInt()];
                                    return BarTooltipItem(
                                      '$day\n${rod.toY.toInt()} visitas',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              barGroups: values
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => BarChartGroupData(
                                      x: entry.key,
                                      barRods: [
                                        BarChartRodData(
                                          toY: entry.value.toDouble(),
                                          width: 22,
                                          borderRadius: BorderRadius.circular(12),
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
                            ignoring: true,
                            child: LineChart(
                              LineChartData(
                                minY: 0,
                                maxY: maxY,
                                minX: 0,
                                maxX: (values.length - 1).toDouble(),
                                lineTouchData: const LineTouchData(enabled: false),
                                titlesData: const FlTitlesData(
                                  show: false,
                                ),
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
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

extension on Color {
  Color darken([double amount = .1]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

