import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum SyncStatus {
  locallySaved,
  pendingSync,
  synced,
}

extension SyncStatusExtension on SyncStatus {
  String get value {
    switch (this) {
      case SyncStatus.locallySaved:
        return 'locally_saved';
      case SyncStatus.pendingSync:
        return 'pending_sync';
      case SyncStatus.synced:
        return 'synced';
    }
  }

  String get displayName {
    switch (this) {
      case SyncStatus.locallySaved:
        return 'Saved Locally';
      case SyncStatus.pendingSync:
        return 'Pending Sync';
      case SyncStatus.synced:
        return 'Cloud Synced';
    }
  }

  Color get color {
    switch (this) {
      case SyncStatus.locallySaved:
        return AppColors.syncLocal;
      case SyncStatus.pendingSync:
        return AppColors.syncPending;
      case SyncStatus.synced:
        return AppColors.syncSynced;
    }
  }

  IconData get icon {
    switch (this) {
      case SyncStatus.locallySaved:
        return Icons.save_outlined;
      case SyncStatus.pendingSync:
        return Icons.sync_problem_rounded;
      case SyncStatus.synced:
        return Icons.cloud_done_rounded;
    }
  }

  static SyncStatus fromString(String? val) {
    switch (val) {
      case 'locally_saved':
        return SyncStatus.locallySaved;
      case 'pending_sync':
        return SyncStatus.pendingSync;
      case 'synced':
      default:
        return SyncStatus.synced;
    }
  }
}
