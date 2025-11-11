import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';

class DonutChartPanel extends StatelessWidget {
  const DonutChartPanel({super.key, this.breakdown});

  final Map<String, int>? breakdown;

  static const _colors = [
    Color(0xFF28A745),
    Color(0xFF007BFF),
    Color(0xFFF39C12),
  ];

  Map<String, int> get _data =>
      breakdown ?? const {'Modelo': 48, 'Centro': 62, 'Km 11': 35};

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final total = data.values.fold<int>(0, (a, b) => a + b);
    final sections =
        data.entries
            .toList()
            .asMap()
            .entries
            .map(
              (entry) => PieChartSectionData(
                value: entry.value.value.toDouble(),
                color: _colors[entry.key % _colors.length],
                title:
                    '${((entry.value.value / total) * 100).toStringAsFixed(0)}%',
                radius: 70,
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            )
            .toList();

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
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 48,
                borderData: FlBorderData(show: false),
                sections: sections,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Distribución por sede',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AdminTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                ...data.entries.toList().asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _colors[entry.key % _colors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${entry.value.key}: ${entry.value.value} personas',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AdminTheme.textMuted,
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
      ),
    );
  }
}
