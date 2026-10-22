import 'package:flutter/material.dart';

/// Voice & Audio Assistant Service for Rural and Low-Literacy Villagers
/// Provides spoken text prompts, audio navigation hints, and voice narration modal.
class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  bool isVoiceGuidanceEnabled = true;

  void toggleVoiceGuidance() {
    isVoiceGuidanceEnabled = !isVoiceGuidanceEnabled;
  }

  /// Displays an accessible spoken-dialog card for low-literacy rural users
  void speakPrompt(BuildContext context, {required String title, required String hindiText, required String englishText}) {
    if (!isVoiceGuidanceEnabled) return;

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFF004D40),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2F1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.volume_up_rounded, color: Color(0xFF004D40), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hindiText,
                    style: const TextStyle(color: Color(0xFFFFF9C4), fontSize: 13),
                  ),
                  Text(
                    englishText,
                    style: const TextStyle(color: Color(0xFFB2DFDB), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
