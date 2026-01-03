import 'package:flutter/material.dart';

class AuthColors {
  // Brand colors (modern 2026 palette)
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDeep = Color(0xFF0F172A);
  static const Color primaryAccent = Color(0xFF22D3EE); // cyan accent
  static const Color primarySoft = Color(0xFFE0F2FE);

  // Semantic colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Neutral colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Colors.white;

  // Gradients
  static LinearGradient get primaryGradient => const LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get backgroundGradient => const LinearGradient(
    colors: [Color(0xFF0B1224), Color(0xFF0F172A), Color(0xFF0B1224)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient get glassGradient => LinearGradient(
    colors: [
      Colors.white.withValues(alpha: 0.85),
      Colors.white.withValues(alpha: 0.70),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxShadow get softGlow => BoxShadow(
    color: primary.withValues(alpha: 0.15),
    blurRadius: 40,
    spreadRadius: 4,
    offset: const Offset(0, 12),
  );

  static BoxShadow get thinBorder => BoxShadow(
    color: Colors.white.withValues(alpha: 0.6),
    blurRadius: 0,
    spreadRadius: 0.5,
  );
}

class AuthDimensions {
  static const double paddingXS = 8.0;
  static const double paddingSM = 12.0;
  static const double paddingMD = 16.0;
  static const double paddingLG = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 40.0;

  static const double radiusXS = 6.0;
  static const double radiusSM = 10.0;
  static const double radiusMD = 14.0;
  static const double radiusLG = 20.0;
  static const double radiusXL = 28.0;

  static const double inputHeight = 56.0;
  static const double buttonHeight = 52.0;
}
