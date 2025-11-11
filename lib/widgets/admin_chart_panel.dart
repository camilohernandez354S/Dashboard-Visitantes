import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/admin_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('Sin datos para la semana'));
    }

    final values = data.map((e) => e.value).toList();
    final total = values.fold<int>(0, (prev, el) => prev + el);
    final labels = data.map((e) => e.label).toList();
    final maxValue = (values.reduce(max) * 1.2).clamp(10, 9999).toDouble();
    final average = total / values.length;
    final Color primaryBarColor = barColor;
    final Color secondaryBarColor = Color.lerp(barColor, Colors.white, 0.35)!;
    final Color badgeColor = barColor;
    final Color trendLineColor = lineColor.withOpacity(0.55);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF9FBF9), Color(0xFFEFF5EF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '📊 Estadísticas semanales',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AdminTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Comparativo general de registros acumulados',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AdminTheme.textMuted,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.orangeAccent.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'Promedio semanal: ${average.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF009739).withOpacity(0.14),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF009739).withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.insights_rounded,
                          size: 16,
                          color: Color(0xFF009739),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Total semanal: $total personas',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF009739),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _LegendRow(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Flexible(
            fit: FlexFit.loose,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width =
                    constraints.maxWidth == double.infinity
                        ? 800.0
                        : constraints.maxWidth;
                final baseHeight = width / 2.2;
                final availableHeight =
                    constraints.maxHeight.isFinite
                        ? constraints.maxHeight
                        : baseHeight;
                final chartHeight =
                    availableHeight.isFinite
                        ? min(availableHeight, max(220.0, baseHeight))
                        : max(220.0, baseHeight);

                return TweenAnimationBuilder<double>(
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
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: chartHeight,
                      width: width,
                      child: Stack(
                        children: [
                          BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: maxValue,
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
                                    reservedSize: 42,
                                    interval: 20,
                                    getTitlesWidget: (value, meta) {
                                      if (value % 20 != 0) {
                                        return const SizedBox();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
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
                                getDrawingHorizontalLine:
                                    (value) => FlLine(
                                      color: Colors.grey.shade300,
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
                                          barsSpace: 12,
                                          barRods: [
                                            BarChartRodData(
                                              toY: entry.value.toDouble(),
                                              width: 18,
                                              gradient: LinearGradient(
                                                colors: [
                                                  primaryBarColor,
                                                  secondaryBarColor,
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    topLeft: Radius.circular(6),
                                                    topRight: Radius.circular(
                                                      6,
                                                    ),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      )
                                      .toList(),
                              extraLinesData: ExtraLinesData(
                                horizontalLines: [
                                  HorizontalLine(
                                    y: average,
                                    color: Colors.orangeAccent,
                                    strokeWidth: 2,
                                    dashArray: const [5, 5],
                                    label: HorizontalLineLabel(
                                      show: true,
                                      labelResolver:
                                          (line) =>
                                              'Promedio: ${average.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orangeAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IgnorePointer(
                            child: LineChart(
                              LineChartData(
                                minY: 0,
                                maxY: maxValue,
                                minX: 0,
                                maxX: (values.length - 1).toDouble(),
                                titlesData: const FlTitlesData(show: false),
                                gridData: const FlGridData(show: false),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots:
                                        values
                                            .asMap()
                                            .entries
                                            .map(
                                              (entry) => FlSpot(
                                                entry.key.toDouble(),
                                                entry.value.toDouble(),
                                              ),
                                            )
                                            .toList(),
                                    isCurved: true,
                                    color: trendLineColor,
                                    barWidth: 3,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        colors: [
                                          trendLineColor.withOpacity(0.18),
                                          trendLineColor.withOpacity(0.05),
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
                          Positioned.fill(
                            child: LayoutBuilder(
                              builder: (context, chartConstraints) {
                                final chartHeightInternal =
                                    chartConstraints.maxHeight;
                                return Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: List.generate(values.length, (
                                    index,
                                  ) {
                                    final value = values[index];
                                    final percent =
                                        maxValue == 0
                                            ? 0.0
                                            : (value / maxValue).clamp(
                                              0.0,
                                              1.0,
                                            );
                                    final bottomPadding = (chartHeightInternal *
                                            (1 - percent))
                                        .clamp(0.0, chartHeightInternal);
                                    return Expanded(
                                      child: Container(
                                        alignment: Alignment.bottomCenter,
                                        padding: EdgeInsets.only(
                                          bottom: bottomPadding + 24,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: badgeColor,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 6,
                                                offset: Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            '$value personas',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _LegendDot(label: 'Modelo', color: Color(0xFF28A745)),
        SizedBox(width: 12),
        _LegendDot(label: 'Centro', color: Color(0xFF007BFF)),
        SizedBox(width: 12),
        _LegendDot(label: 'Km 11', color: Color(0xFFF39C12)),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AdminTheme.textMuted,
          ),
        ),
      ],
    );
  }
}
