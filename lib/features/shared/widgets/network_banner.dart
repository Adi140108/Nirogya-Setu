import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/sync/offline_sync_manager.dart';
import '../../../core/services/voice_service.dart';

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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isOnline
          ? const Color(0xFFE4E6CC)
          : const Color(0xFFF3DCC4),
      child: Row(
        children: [
          Icon(
            isOnline ? Icons.sync_rounded : Icons.wifi_off_rounded,
            size: 18,
            color: isOnline ? const Color(0xFF3B6634) : const Color(0xFFA8452A),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOnline
                  ? (isSyncing
                      ? 'Auto-syncing $pendingCount records to cloud...'
                      : 'Connected • All records auto-synced')
                  : 'Offline Mode: Data saved securely on device',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isOnline ? const Color(0xFF2C4D27) : const Color(0xFFA8452A),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Audio guidance hint',
            icon: const Icon(Icons.volume_up_outlined, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              VoiceService().speakPrompt(
                context,
                title: isOnline ? 'Sync Status' : 'Offline Mode',
                hindiText: isOnline
                    ? 'Records are syncing to Cloud Firestore.'
                    : 'App is functional offline. Records safely saved locally.',
                englishText: isOnline
                    ? 'Records are syncing to Cloud Firestore.'
                    : 'App is functional offline. Records safely saved locally.',
              );
            },
          ),
        ],
      ),
    );
  }
}
