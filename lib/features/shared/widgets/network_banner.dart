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
          ? const Color(0xFFE8F5E9)
          : const Color(0xFFFFF3E0),
      child: Row(
        children: [
          Icon(
            isOnline ? Icons.sync_rounded : Icons.wifi_off_rounded,
            size: 18,
            color: isOnline ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOnline
                  ? (isSyncing
                      ? 'Synchronizing $pendingCount records with cloud...'
                      : '$pendingCount records ready for cloud sync')
                  : 'Offline Mode: Data saved securely on device',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isOnline ? const Color(0xFF1B5E20) : const Color(0xFFBF360C),
              ),
            ),
          ),
          if (isOnline && pendingCount > 0 && !isSyncing) ...[
            TextButton.icon(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () => syncManager.triggerManualSync(),
              icon: const Icon(Icons.cloud_upload_outlined, size: 16),
              label: const Text('Sync Now', style: TextStyle(fontSize: 12)),
            ),
          ],
          IconButton(
            tooltip: 'Audio guidance hint',
            icon: const Icon(Icons.volume_up_outlined, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              VoiceService().speakPrompt(
                context,
                title: isOnline ? 'सिंक स्थिति / Sync Status' : 'ऑफ़लाइन मोड / Offline Mode',
                hindiText: isOnline
                    ? 'सभी रिकॉर्ड क्लाउड सर्वर से जुड़ रहे हैं।'
                    : 'इंटरनेट बंद होने पर भी आपका डेटा सुरक्षित है।',
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
