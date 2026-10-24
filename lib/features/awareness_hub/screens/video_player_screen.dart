import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/awareness_content_model.dart';
import '../../../core/services/voice_service.dart';

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
  String _errorMessage = '';
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
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
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

  @override
  Widget build(BuildContext context) {
    final content = widget.content;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(content.title, style: const TextStyle(fontSize: 14)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_outlined),
            tooltip: 'Audio guidance',
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
        child: Column(
          children: [
            // Video Player Aspect Ratio Box
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isInitialized && _controller != null)
                    VideoPlayer(_controller!)
                  else if (_hasError)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            'Video playback error:\n$_errorMessage',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  else
                    const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),

                  // Overlay Play/Pause Button
                  if (_isInitialized && _controller != null)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
                        });
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: AnimatedOpacity(
                          opacity: _controller!.value.isPlaying ? 0.0 : 0.85,
                          duration: const Duration(milliseconds: 250),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _controller!.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Video Controls Progress Bar
            if (_isInitialized && _controller != null) ...[
              Container(
                color: const Color(0xFF1E293B),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    VideoProgressIndicator(
                      _controller!,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: AppColors.primary,
                        bufferedColor: Colors.white24,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _controller!.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
                            });
                          },
                        ),
                        Text(
                          '${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            _controller!.value.volume > 0 ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _controller!.setVolume(_controller!.value.volume > 0 ? 0.0 : 1.0);
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Offline Verification Badge & Metadata
            Expanded(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    // Offline Storage Verification Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isPlayingFromLocalFile ? const Color(0xFFE8F5E9) : const Color(0xFFE1F5FE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isPlayingFromLocalFile ? const Color(0xFF2E7D32) : const Color(0xFF0288D1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isPlayingFromLocalFile ? Icons.offline_pin_rounded : Icons.wifi_rounded,
                            color: _isPlayingFromLocalFile ? const Color(0xFF2E7D32) : const Color(0xFF0288D1),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isPlayingFromLocalFile
                                      ? 'Playing from Local Device Storage'
                                      : 'Streaming via Network',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: _isPlayingFromLocalFile ? const Color(0xFF1B5E20) : const Color(0xFF01579B),
                                  ),
                                ),
                                Text(
                                  _isPlayingFromLocalFile
                                      ? 'Zero mobile data consumed. Plays completely offline even with Wi-Fi & cellular disabled.'
                                      : 'Streamed live from health server. Tap download to save for offline use.',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      content.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Topic: ${content.topic} • Language: ${content.language}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      content.description,
                      style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textPrimary),
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.verified_outlined, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Source: ${content.source}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Clinical Review Date: ${content.reviewDate} • Version ${content.version}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
