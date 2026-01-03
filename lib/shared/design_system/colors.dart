/// 🎨 MedDoc Design System - Colors
/// Premium healthcare color palette inspired by Doctolib/Zocdoc

import 'package:flutter/material.dart';

class MedDocColors {
  // 🔵 Primary Colors
  static const Color primaryBlue = Color(0xFF2E63D9); // Main brand blue
  static const Color primaryBlueDark = Color(0xFF1A47B5);
  static const Color primaryBlueLight = Color(0xFFEBF2FF);

  // 🟣 Secondary Colors (Accent)
  static const Color secondaryPurple = Color(
    0xFF8B5CF6,
  ); // Trust & Professional
  static const Color secondaryPurpleDark = Color(0xFF6D28D9);
  static const Color secondaryPurpleLight = Color(0xFFF3E8FF);

  // ✅ Success Colors
  static const Color successGreen = Color(0xFF10B981); // Positive actions
  static const Color successGreenDark = Color(0xFF059669);
  static const Color successGreenLight = Color(0xECFDF5);

  // ⚠️ Warning Colors
  static const Color warningAmber = Color(0xFFF59E0B); // Alerts
  static const Color warningAmberDark = Color(0xFFD97706);
  static const Color warningAmberLight = Color(0xFFFEF3C7);

  // ❌ Error Colors
  static const Color errorRed = Color(0xFFEF4444); // Errors
  static const Color errorRedDark = Color(0xFFDC2626);
  static const Color errorRedLight = Color(0xFFFEE2E2);

  // ⚫ Neutral Colors
  static const Color neutralBlack = Color(0xFF0F172A); // Text
  static const Color neutral900 = Color(0xFF111827); // Dark text
  static const Color neutral700 = Color(0xFF374151); // Secondary text
  static const Color neutral500 = Color(0xFF6B7280); // Helper text
  static const Color neutral300 = Color(0xFFD1D5DB); // Borders
  static const Color neutral100 = Color(0xFFF3F4F6); // Light bg
  static const Color neutral50 = Color(0xFFFAFAFC); // Very light bg
  static const Color white = Color(0xFFFFFFFF);

  // 🔵 Background Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, secondaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightGradient = LinearGradient(
    colors: [primaryBlueLight, secondaryPurpleLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 🟡 Status Colors
  static const Color pending = Color(0xFFF59E0B);
  static const Color completed = Color(0xFF10B981);
  static const Color disabled = Color(0xFFD1D5DB);

  // 📊 UI Elements
  static const Color borderColor = neutral300;
  static const Color dividerColor = neutral100;
  static const Color backgroundColor = neutral50;
  static const Color surfaceColor = white;
  static const Color shadowColor = Color(0x1A000000); // Black 10% opacity
}
