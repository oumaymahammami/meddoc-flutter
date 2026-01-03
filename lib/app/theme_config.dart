import 'package:flutter/material.dart';

class AppTheme {
  // Premium Medical Color Palette
  static const Color primaryTeal = Color(0xFF00BFA5);
  static const Color primaryBlue = Color(0xFF4FC3F7);
  static const Color softLavender = Color(0xFFB39DDB);
  static const Color mintGreen = Color(0xFF80CBC4);
  static const Color warmPeach = Color(0xFFFFAB91);
  static const Color lightLavender = Color(0xFFE1BEE7);
  static const Color skyBlue = Color(0xFF81D4FA);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4FC3F7), Color(0xFF00BFA5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lavenderGradient = LinearGradient(
    colors: [Color(0xFFB39DDB), Color(0xFFCE93D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFFAB91), Color(0xFFFFCC80)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient calmGradient = LinearGradient(
    colors: [Color(0xFF81D4FA), Color(0xFF80CBC4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glassmorphism
  static BoxDecoration glassCard({Color? color}) {
    return BoxDecoration(
      color: (color ?? Colors.white).withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.2),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  // Soft Shadow
  static List<BoxShadow> softShadow({Color? color}) {
    return [
      BoxShadow(
        color: (color ?? Colors.black).withValues(alpha: 0.08),
        blurRadius: 30,
        offset: const Offset(0, 10),
        spreadRadius: -5,
      ),
    ];
  }

  // Glow Effect
  static List<BoxShadow> glowEffect(Color color) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.4),
        blurRadius: 20,
        offset: const Offset(0, 5),
        spreadRadius: 2,
      ),
    ];
  }

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryTeal,
      brightness: Brightness.light,
      primary: primaryTeal,
      secondary: primaryBlue,
      surface: const Color(0xFFF8FAFB),
    ),
    scaffoldBackgroundColor: const Color(0xFFF8FAFB),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF2D3748),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2D3748),
        letterSpacing: -0.5,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A202C),
        letterSpacing: -1,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2D3748),
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2D3748),
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2D3748),
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Color(0xFF4A5568),
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Color(0xFF718096),
        height: 1.5,
      ),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryTeal,
      brightness: Brightness.dark,
      primary: primaryTeal,
      secondary: primaryBlue,
      surface: const Color(0xFF1A202C),
    ),
    scaffoldBackgroundColor: const Color(0xFF0F1419),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: const Color(0xFF1A202C),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFFE2E8F0),
    ),
  );
}

// Animation Durations
class AppAnimations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 400);
}

// Spacing Constants
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}
