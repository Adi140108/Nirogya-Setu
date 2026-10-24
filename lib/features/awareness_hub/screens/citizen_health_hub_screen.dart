import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/admin_models.dart';
import '../../../core/models/awareness_content_model.dart';
import '../../../core/services/admin_repository.dart';
import '../../../core/services/health_video_download_manager.dart';
import '../../../core/services/voice_service.dart';
import '../widgets/youtube_thumbnail.dart';
import 'citizen_video_player_screen.dart';

/// Citizen Health Hub: shows exactly the videos the administrator publishes
/// from Admin Portal > Manage Videos (kept in sync through the cloud database).
/// The chosen language changes each card's title and the video that plays.
/// Any language version can be downloaded for offline viewing.
class CitizenHealthHubScreen extends StatefulWidget {
  const CitizenHealthHubScreen({super.key});

  @override
  State<CitizenHealthHubScreen> createState() => _CitizenHealthHubScreenState();
}

class _CitizenHealthHubScreenState extends State<CitizenHealthHubScreen> {
  String? _language;
  String _topic = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final admin = context.read<AdminRepository>();
    final downloads = context.read<HealthVideoDownloadManager>();
    await admin.syncWithCloud();
    if (admin.isLoaded) await downloads.pruneOrphans(admin.videos);
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminRepository>();
    final downloads = context.watch<HealthVideoDownloadManager>();

    final videos = admin.videos;
    final languages = admin.availableVideoLanguages;
    final language = languages.contains(_language)
        ? _language!
        : (languages.contains('Hindi') ? 'Hindi' : (languages.isNotEmpty ? languages.first : null));

    final topics = ['All', ...{for (final v in videos) v.topic}];
    final topic = topics.contains(_topic) ? _topic : 'All';
    final filtered = videos.where((v) => topic == 'All' || v.topic == topic).toList();

    return Scaffold(
      backgroundColor: Colors.white,
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
            tooltip: 'Audio guidance for Health Hub',
            onPressed: () {
              VoiceService().speakPrompt(
                context,
                title: 'Health Hub Guidance',
                hindiText: 'Choose your language, watch health videos, and download them to watch without internet.',
                englishText: 'Choose your language, watch health videos, and download them to watch without internet.',
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFE0F2F1),
              child: Row(
                children: [
                  Icon(admin.isSyncing ? Icons.sync_rounded : Icons.download_done_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      admin.isSyncing
                          ? 'Checking for new videos…'
                          : '${videos.length} video${videos.length == 1 ? '' : 's'} • '
                              '${downloads.downloadedCount} saved on this device for offline viewing',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                    ),
                  ),
                  if (!downloads.isOnline)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(10)),
                      child: const Text('Offline',
                          style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
            if (languages.isNotEmpty) _buildFilters(languages, language, topics, topic),
            const Divider(height: 1),
            if (filtered.isEmpty)
              _emptyState(admin.isSyncing)
            else
              for (final v in filtered) _HubVideoCard(video: v, language: language, downloads: downloads),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(List<String> languages, String? language, List<String> topics, String topic) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.translate_rounded, size: 18, color: AppColors.secondary),
                ),
                for (final l in languages)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(l,
                          style: TextStyle(fontSize: 12.5, fontWeight: l == language ? FontWeight.bold : FontWeight.w500)),
                      selected: l == language,
                      selectedColor: const Color(0xFFFFF3E0),
                      labelStyle: TextStyle(color: l == language ? AppColors.secondary : AppColors.textPrimary),
                      onSelected: (_) => setState(() => _language = l),
                    ),
                  ),
              ],
            ),
          ),
          if (topics.length > 2)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final t in topics)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(t, style: TextStyle(fontSize: 12, fontWeight: t == topic ? FontWeight.bold : FontWeight.w500)),
                        selected: t == topic,
                        selectedColor: AppColors.primarySurface,
                        labelStyle: TextStyle(color: t == topic ? AppColors.primaryDark : AppColors.textPrimary),
                        onSelected: (_) => setState(() => _topic = t),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState(bool isSyncing) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 64, 32, 32),
      child: Column(
        children: [
          Icon(isSyncing ? Icons.cloud_sync_rounded : Icons.ondemand_video_rounded, size: 56, color: AppColors.primaryLight),
          const SizedBox(height: 14),
          Text(
            isSyncing ? 'Loading health videos…' : 'No health videos yet',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Videos published by your district health team will appear here. Pull down to refresh.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
          ),
        ],
      ),
    );
  }
}

/// YouTube-style card: full-width 16:9 thumbnail, then icon + title + details.
class _HubVideoCard extends StatelessWidget {
  final HealthVideoModel video;
  final String? language;
  final HealthVideoDownloadManager downloads;

  const _HubVideoCard({required this.video, required this.language, required this.downloads});

  @override
  Widget build(BuildContext context) {
    final variant = video.variantFor(language);
    final isFallback = language != null && variant.language != language;
    final state = downloads.stateFor(video.id, variant);

    void openPlayer() => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CitizenVideoPlayerScreen(videoId: video.id, initialLanguage: variant.language),
          ),
        );

    return InkWell(
      onTap: openPlayer,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  YoutubeThumbnail(youtubeId: variant.youtubeId),
                  if (state.isDownloaded)
                    Positioned(top: 10, left: 10, child: DownloadStatusPill(state: state)),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        variant.language,
                        style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (state.isDownloading)
              LinearProgressIndicator(
                value: state.progress,
                minHeight: 3,
                backgroundColor: AppColors.primarySurface,
                color: AppColors.primary,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 4, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 19,
                    backgroundColor: AppColors.primarySurface,
                    child: Icon(Icons.health_and_safety_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          variant.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            video.topic,
                            if (isFallback) 'Not in $language' else '${video.languages.length} language${video.languages.length == 1 ? '' : 's'}',
                            if (state.isDownloading)
                              'Saving ${(state.progress * 100).toInt()}%'
                            else if (state.isDownloaded)
                              'Saved offline',
                          ].join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: isFallback ? AppColors.secondary : AppColors.textSecondary),
                        ),
                        if (state.error != null && !state.isDownloading) ...[
                          const SizedBox(height: 4),
                          Text(state.error!, style: const TextStyle(fontSize: 11.5, color: AppColors.riskRed)),
                        ],
                      ],
                    ),
                  ),
                  _downloadButton(variant, state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _downloadButton(VideoLanguageVariant variant, HealthVideoDownload state) {
    if (state.isDownloading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    }
    if (state.isDownloaded) {
      return IconButton(
        tooltip: 'Delete offline copy',
        icon: const Icon(Icons.download_done_rounded, color: AppColors.riskGreen),
        onPressed: () => downloads.removeDownload(video.id, variant),
      );
    }
    return IconButton(
      tooltip: 'Save ${variant.language} version offline',
      icon: const Icon(Icons.download_for_offline_outlined, color: AppColors.textSecondary),
      onPressed: () => downloads.download(video.id, variant),
    );
  }
}

class DownloadStatusPill extends StatelessWidget {
  final HealthVideoDownload state;

  const DownloadStatusPill({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late IconData icon;
    switch (state.status) {
      case VideoDownloadStatus.downloaded:
        bg = const Color(0xFF2E7D32);
        icon = Icons.check_circle_rounded;
        break;
      case VideoDownloadStatus.downloading:
        bg = const Color(0xFFE65100);
        icon = Icons.downloading_rounded;
        break;
      case VideoDownloadStatus.waitingForInternet:
        bg = const Color(0xFFC62828);
        icon = Icons.wifi_off_rounded;
        break;
      case VideoDownloadStatus.updateAvailable:
        bg = const Color(0xFFF57F17);
        icon = Icons.update_rounded;
        break;
      case VideoDownloadStatus.notDownloaded:
        bg = Colors.black54;
        icon = Icons.cloud_outlined;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(state.status.displayName,
              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
