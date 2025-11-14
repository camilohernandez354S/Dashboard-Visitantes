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
    // Si todos los valores son 0, usar un máximo mínimo para mostrar el gráfico
    final maxValue = maxValueInData == 0 
        ? 10 
        : max(10, (maxValueInData * 1.25).round());
    final double average =
        values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length;
    final variation = values.isEmpty ? 0 : (values.last - values.first);

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
            mainAxisSize: MainAxisSize.max,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 12,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📅 Evolución diaria de asistencias',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AdminTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Seguimiento por hora de la jornada actual',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AdminTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _StatusBadge(
                        icon: Icons.trending_up_rounded,
                        label: 'Promedio por hora: ${average.toStringAsFixed(0)}',
                        background: const Color(0xFFFEF3C7),
                        foreground: const Color(0xFFE09A00),
                      ),
                      _StatusBadge(
                        icon:
                            variation >= 0
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                        label:
                            '${variation >= 0 ? 'Sube' : 'Baja'} ${variation.abs()} desde ${labels.first}',
                        background:
                            variation >= 0
                                ? const Color(0xFFE6F7EF)
                                : const Color(0xFFFFEBEB),
                        foreground:
                            variation >= 0
                                ? const Color(0xFF009739)
                                : const Color(0xFFD64545),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
                        lineTouchData: LineTouchData(enabled: true),
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
                              reservedSize: 44,
                              interval: _calculateInterval(maxValue.toDouble()),
                              getTitlesWidget: (value, meta) {
                                if (value == 0) return const SizedBox();
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
                          drawVerticalLine: true,
                          horizontalInterval: _calculateInterval(
                            maxValue.toDouble(),
                          ),
                          getDrawingHorizontalLine:
                              (value) => FlLine(
                                color: Colors.grey.shade300,
                                strokeWidth: 1,
                              ),
                          getDrawingVerticalLine:
                              (value) => FlLine(
                                color: Colors.grey.shade300.withOpacity(0.6),
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
                            color: const Color(0xFF009739),
                            barWidth: 4,
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF009739).withOpacity(0.30),
                                  const Color(0xFF009739).withOpacity(0.05),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
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
                              color: const Color(0xFF4285F4),
                              strokeWidth: 2,
                              dashArray: const [6, 4],
                              label: HorizontalLineLabel(
                                show: true,
                                alignment: Alignment.topLeft,
                                padding: const EdgeInsets.only(left: 8),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4285F4),
                                ),
                                labelResolver:
                                    (line) =>
                                        'Promedio semanal ${average.toStringAsFixed(0)}',
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
                                      top: max(8.0, topOffset - 36),
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
      radius: 5,
      color: Colors.white,
      strokeWidth: 3,
      strokeColor: const Color(0xFF009739),
    );
  }
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF009739),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
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
