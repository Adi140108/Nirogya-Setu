import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/awareness_content_model.dart';
import '../../../core/services/voice_service.dart';
import '../../shared/widgets/ui.dart';

class VideoPlayerScreen extends StatefulWidget {
  final AwarenessContentModel content;

  const VideoPlayerScreen({super.key, required this.content});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isPlayingFromLocalFile = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final content = widget.content;

      // 1. Prioritize playing from local device storage (100% offline verification!)
      if (content.localFilePath != null && content.localFilePath!.isNotEmpty) {
        final f = File(content.localFilePath!);
        if (await f.exists()) {
          _controller = VideoPlayerController.file(f);
          _isPlayingFromLocalFile = true;
        }
      }

      // 2. If no local file yet, check bundled asset fallback
      if (_controller == null && content.bundledAssetPath != null) {
        _controller = VideoPlayerController.asset(content.bundledAssetPath!);
        _isPlayingFromLocalFile = true;
      }

      // 3. Fallback to network stream if online
      if (_controller == null) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(content.remoteVideoUrl));
        _isPlayingFromLocalFile = false;
      }

      await _controller!.initialize();
      _controller!.addListener(() {
        if (mounted) setState(() {});
      });

      setState(() {
        _isInitialized = true;
      });

      _controller!.play();
    } catch (e) {
      debugPrint('VideoPlayerScreen: could not play ${widget.content.id}: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _togglePlay() {
    setState(() {
      _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
    });
  }

  void _toggleSound() {
    setState(() {
      _controller!.setVolume(_controller!.value.volume > 0 ? 0.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.content;
    final ready = _isInitialized && _controller != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(content.title),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.volume_up_outlined),
            label: const Text('Listen'),
            onPressed: () {
              VoiceService().speakPrompt(
                context,
                title: content.title,
                hindiText: 'Playing educational video on ${content.topic}. Fully available offline.',
                englishText: 'Playing educational video on ${content.topic}. Fully available offline.',
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape = constraints.maxWidth > constraints.maxHeight;
            if (landscape) {
              // Video would be taller than the screen: scroll everything, and cap
              // the video at the visible height.
              return ListView(
                children: [
                  _buildPlayer(ready, maxVideoHeight: constraints.maxHeight),
                  Padding(
                    padding: AppSpacing.screen,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _buildDetails(content),
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                _buildPlayer(ready),
                Expanded(
                  child: ListView(padding: AppSpacing.screen, children: _buildDetails(content)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlayer(bool ready, {double? maxVideoHeight}) {
    Widget video = AspectRatio(aspectRatio: 16 / 9, child: _buildVideoArea());
    if (maxVideoHeight != null) {
      video = Center(
        child: ConstrainedBox(constraints: BoxConstraints(maxHeight: maxVideoHeight), child: video),
      );
    }
    return ColoredBox(
      color: _playerBg,
      child: Column(
        children: [
          video,
          if (ready) _buildControls(),
        ],
      ),
    );
  }

  /// Dark player background. There is no dark surface token, so the darkest
  /// neutral token is reused here (see report).
  static const Color _playerBg = AppColors.textPrimary;

  Widget _buildVideoArea() {
    final ready = _isInitialized && _controller != null;
    final text = Theme.of(context).textTheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        if (ready)
          VideoPlayer(_controller!)
        else if (_hasError)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white, size: 28),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'This video could not play.',
                    textAlign: TextAlign.center,
                    style: text.titleSmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Check your internet, or save the video to your phone first.',
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: AppSpacing.md),
              Text('Loading video…', style: text.bodySmall?.copyWith(color: Colors.white)),
            ],
          ),

        // Tap anywhere on the video to play or pause.
        if (ready)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _togglePlay,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _controller!.value.isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    width: AppSizes.minTouch + AppSpacing.lg,
                    height: AppSizes.minTouch + AppSpacing.lg,
                    decoration: BoxDecoration(
                      color: _playerBg.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      _controller!.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: AppSizes.minTouch - AppSpacing.sm,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildControls() {
    final value = _controller!.value;
    final isPlaying = value.isPlaying;
    final hasSound = value.volume > 0;
    final buttonStyle = TextButton.styleFrom(
      foregroundColor: Colors.white,
      minimumSize: const Size(AppSizes.minTouch, AppSizes.button),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VideoProgressIndicator(
            _controller!,
            allowScrubbing: true,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            colors: VideoProgressColors(
              playedColor: AppColors.primaryLight,
              bufferedColor: Colors.white.withValues(alpha: 0.35),
              backgroundColor: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Text(
            '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  style: buttonStyle,
                  icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 28),
                  label: Text(isPlaying ? 'Pause' : 'Play'),
                  onPressed: _togglePlay,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextButton.icon(
                  style: buttonStyle,
                  icon: Icon(hasSound ? Icons.volume_up_rounded : Icons.volume_off_rounded, size: 28),
                  label: Text(hasSound ? 'Mute' : 'Unmute'),
                  onPressed: _toggleSound,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDetails(AwarenessContentModel content) {
    final text = Theme.of(context).textTheme;
    return [
        InfoCard(
          color: AppColors.primarySurface,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _isPlayingFromLocalFile ? Icons.offline_pin_rounded : Icons.wifi_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isPlayingFromLocalFile ? 'Playing from this phone' : 'Playing over the internet',
                      style: text.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _isPlayingFromLocalFile
                          ? 'No mobile data used. Works even with Wi-Fi and mobile data off.'
                          : 'This uses mobile data. Go back and tap "Save to watch offline" to keep it on your phone.',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(content.title, style: text.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text('${content.topic} · ${content.language}', style: text.bodySmall),
        const SizedBox(height: AppSpacing.md),
        Text(content.description, style: text.bodyMedium),
        const SectionHeader('About this video'),
        InfoCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Column(
            children: [
              InfoRow('Source', content.source),
              const Divider(),
              InfoRow('Last checked', content.reviewDate),
              const Divider(),
              InfoRow('Version', '${content.version}'),
            ],
          ),
        ),
    ];
  }
}
