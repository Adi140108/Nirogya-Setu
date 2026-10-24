import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Secondary
  static const Color primary = Color(0xFF00796B);       // Deep Healing Teal
  static const Color primaryDark = Color(0xFF004D40);
  static const Color primaryLight = Color(0xFF48A999);
  static const Color primarySurface = Color(0xFFE0F2F1); // Light mint wash
  static const Color primaryGreen = Color(0xFF064E3B);   // Citizen & ASHA deep emerald green
  static const Color emergencyRed = Color(0xFFDC2626);   // Urgent emergency red

  static const Color secondary = Color(0xFFE65100);     // Warm Ochre / Marigold
  static const Color secondaryLight = Color(0xFFFFB74D);
  static const Color secondarySurface = Color(0xFFFFF3E0);

  // Health Risk Category Colors
  static const Color riskGreen = Color(0xFF2E7D32);     // Normal / Routine
  static const Color riskGreenSurface = Color(0xFFE8F5E9);
  static const Color riskYellow = Color(0xFFF57F17);    // Moderate / Attention
  static const Color riskYellowSurface = Color(0xFFFFFDE7);
  static const Color riskRed = Color(0xFFC62828);       // High Urgency / Critical
  static const Color riskRedSurface = Color(0xFFFFEBEE);

  // Sync Status Colors
  static const Color syncSynced = Color(0xFF1B5E20);    // Synced with cloud
  static const Color syncPending = Color(0xFFE65100);   // Pending sync
  static const Color syncLocal = Color(0xFF455A64);     // Local only

  // Neutral Colors
  static const Color background = Color(0xFFF8FAF9);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFCBD5E1);

  // Role Accent Colors
  static const Color roleAsha = Color(0xFF00897B);      // Teal
  static const Color roleDoctor = Color(0xFF1565C0);    // Blue
  static const Color rolePatient = Color(0xFF6A1B9A);   // Purple
}
