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
  }) : _breakdown = breakdown ?? const {'Modelo': 5, 'Centro': 4, 'Km 11': 3};

  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final double variation;
  final String? tooltip;
  final Map<String, int> _breakdown;

  @override
  Widget build(BuildContext context) {
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
      height: _breakdown.isEmpty ? 122 : 150,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
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
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.18),
                ),
                child: Icon(icon, size: 28, color: color.darken(0.1)),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6C757D),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formattedValue,
                          style: TextStyle(
                            fontSize: 32,
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
                              Icon(
                                variationIcon,
                                size: 14,
                                color: variationColor,
                              ),
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
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_breakdown.isNotEmpty) const SizedBox(height: 12),
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
