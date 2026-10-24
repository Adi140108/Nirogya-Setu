import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/admin_models.dart';
import '../../../core/services/admin_repository.dart';
import '../../../core/services/health_video_download_manager.dart';
import 'citizen_health_hub_screen.dart';

/// Plays one Health Hub video. Switching language swaps the video, title and
/// description. A downloaded language version plays from the device file, so
/// it works with no internet; otherwise it streams from YouTube.
class CitizenVideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String initialLanguage;

  const CitizenVideoPlayerScreen({super.key, required this.videoId, required this.initialLanguage});

  @override
  State<CitizenVideoPlayerScreen> createState() => _CitizenVideoPlayerScreenState();
}

class _CitizenVideoPlayerScreenState extends State<CitizenVideoPlayerScreen> {
  late String _language;
  YoutubePlayerController? _youtube;
  String? _youtubeLoadedId;
  VideoPlayerController? _local;
  String? _localPath;
  bool _localFailed = false;

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage;
  }

  @override
  void dispose() {
    _youtube?.close();
    _local?.dispose();
    super.dispose();
  }

  /// Keeps exactly one player active for the selected language version.
  void _syncPlayer(HealthVideoModel video, HealthVideoDownload state, bool isOnline) {
    final variant = video.variantFor(_language);

    if (state.isDownloaded && !_localFailed) {
      if (_localPath != state.localPath) {
        _youtube?.pauseVideo();
        _local?.dispose();
        _localPath = state.localPath;
        final controller = VideoPlayerController.file(File(state.localPath!));
        _local = controller;
        controller.initialize().then((_) {
          if (!mounted || _local != controller) return;
          controller.play();
          setState(() {});
        }).catchError((Object _) {
          if (!mounted || _local != controller) return;
          setState(() => _localFailed = true);
        });
        controller.addListener(() {
          if (mounted && _local == controller) setState(() {});
        });
      }
      return;
    }

    if (_local != null) {
      _local!.dispose();
      _local = null;
      _localPath = null;
    }
    if (!isOnline) return;

    if (_youtube == null) {
      _youtube = YoutubePlayerController.fromVideoId(
        videoId: variant.youtubeId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          // The package's default origin (www.youtube.com) makes YouTube reject the embed with error 152.
          origin: 'https://www.youtube-nocookie.com',
          showFullscreenButton: true,
          strictRelatedVideos: true,
          showVideoAnnotations: false,
        ),
      );
      _youtubeLoadedId = variant.youtubeId;
    } else if (_youtubeLoadedId != variant.youtubeId) {
      _youtube!.loadVideoById(videoId: variant.youtubeId);
      _youtubeLoadedId = variant.youtubeId;
    }
  }

  void _selectLanguage(String language) {
    if (language == _language) return;
    setState(() {
      _language = language;
      _localFailed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminRepository>();
    final downloads = context.watch<HealthVideoDownloadManager>();
    final video = admin.videos.where((v) => v.id == widget.videoId).firstOrNull;

    if (video == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('This video is no longer available.', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ),
      );
    }

    final variant = video.variantFor(_language);
    final state = downloads.stateFor(video.id, variant);
    _syncPlayer(video, state, downloads.isOnline);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(variant.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15)),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildPlayer(state, downloads.isOnline, video),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.translate_rounded, size: 16, color: AppColors.secondary),
                    SizedBox(width: 6),
                    Text('Watch in',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final v in video.variants)
                      ChoiceChip(
                        avatar: downloads.stateFor(video.id, v).isDownloaded
                            ? const Icon(Icons.offline_pin_rounded, size: 16, color: AppColors.riskGreen)
                            : null,
                        label: Text(v.language,
                            style: TextStyle(
                                fontSize: 12, fontWeight: v.language == variant.language ? FontWeight.bold : FontWeight.w500)),
                        selected: v.language == variant.language,
                        selectedColor: const Color(0xFFFFF3E0),
                        labelStyle: TextStyle(
                            color: v.language == variant.language ? AppColors.secondary : AppColors.textPrimary),
                        onSelected: (_) => _selectLanguage(v.language),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
                  child: Text(video.topic,
                      style: const TextStyle(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                Text(variant.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text(variant.description,
                    style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.45)),
                const SizedBox(height: 18),
                _buildDownloadPanel(video, variant, state, downloads),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayer(HealthVideoDownload state, bool isOnline, HealthVideoModel video) {
    if (state.isDownloaded && !_localFailed) {
      final controller = _local;
      if (controller == null || !controller.value.isInitialized) {
        return const AspectRatio(
          aspectRatio: 16 / 9,
          child: ColoredBox(color: Colors.black, child: Center(child: CircularProgressIndicator(color: Colors.white))),
        );
      }
      return _LocalVideoView(controller: controller);
    }

    if (isOnline && _youtube != null) {
      return YoutubePlayer(controller: _youtube!, aspectRatio: 16 / 9);
    }

    final downloadedLanguages = video.variants
        .where((v) => context.read<HealthVideoDownloadManager>().stateFor(video.id, v).isDownloaded)
        .map((v) => v.language)
        .toList();

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: const Color(0xFF1E293B),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white70, size: 36),
            const SizedBox(height: 10),
            Text(
              _localFailed
                  ? 'The saved file could not be played. Delete it and download again.'
                  : 'You are offline. Connect to the internet to watch, or download it to watch offline.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.35),
            ),
            if (downloadedLanguages.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Saved offline in: ${downloadedLanguages.join(', ')}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF69F0AE), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadPanel(
    HealthVideoModel video,
    VideoLanguageVariant variant,
    HealthVideoDownload state,
    HealthVideoDownloadManager downloads,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DownloadStatusPill(state: state),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.isDownloaded
                      ? '${variant.language} version saved on this device${state.sizeBytes != null ? ' (${(state.sizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MB)' : ''}'
                      : 'Save the ${variant.language} version to watch without internet',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          if (state.isDownloading) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: state.progress, backgroundColor: AppColors.primarySurface, color: AppColors.primary),
            const SizedBox(height: 4),
            Text('${(state.progress * 100).toInt()}% downloaded',
                style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
          ],
          if (state.error != null && !state.isDownloading) ...[
            const SizedBox(height: 8),
            Text(state.error!, style: const TextStyle(fontSize: 11.5, color: AppColors.riskRed)),
          ],
          const SizedBox(height: 12),
          if (state.isDownloaded)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.riskRed,
                side: const BorderSide(color: AppColors.riskRed),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Delete offline copy', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                setState(() => _localFailed = false);
                downloads.removeDownload(video.id, variant);
              },
            )
          else
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(state.isDownloading ? 'Downloading…' : 'Download ${variant.language} version',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              onPressed: state.isDownloading ? null : () => downloads.download(video.id, variant),
            ),
        ],
      ),
    );
  }
}

/// Minimal player UI for a downloaded file: tap to show controls, play/pause, scrub.
class _LocalVideoView extends StatefulWidget {
  final VideoPlayerController controller;

  const _LocalVideoView({required this.controller});

  @override
  State<_LocalVideoView> createState() => _LocalVideoViewState();
}

class _LocalVideoViewState extends State<_LocalVideoView> {
  bool _showControls = true;

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final value = c.value;
    return AspectRatio(
      aspectRatio: value.aspectRatio > 0 ? value.aspectRatio : 16 / 9,
      child: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: Colors.black, child: VideoPlayer(c)),
            if (_showControls) ...[
              Container(color: Colors.black26),
              Center(
                child: IconButton(
                  iconSize: 56,
                  color: Colors.white,
                  icon: Icon(value.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded),
                  onPressed: () => value.isPlaying ? c.pause() : c.play(),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                  color: Colors.black45,
                  child: Row(
                    children: [
                      const Icon(Icons.offline_pin_rounded, color: Color(0xFF69F0AE), size: 16),
                      const SizedBox(width: 6),
                      Text(_format(value.position), style: const TextStyle(color: Colors.white, fontSize: 11)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: VideoProgressIndicator(
                          c,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Color(0xFF48A999),
                            bufferedColor: Colors.white38,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_format(value.duration), style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
