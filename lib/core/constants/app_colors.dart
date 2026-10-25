import 'package:flutter/material.dart';

/// Nirogya Setu palette: terracotta + neem on mud-paper (see nirogya-setu-logo/DESIGN.md).
/// The legacy names are kept so every existing screen picks up the new look.
class AppColors {
  // Brand tokens
  static const Color mud = Color(0xFFF1E4CE);
  static const Color mud2 = Color(0xFFE8D6B8);
  static const Color paint = Color(0xFFFBF4E8);
  static const Color ink = Color(0xFF33200F);
  static const Color terra = Color(0xFFA8452A);
  static const Color terraDark = Color(0xFF7E3019);
  static const Color neem = Color(0xFF3B6634);
  static const Color neemDark = Color(0xFF2C4D27);
  static const Color haldi = Color(0xFFE3A126);

  // Brand Primary & Secondary
  static const Color primary = neem;
  static const Color primaryDark = neemDark;
  static const Color primaryLight = Color(0xFF6E9A5E);
  static const Color primarySurface = Color(0xFFE4E6CC); // neem wash on mud
  static const Color primaryGreen = neemDark;
  static const Color emergencyRed = Color(0xFFB23A22);

  static const Color secondary = terra;
  static const Color secondaryLight = haldi;
  static const Color secondarySurface = Color(0xFFF3DCC4);

  // Health Risk Category Colors
  static const Color riskGreen = neem;
  static const Color riskGreenSurface = Color(0xFFE4E9CF);
  static const Color riskYellow = Color(0xFFB7780C);
  static const Color riskYellowSurface = Color(0xFFF7E6C2);
  static const Color riskRed = Color(0xFFB23A22);
  static const Color riskRedSurface = Color(0xFFF4D6C8);

  // Sync Status Colors
  static const Color syncSynced = neem;
  static const Color syncPending = terra;
  static const Color syncLocal = Color(0xFF6B5443);

  // Neutral Colors
  static const Color background = mud;
  static const Color surface = paint;
  static const Color textPrimary = ink;
  static const Color textSecondary = Color(0xFF6B5443);
  static const Color textMuted = Color(0xFF9A8571);
  static const Color divider = Color(0xFFE2D2B6);
  static const Color border = Color(0xFFD5C1A0);

  // Role Accent Colors
  static const Color roleAsha = neem;
  static const Color roleDoctor = neemDark;
  static const Color rolePatient = neem;
}
