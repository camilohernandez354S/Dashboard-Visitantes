import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/admin_theme.dart';

class DailyTrendPanel extends StatelessWidget {
  const DailyTrendPanel({super.key, required this.data});

  final List<HourlyAttendance> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState(context);
    }

    final values = data.map((e) => e.value).toList(growable: false);
    final labels = data.map((e) => e.hour).toList(growable: false);
    final maxValueInData = values.isEmpty ? 0 : values.reduce(max);
    final maxValue = maxValueInData == 0 
        ? 10 
        : max(10, (maxValueInData * 1.25).round());
    final double average =
        values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length;
    final variation = values.isEmpty ? 0 : (values.last - values.first);

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
            mainAxisSize: MainAxisSize.max,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 16,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up_rounded,
                            color: AdminTheme.bondiBlue,
                            size: 24,
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Evolución de ingresos durante el día',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AdminTheme.textDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Cantidad de personas que han ingresado por hora',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AdminTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Seguimiento por hora de la jornada actual',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AdminTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Promedio: ${average.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AdminTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, chartConstraints) {
                    return Stack(
                      children: [
                        LineChart(
                          LineChartData(
                            minX: 0,
                            maxX: (values.length - 1).toDouble(),
                            minY: 0,
                            maxY: maxValue.toDouble(),
                            lineTouchData: LineTouchData(
                              enabled: true,
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (_) => AdminTheme.regalBlue,
                                tooltipRoundedRadius: 8,
                                tooltipPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
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
                                  reservedSize: 48,
                                  interval: _calculateInterval(maxValue.toDouble()),
                                  getTitlesWidget: (value, meta) {
                                    if (value == 0) return const SizedBox();
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
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
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index >= labels.length) {
                                      return const SizedBox();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
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
                              drawVerticalLine: true,
                              horizontalInterval: _calculateInterval(
                                maxValue.toDouble(),
                              ),
                              getDrawingHorizontalLine:
                                  (value) => FlLine(
                                    color: AdminTheme.panelBorder,
                                    strokeWidth: 1.5,
                                    dashArray: [4, 4],
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
                                color: AdminTheme.bondiBlue,
                                barWidth: 4,
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AdminTheme.bondiBlue.withOpacity(0.1),
                                ),
                                dotData: const FlDotData(
                                  show: true,
                                  getDotPainter: _customDotPainter,
                                ),
                              ),
                            ],
                              extraLinesData: ExtraLinesData(
                              horizontalLines: [
                                HorizontalLine(
                                  y: average,
                                  color: AdminTheme.regalBlue,
                                  strokeWidth: 2.5,
                                  dashArray: const [8, 5],
                                  label: HorizontalLineLabel(
                                    show: true,
                                    alignment: Alignment.topLeft,
                                    padding: const EdgeInsets.only(left: 12, top: 4),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AdminTheme.regalBlue,
                                    ),
                                    labelResolver:
                                        (line) =>
                                            'Promedio: ${average.toStringAsFixed(0)}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: LayoutBuilder(
                            builder: (context, innerConstraints) {
                              final width = innerConstraints.maxWidth;
                              final height = innerConstraints.maxHeight;

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: List.generate(values.length, (index) {
                                  final value = values[index];
                                  final y =
                                      (value / maxValue).clamp(0.0, 1.0).toDouble();
                                  final topOffset = height - (height * y);

                                  return SizedBox(
                                    width: width / values.length,
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          top: max(8.0, topOffset - 40),
                                        ),
                                        child: _ValueChip(label: '$value personas'),
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const SizedBox.shrink();
  }

  static double _calculateInterval(double maxValue) {
    if (maxValue <= 40) return 10;
    if (maxValue <= 100) return 20;
    return 40;
  }

  static FlDotPainter _customDotPainter(
    FlSpot spot,
    double percent,
    LineChartBarData barData,
    int index,
  ) {
    return FlDotCirclePainter(
      radius: 6,
      color: Colors.white,
      strokeWidth: 3.5,
      strokeColor: AdminTheme.bondiBlue,
    );
  }
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AdminTheme.bondiBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
