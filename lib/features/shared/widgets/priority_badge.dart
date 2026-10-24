import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/screening_rules.dart';

/// Shared triage colours and words, so screens never write their own switch.
extension HealthPriorityStyle on HealthPriority {
  Color get color => switch (this) {
        HealthPriority.red => AppColors.riskRed,
        HealthPriority.yellow => AppColors.riskYellow,
        HealthPriority.green => AppColors.riskGreen,
      };

  Color get surfaceColor => switch (this) {
        HealthPriority.red => AppColors.riskRedSurface,
        HealthPriority.yellow => AppColors.riskYellowSurface,
        HealthPriority.green => AppColors.riskGreenSurface,
      };

  /// Plain word shown to users: Urgent / Moderate / Normal.
  String get word => switch (this) {
        HealthPriority.red => 'Urgent',
        HealthPriority.yellow => 'Moderate',
        HealthPriority.green => 'Normal',
      };
}

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
    final bg = priority.surfaceColor;
    final fg = priority.color;
    final label = priority.word;
    final icon = switch (priority) {
      HealthPriority.red => Icons.warning_rounded,
      HealthPriority.yellow => Icons.error_outline_rounded,
      HealthPriority.green => Icons.check_circle_outline_rounded,
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
