import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/screening_rules.dart';

/// Triage label. Always icon + word so it reads without relying on colour.
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
    final (Color bg, Color fg, String label, IconData icon) = switch (priority) {
      HealthPriority.red => (AppColors.riskRedSurface, AppColors.riskRed, 'Urgent', Icons.warning_rounded),
      HealthPriority.yellow => (AppColors.riskYellowSurface, AppColors.riskYellow, 'Moderate', Icons.error_outline_rounded),
      HealthPriority.green => (AppColors.riskGreenSurface, AppColors.riskGreen, 'Normal', Icons.check_circle_outline_rounded),
    };

    return Semantics(
      label: 'Priority: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: fg),
            if (showLabel) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fg),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
