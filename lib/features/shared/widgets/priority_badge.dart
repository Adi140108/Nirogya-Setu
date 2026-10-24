import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/screening_rules.dart';

class PriorityBadge extends StatelessWidget {
  final HealthPriority priority;
  final bool showLabel;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (priority) {
      case HealthPriority.red:
        bg = AppColors.riskRedSurface;
        fg = AppColors.riskRed;
        label = 'RED — High Urgency';
        icon = Icons.warning_rounded;
        break;
      case HealthPriority.yellow:
        bg = AppColors.riskYellowSurface;
        fg = AppColors.riskYellow;
        label = 'YELLOW — Moderate';
        icon = Icons.error_outline_rounded;
        break;
      case HealthPriority.green:
        bg = AppColors.riskGreenSurface;
        fg = AppColors.riskGreen;
        label = 'GREEN — Normal';
        icon = Icons.check_circle_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          if (showLabel) ...[
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
