import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/admin_theme.dart';
import '../utils/color_utils.dart';

/// Tarjeta estadística inspirada en AdminLTE.
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
    // Debug: imprimir breakdown recibido
    // ignore: avoid_print
    print('🎨 [StatCard] ${title} - Breakdown: $_breakdown (isEmpty: ${_breakdown.isEmpty})');
    
    final bool isPositive = variation >= 0;
    final bool isNeutral = variation == 0;
    final Color variationColor =
        isNeutral
            ? const Color(0xFF6C757D)
            : (isPositive ? const Color(0xFF28A745) : const Color(0xFFD64545));
    final IconData variationIcon =
        isNeutral
            ? Icons.horizontal_rule_rounded
            : (isPositive
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded);

    final formattedValue = NumberFormat.decimalPattern().format(value);

    final card = Container(
      constraints: const BoxConstraints(minHeight: 160, maxHeight: 188),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.12), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.18),
                ),
                child: Icon(icon, size: 26, color: color.darken(0.1)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: Color(0xFF6C757D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formattedValue,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: color.darken(0.15),
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: variationColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(variationIcon, size: 14, color: variationColor),
                    const SizedBox(width: 4),
                    Text(
                      '${variation.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: variationColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (_trend.isNotEmpty && _trend.any((v) => v > 0)) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 40,
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
                            barWidth: 2,
                            color: color.darken(0.05),
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  color.withOpacity(0.18),
                                  color.withOpacity(0.04),
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
          if (_breakdown.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children:
                  _breakdown.entries
                      .map((entry) => _buildSubSedeChip(entry.key, entry.value))
                      .toList(),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: chipColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: chipColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
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
        return const Color(0xFF28A745);
      case 'centro':
        return const Color(0xFF007BFF);
      case 'km 11':
      case 'km11':
        return const Color(0xFFF39C12);
      default:
        return base;
    }
  }
}
