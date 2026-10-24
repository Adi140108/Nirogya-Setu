import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/sync_status.dart';

class SyncStatusBadge extends StatelessWidget {
  final SyncStatus status;
  final bool compact;

  const SyncStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Tooltip(
        message: status.displayName,
        child: Icon(status.icon, size: 18, color: status.color),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(status.icon, size: 16, color: status.color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          status.displayName,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: status.color),
        ),
      ],
    );
  }
}
