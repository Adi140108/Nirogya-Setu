import 'package:flutter/material.dart';

/// Calm, high-contrast palette for field use (ASHA workers, rural citizens).
/// One brand colour (teal). Strong colour is reserved for triage red/yellow/green.
/// All text colours meet WCAG AA (>= 4.5:1) on [surface] and [background].
class AppColors {
  // Brand
  static const Color primary = Color(0xFF0F6E64);        // Teal, 6.0:1 on white
  static const Color primaryDark = Color(0xFF0A4F48);
  static const Color primaryLight = Color(0xFF4F9C93);
  static const Color primarySurface = Color(0xFFE8F3F1); // Selected / tinted backgrounds

  // Secondary is a muted amber, used sparingly for "needs attention" accents
  static const Color secondary = Color(0xFF8A5A00);
  static const Color secondaryLight = Color(0xFFD9A441);
  static const Color secondarySurface = Color(0xFFFBF3E3);

  // Triage. Always pair with an icon + word, never colour alone.
  static const Color riskGreen = Color(0xFF1E7B3C);
  static const Color riskGreenSurface = Color(0xFFE9F5EC);
  static const Color riskYellow = Color(0xFF8A5A00);     // Dark amber so text stays readable
  static const Color riskYellowSurface = Color(0xFFFFF6DB);
  static const Color riskRed = Color(0xFFB42318);
  static const Color riskRedSurface = Color(0xFFFDECEA);

  // Sync status
  static const Color syncSynced = riskGreen;
  static const Color syncPending = riskYellow;
  static const Color syncLocal = Color(0xFF5B6770);

  // Neutrals
  static const Color background = Color(0xFFF6F7F6);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A2421);
  static const Color textSecondary = Color(0xFF4A5652);
  static const Color textMuted = Color(0xFF66716D);
  static const Color divider = Color(0xFFE4E8E6);
  static const Color border = Color(0xFFD3D9D6);

  // Roles share the single brand colour to keep the interface quiet
  static const Color roleAsha = primary;
  static const Color roleDoctor = primary;
  static const Color rolePatient = primary;
}

/// 4pt spacing scale.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Standard screen padding.
  static const EdgeInsets screen = EdgeInsets.all(lg);
}

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double pill = 999;

  static final BorderRadius card = BorderRadius.circular(md);
  static final BorderRadius control = BorderRadius.circular(sm + 2);
}

/// Touch target sizes (Material minimum is 48dp).
class AppSizes {
  static const double minTouch = 48;
  static const double button = 52;
  static const double primaryButton = 56;
}
