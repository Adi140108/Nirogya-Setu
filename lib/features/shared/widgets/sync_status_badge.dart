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
    // Compact keeps the word (rule: never icon/colour alone), just tighter.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(status.icon, size: compact ? 14 : 16, color: status.color),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            status.displayName,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: status.color),
          ),
        ),
      ],
    );
  }
}
