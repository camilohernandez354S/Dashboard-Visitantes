import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';

class HistoricalChartPanel extends StatelessWidget {
  const HistoricalChartPanel({super.key});

  static const _weeks = ['Semana 1', 'Semana 2', 'Semana 3', 'Semana 4'];
  static const _historicalTotals = [520, 560, 610, 695];

  @override
  Widget build(BuildContext context) {
    final spots = List<FlSpot>.generate(
      _weeks.length,
      (index) => FlSpot(index.toDouble(), _historicalTotals[index].toDouble()),
    );

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
          const Text(
            '📈 Tendencia de las últimas 4 semanas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AdminTheme.textDark,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0, end: 1),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 16),
                    child: child,
                  ),
                );
              },
              child: LineChart(
                LineChartData(
                  minY:
                      _historicalTotals
                          .reduce((a, b) => a < b ? a : b)
                          .toDouble() -
                      20,
                  maxY:
                      _historicalTotals
                          .reduce((a, b) => a > b ? a : b)
                          .toDouble() +
                      40,
                  minX: 0,
                  maxX: (_weeks.length - 1).toDouble(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 46,
                        interval: 40,
                        getTitlesWidget: (value, meta) {
                          if (value % 40 != 0) return const SizedBox();
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AdminTheme.textMuted,
                            ),
                          );
                        },
                      ),
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
                          if (index < 0 || index >= _weeks.length) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _weeks[index],
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
                    drawVerticalLine: true,
                    getDrawingHorizontalLine:
                        (value) => FlLine(
                          color: AdminTheme.panelBorder,
                          strokeWidth: 1,
                        ),
                    getDrawingVerticalLine:
                        (value) => FlLine(
                          color: AdminTheme.panelBorder.withOpacity(0.5),
                          strokeWidth: 1,
                        ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 4,
                      color: AdminTheme.appBar,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AdminTheme.appBar.withOpacity(0.18),
                            AdminTheme.appBar.withOpacity(0.04),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
