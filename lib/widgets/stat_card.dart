import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/admin_theme.dart';

/// Tarjeta estadística moderna con diseño vibrante y profesional.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.variation,
    this.tooltip,
    Map<String, int>? breakdown,
    List<int>? trend,
  }) : _breakdown = breakdown ?? const <String, int>{},
       _trend = trend ?? const <int>[];

  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final double variation;
  final String? tooltip;
  final Map<String, int> _breakdown;
  final List<int> _trend;

  @override
  Widget build(BuildContext context) {
    final formattedValue = NumberFormat.decimalPattern().format(value);

    final card = Container(
      constraints: const BoxConstraints(minHeight: 160, maxHeight: 180),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AdminTheme.panelBorder.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: AdminTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: AdminTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getDescriptionForTitle(title),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AdminTheme.textMuted.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formattedValue,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${variation.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AdminTheme.textMuted,
                ),
              ),
              if (_trend.isNotEmpty && _trend.any((v) => v > 0)) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: (_trend.reduce(max) * 1.2).clamp(5.0, double.infinity),
                        titlesData: const FlTitlesData(show: false),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots:
                                _trend
                                    .asMap()
                                    .entries
                                    .map(
                                      (e) => FlSpot(
                                        e.key.toDouble(),
                                        e.value.toDouble(),
                                      ),
                                    )
                                    .toList(),
                            isCurved: true,
                            barWidth: 3,
                            color: color,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  color.withOpacity(0.25),
                                  color.withOpacity(0.08),
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
            ],
          ),
          if (_breakdown.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children:
                  _breakdown.entries
                      .map((entry) => _buildSubSedeChip(entry.key, entry.value))
                      .toList(),
            ),
          ],
        ],
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) {
      return card;
    }
    return Tooltip(message: tooltip!, preferBelow: false, child: card);
  }

  Widget _buildSubSedeChip(String label, int value) {
    final Color chipColor = _colorForLabel(label, base: color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            chipColor.withOpacity(0.18),
            chipColor.withOpacity(0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: chipColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: chipColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: chipColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: chipColor.withOpacity(0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AdminTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForLabel(String label, {required Color base}) {
    switch (label.toLowerCase()) {
      case 'modelo':
        return AdminTheme.successGreen;
      case 'centro':
        return AdminTheme.bondiBlue;
      case 'km 11':
      case 'km11':
        return AdminTheme.warningAmber;
      default:
        return base;
    }
  }

  String _getDescriptionForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'instructor':
        return 'Personal docente que ha ingresado';
      case 'aprendiz':
        return 'Estudiantes que han ingresado';
      case 'funcionario':
        return 'Personal administrativo que ha ingresado';
      case 'visitante':
        return 'Visitantes que han ingresado';
      default:
        return 'Registros de ingreso del día';
    }
  }
}
