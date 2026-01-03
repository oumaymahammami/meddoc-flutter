/// 🎨 MedDoc Design System - Typography & Spacing

import 'package:flutter/material.dart';
import 'colors.dart';

class MedDocTypography {
  /// 📱 Title Styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800, // Bold
    height: 1.2,
    color: MedDocColors.neutral900,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700, // Bold
    height: 1.3,
    color: MedDocColors.neutral900,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700, // Bold
    height: 1.4,
    color: MedDocColors.neutral900,
  );

  /// 📄 Heading Styles (section headers)
  static const TextStyle headingLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600, // Semibold
    height: 1.4,
    color: MedDocColors.neutral900,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600, // Semibold
    height: 1.5,
    color: MedDocColors.neutral900,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600, // Semibold
    height: 1.5,
    color: MedDocColors.neutral900,
  );

  /// 📝 Body Styles (regular text)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500, // Medium
    height: 1.5,
    color: MedDocColors.neutral700,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500, // Medium
    height: 1.5,
    color: MedDocColors.neutral700,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500, // Medium
    height: 1.5,
    color: MedDocColors.neutral700,
  );

  /// 🏷️ Label Styles (input labels, captions)
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600, // Semibold
    height: 1.4,
    color: MedDocColors.neutral900,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600, // Semibold
    height: 1.4,
    color: MedDocColors.neutral700,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500, // Medium
    height: 1.4,
    color: MedDocColors.neutral500,
  );

  /// 💬 Helper Text / Caption
  static const TextStyle helperText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400, // Regular
    height: 1.4,
    color: MedDocColors.neutral500,
  );

  static const TextStyle captionSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400, // Regular
    height: 1.3,
    color: MedDocColors.neutral500,
  );

  /// 🔘 Button Text
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700, // Bold
    height: 1.5,
    color: Colors.white,
    letterSpacing: 0.3,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700, // Bold
    height: 1.5,
    color: Colors.white,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700, // Bold
    height: 1.5,
    color: Colors.white,
    letterSpacing: 0.1,
  );
}

class MedDocSpacing {
  /// 🔲 Spacing Scale (8px base unit)
  static const double xs = 4; // 4px
  static const double sm = 8; // 8px
  static const double md = 12; // 12px
  static const double lg = 16; // 16px
  static const double xl = 20; // 20px
  static const double xl2 = 24; // 24px
  static const double xl3 = 28; // 28px
  static const double xl4 = 32; // 32px
  static const double xl5 = 40; // 40px
  static const double xl6 = 48; // 48px

  /// 📐 Common Dimensions
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXL = 20;

  /// 📏 Input Field Dimensions
  static const double inputHeight = 48;
  static const double inputPadding = lg;

  /// 🔘 Button Dimensions
  static const double buttonHeight = 48;
  static const double buttonRadius = radiusLarge;
  static const double buttonPaddingHorizontal = xl;

  /// 📦 Card / Container Dimensions
  static const double cardRadius = radiusXL;
  static const double cardPadding = xl;
  static const double cardSpacing = lg;

  /// 🎯 Section Spacing
  static const double sectionSpacing = xl2;
  static const double fieldSpacing = lg;
  static const double helperTextSpacing = xs;
}

class MedDocShadows {
  /// 🌫️ Shadow Styles
  static const BoxShadow shadowSmall = BoxShadow(
    color: MedDocColors.shadowColor,
    blurRadius: 4,
    offset: Offset(0, 2),
  );

  static const BoxShadow shadowMedium = BoxShadow(
    color: MedDocColors.shadowColor,
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  static const BoxShadow shadowLarge = BoxShadow(
    color: MedDocColors.shadowColor,
    blurRadius: 12,
    offset: Offset(0, 8),
  );

  static const BoxShadow shadowXL = BoxShadow(
    color: MedDocColors.shadowColor,
    blurRadius: 16,
    offset: Offset(0, 12),
  );

  static const List<BoxShadow> cardShadow = [shadowSmall];
  static const List<BoxShadow> buttonShadow = [shadowMedium];
  static const List<BoxShadow> modalShadow = [shadowXL];
}

class MedDocBorders {
  /// 🔲 Border Styles
  static const BorderSide thin = BorderSide(
    color: MedDocColors.borderColor,
    width: 1,
  );

  static const BorderSide medium = BorderSide(
    color: MedDocColors.borderColor,
    width: 1.5,
  );

  static const BorderSide active = BorderSide(
    color: MedDocColors.primaryBlue,
    width: 2,
  );

  static const BorderSide error = BorderSide(
    color: MedDocColors.errorRed,
    width: 1.5,
  );

  static const BorderSide success = BorderSide(
    color: MedDocColors.successGreen,
    width: 1.5,
  );
}

class MedDocDuration {
  /// ⏱️ Animation Durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}
