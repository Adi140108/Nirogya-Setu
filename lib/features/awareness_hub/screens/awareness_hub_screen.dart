import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/awareness_content_model.dart';
import '../../../core/services/offline_video_manager.dart';
import '../../../core/services/voice_service.dart';
import 'video_player_screen.dart';

class AwarenessHubScreen extends StatefulWidget {
  final bool isPublicAccess;

  const AwarenessHubScreen({super.key, this.isPublicAccess = false});

  @override
  State<AwarenessHubScreen> createState() => _AwarenessHubScreenState();
}

class _AwarenessHubScreenState extends State<AwarenessHubScreen> {
  String _selectedTopic = 'All';
  String _selectedLanguage = 'All';

  @override
  Widget build(BuildContext context) {
    final videoManager = context.watch<OfflineVideoManager>();
    final contents = videoManager.contents;
    final isOnline = videoManager.isOnline;

    final topics = {'All', ...contents.map((c) => c.topic)}.toList();
    final languages = {'All', 'Hindi', 'English', 'Regional'}.toList();

    final filtered = contents.where((c) {
      final matchesTopic = _selectedTopic == 'All' || c.topic == _selectedTopic;
      final matchesLang = _selectedLanguage == 'All' || c.language.contains(_selectedLanguage);
      return matchesTopic && matchesLang;
    }).toList();

    final downloadedCount = contents.where((c) => c.downloadStatus == VideoDownloadStatus.downloaded).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aarogya Setu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Public Health Awareness Hub', style: TextStyle(fontSize: 11, color: Color(0xFFE0F2F1))),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_outlined),
            tooltip: 'Audio guidance for Awareness Hub',
            onPressed: () {
              VoiceService().speakPrompt(
                context,
                title: 'Health Hub Guidance',
                hindiText: 'Watch health guidance videos. You can download them to watch 100% offline anytime.',
                englishText: 'Watch health guidance videos. You can download them to watch 100% offline anytime.',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline Videos Counter & Guidance Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFE0F2F1),
            child: Row(
              children: [
                const Icon(Icons.download_done_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$downloadedCount of ${contents.length} videos stored on device (Ready for offline playback)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
                ),
                if (!isOnline)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Offline', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),

          // Statutory Sample vs Verified Guidance Distinction Banner
          _buildVerificationNotice(),

          // Filters: Topics & Languages
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: topics.map((t) {
                      final isSelected = _selectedTopic == t;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(t, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                          selected: isSelected,
                          selectedColor: AppColors.primarySurface,
                          labelStyle: TextStyle(color: isSelected ? AppColors.primaryDark : AppColors.textPrimary),
                          onSelected: (_) => setState(() => _selectedTopic = t),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: languages.map((lang) {
                      final isSelected = _selectedLanguage == lang;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(lang == 'All' ? 'All Languages' : lang, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                          selected: isSelected,
                          selectedColor: const Color(0xFFFFF3E0),
                          checkmarkColor: AppColors.secondary,
                          onSelected: (_) => setState(() => _selectedLanguage = lang),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Video Cards Grid / List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                return _buildVideoCard(item, videoManager);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFF1F5F9),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, size: 16, color: AppColors.roleAsha),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Public Health Notice: All educational media in this catalog is curated from the Ministry of Health & Family Welfare (MoHFW) and verified state guidelines. Content labeled "Verified Guidance" follows national rural protocol.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(AwarenessContentModel item, OfflineVideoManager manager) {
    final isDownloaded = item.downloadStatus == VideoDownloadStatus.downloaded;
    final isDownloading = item.downloadStatus == VideoDownloadStatus.downloading;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video Thumbnail Placeholder with Play Overlay
          Stack(
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF004D40), Color(0xFF00796B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, size: 36, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.topic,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

              // Download Status Pill
              Positioned(
                top: 10,
                right: 10,
                child: _buildDownloadStatusPill(item.downloadStatus),
              ),

              // Verified Badge
              if (item.isVerifiedGuidance)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 12, color: Color(0xFF69F0AE)),
                        SizedBox(width: 4),
                        Text(
                          'Verified Guidance',
                          style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Video Metadata Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text('🗣 ${item.language}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Text('🏛 ${item.source}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Text('📅 ${item.reviewDate}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),

                // Download Progress Indicator
                if (isDownloading) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: item.downloadProgress,
                    backgroundColor: AppColors.primarySurface,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Downloading to local device storage...', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                      Text('${(item.downloadProgress * 100).toInt()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],

                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  children: [
                    // Play Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDownloaded ? AppColors.riskGreen : AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: Icon(isDownloaded ? Icons.offline_pin_rounded : Icons.play_arrow_rounded, size: 18),
                        label: Text(
                          isDownloaded ? 'Play Offline (Saved)' : 'Watch Video',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VideoPlayerScreen(content: item),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Download / Remove Offline Copy Button
                    if (isDownloaded) ...[
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.riskRed),
                        tooltip: 'Delete downloaded file',
                        onPressed: () => manager.removeDownloadedVideo(item.id),
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Save Offline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: isDownloading ? null : () => manager.downloadVideo(item.id),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadStatusPill(VideoDownloadStatus status) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case VideoDownloadStatus.downloaded:
        bg = const Color(0xFF2E7D32);
        fg = Colors.white;
        icon = Icons.check_circle_rounded;
        break;
      case VideoDownloadStatus.downloading:
        bg = const Color(0xFFE65100);
        fg = Colors.white;
        icon = Icons.downloading_rounded;
        break;
      case VideoDownloadStatus.waitingForInternet:
        bg = const Color(0xFFC62828);
        fg = Colors.white;
        icon = Icons.wifi_off_rounded;
        break;
      case VideoDownloadStatus.updateAvailable:
        bg = const Color(0xFFF57F17);
        fg = Colors.white;
        icon = Icons.update_rounded;
        break;
      case VideoDownloadStatus.notDownloaded:
        bg = Colors.black54;
        fg = Colors.white;
        icon = Icons.cloud_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
