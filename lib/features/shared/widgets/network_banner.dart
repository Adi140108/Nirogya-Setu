import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/sync/offline_sync_manager.dart';
import '../../../core/services/voice_service.dart';

/// Thin status strip. Hidden when online and fully synced.
class NetworkBanner extends StatelessWidget {
  const NetworkBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final syncManager = context.watch<OfflineSyncManager>();
    final isOnline = syncManager.isOnline;
    final pendingCount = syncManager.pendingCount;
    final isSyncing = syncManager.isSyncing;

    if (isOnline && pendingCount == 0 && !isSyncing) {
      return const SizedBox.shrink();
    }

    final fg = isOnline ? AppColors.primaryDark : AppColors.secondary;
    final message = isOnline
        ? (isSyncing ? 'Syncing $pendingCount records…' : '$pendingCount records waiting to sync')
        : 'Offline. Your work is saved on this phone.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isOnline ? AppColors.primarySurface : AppColors.secondarySurface,
        border: const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Icon(isOnline ? Icons.sync_rounded : Icons.wifi_off_rounded, size: 20, color: fg),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg),
            ),
          ),
          IconButton(
            tooltip: 'Listen',
            icon: Icon(Icons.volume_up_outlined, size: 22, color: fg),
            onPressed: () {
              VoiceService().speakPrompt(
                context,
                title: isOnline ? 'Sync Status' : 'Offline Mode',
                hindiText: isOnline
                    ? 'Records are being sent to the server.'
                    : 'The app works without internet. Your records are saved on this phone.',
                englishText: isOnline
                    ? 'Records are being sent to the server.'
                    : 'The app works without internet. Your records are saved on this phone.',
              );
            },
          ),
        ],
      ),
    );
  }
}
