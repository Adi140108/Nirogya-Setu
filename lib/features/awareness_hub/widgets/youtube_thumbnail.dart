import 'package:flutter/material.dart';

/// YouTube thumbnail with a branded fallback when offline or unavailable.
class YoutubeThumbnail extends StatelessWidget {
  final String youtubeId;

  const YoutubeThumbnail({super.key, required this.youtubeId});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2C4D27), Color(0xFF3B6634)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(child: Icon(Icons.play_circle_outline_rounded, color: Colors.white70, size: 48)),
    );
    return Image.network(
      'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
      loadingBuilder: (context, child, progress) => progress == null ? child : fallback,
    );
  }
}
