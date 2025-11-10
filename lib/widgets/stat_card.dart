import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  });

  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final double variation;
  final String? tooltip;

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
      height: 122,
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
      child: Row(
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
              mainAxisAlignment: MainAxisAlignment.center,
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
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) {
      return card;
    }
    return Tooltip(message: tooltip!, preferBelow: false, child: card);
  }
}
