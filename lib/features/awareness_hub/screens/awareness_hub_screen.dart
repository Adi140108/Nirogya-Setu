import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/awareness_content_model.dart';
import '../../../core/services/offline_video_manager.dart';
import '../../../core/services/voice_service.dart';
import '../../shared/widgets/ui.dart';
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
      appBar: AppBar(
        title: const Text('Health videos'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.volume_up_outlined),
            label: const Text('Listen'),
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
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          _OfflineSummary(downloaded: downloadedCount, total: contents.length, isOnline: isOnline),
          const SizedBox(height: AppSpacing.md),
          const _SourceNotice(),
          const SectionHeader('Topic'),
          _ChipRow(
            options: topics,
            selected: _selectedTopic,
            labelFor: (t) => t == 'All' ? 'All topics' : t,
            onSelected: (t) => setState(() => _selectedTopic = t),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ChipRow(
            options: languages,
            selected: _selectedLanguage,
            labelFor: (l) => l == 'All' ? 'All languages' : l,
            onSelected: (l) => setState(() => _selectedLanguage = l),
          ),
          SectionHeader(
            filtered.length == 1 ? '1 video' : '${filtered.length} videos',
          ),
          if (filtered.isEmpty)
            const EmptyState(
              icon: Icons.video_library_outlined,
              title: 'No videos found',
              message: 'Try another topic or language.',
            )
          else
            for (var i = 0; i < filtered.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.md),
              _VideoCard(
                item: filtered[i],
                onWatch: () => _openVideo(filtered[i]),
                onSave: () => videoManager.downloadVideo(filtered[i].id),
                onRemove: () => _confirmRemove(filtered[i], videoManager),
              ),
            ],
        ],
      ),
    );
  }

  void _openVideo(AwarenessContentModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoPlayerScreen(content: item)),
    );
  }

  Future<void> _confirmRemove(AwarenessContentModel item, OfflineVideoManager manager) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from phone?'),
        content: Text('"${item.title}" will need internet to play again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: AppColors.riskRed)),
          ),
        ],
      ),
    );
    if (confirmed == true) manager.removeDownloadedVideo(item.id);
  }
}

/// How many videos are saved on the phone, plus an offline label.
class _OfflineSummary extends StatelessWidget {
  final int downloaded;
  final int total;
  final bool isOnline;

  const _OfflineSummary({required this.downloaded, required this.total, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InfoCard(
      color: AppColors.primarySurface,
      child: Row(
        children: [
          const Icon(Icons.download_done_rounded, color: AppColors.primary, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$downloaded of $total saved on this phone', style: text.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  isOnline ? 'Saved videos play without internet.' : 'You are offline. Only saved videos will play.',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          if (!isOnline) ...[
            const SizedBox(width: AppSpacing.sm),
            const StatusTag(
              'Offline',
              icon: Icons.wifi_off_rounded,
              color: AppColors.secondary,
              background: AppColors.secondarySurface,
            ),
          ],
        ],
      ),
    );
  }
}

class _SourceNotice extends StatelessWidget {
  const _SourceNotice();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.verified_user_outlined, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'These videos come from the Ministry of Health & Family Welfare (MoHFW) and state health guidelines. '
            '"Verified guidance" means it follows national rural health rules.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

/// One horizontally scrolling row of choice chips.
class _ChipRow extends StatelessWidget {
  final List<String> options;
  final String selected;
  final String Function(String) labelFor;
  final ValueChanged<String> onSelected;

  const _ChipRow({
    required this.options,
    required this.selected,
    required this.labelFor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final o in options)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(labelFor(o)),
                selected: selected == o,
                onSelected: (_) => onSelected(o),
              ),
            ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final AwarenessContentModel item;
  final VoidCallback onWatch;
  final VoidCallback onSave;
  final VoidCallback onRemove;

  const _VideoCard({
    required this.item,
    required this.onWatch,
    required this.onSave,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isDownloaded = item.downloadStatus == VideoDownloadStatus.downloaded;
    final isDownloading = item.downloadStatus == VideoDownloadStatus.downloading;

    return InfoCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Thumbnail(topic: item.topic, onTap: onWatch),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _statusTag(item.downloadStatus),
                    if (item.isVerifiedGuidance)
                      const StatusTag('Verified guidance', icon: Icons.verified_rounded),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(item.title, style: text.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(item.description, style: text.bodySmall),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _Meta(icon: Icons.translate_rounded, text: item.language),
                    _Meta(icon: Icons.account_balance_outlined, text: item.source),
                    _Meta(icon: Icons.event_outlined, text: 'Checked ${item.reviewDate}'),
                  ],
                ),
                if (isDownloading) ...[
                  const SizedBox(height: AppSpacing.md),
                  LinearProgressIndicator(
                    value: item.downloadProgress,
                    backgroundColor: AppColors.primarySurface,
                    minHeight: AppSpacing.sm - 2,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(child: Text('Saving to phone…', style: text.bodySmall)),
                      Text('${(item.downloadProgress * 100).toInt()}%', style: text.labelMedium),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(isDownloaded ? Icons.offline_pin_rounded : Icons.play_arrow_rounded),
                    label: Text(isDownloaded ? 'Watch (saved)' : 'Watch video'),
                    onPressed: onWatch,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: isDownloaded
                      ? OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.riskRed),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Remove from phone'),
                          onPressed: onRemove,
                        )
                      : OutlinedButton.icon(
                          icon: const Icon(Icons.download_rounded),
                          label: Text(isDownloading ? 'Saving…' : 'Save to watch offline'),
                          onPressed: isDownloading ? null : onSave,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Download status as icon + word. Not triage, so no red/amber/green:
  /// success uses primary, attention uses secondary, neutral uses grey.
  Widget _statusTag(VideoDownloadStatus status) {
    switch (status) {
      case VideoDownloadStatus.downloaded:
        return const StatusTag('Saved on phone', icon: Icons.check_circle_rounded);
      case VideoDownloadStatus.downloading:
        return const StatusTag('Saving…', icon: Icons.downloading_rounded);
      case VideoDownloadStatus.waitingForInternet:
        return const StatusTag(
          'Waiting for internet',
          icon: Icons.wifi_off_rounded,
          color: AppColors.secondary,
          background: AppColors.secondarySurface,
        );
      case VideoDownloadStatus.updateAvailable:
        return const StatusTag(
          'New version available',
          icon: Icons.update_rounded,
          color: AppColors.secondary,
          background: AppColors.secondarySurface,
        );
      case VideoDownloadStatus.notDownloaded:
        return const StatusTag(
          'Needs internet',
          icon: Icons.cloud_outlined,
          color: AppColors.textSecondary,
          background: AppColors.background,
        );
    }
  }
}

/// Flat video thumbnail placeholder: shows the topic and opens the video.
class _Thumbnail extends StatelessWidget {
  final String topic;
  final VoidCallback onTap;

  const _Thumbnail({required this.topic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Play video about $topic',
      excludeSemantics: true,
      child: Material(
        color: AppColors.primarySurface,
        child: InkWell(
          onTap: onTap,
          // Min height (not fixed) so large system text grows the box instead of overflowing.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.minTouch * 2.5),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: AppSizes.minTouch,
                    height: AppSizes.minTouch,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, size: 28, color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Text(
                      topic,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: Text(text, style: Theme.of(context).textTheme.labelSmall)),
      ],
    );
  }
}
