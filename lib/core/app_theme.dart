import 'package:flutter/material.dart';

class AppTheme {
  // Deep Night Obsidian & Cockpit Void
  static const Color background = Color(0xFF090A13);
  static const Color surfaceDark = Color(0xFF121422);
  static const Color surfaceElevated = Color(0xFF1A1C30);
  static const Color surfaceGlass = Color(0x3325284B);

  // Neon Glow Accents (Inspired by futuristic car cockpits)
  static const Color neonCyan = Color(0xFF00F2FE);
  static const Color electricBlue = Color(0xFF4FACFE);
  static const Color neonPurple = Color(0xFF9D4EDD);
  static const Color neonPink = Color(0xFFFF007F);
  static const Color carAmber = Color(0xFFFFB703);
  static const Color carNeonGreen = Color(0xFF00F5A0);
  static const Color textMuted = Color(0xFF8E95AF);

  // Cockpit Gradients
  static const LinearGradient carCockpitGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF07080F),
      Color(0xFF131028),
      Color(0xFF0A1526),
    ],
  );

  static const LinearGradient cyanPurpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonCyan, neonPurple],
  );

  static const LinearGradient neonPinkOrange = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonPink, carAmber],
  );

  static const LinearGradient carSpeedGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [carNeonGreen, neonCyan, neonPurple],
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: neonCyan,
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: neonPurple,
        tertiary: carAmber,
        surface: surfaceDark,
        onSurface: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 8,
        shadowColor: neonCyan.withAlpha(40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withAlpha(20), width: 1),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: neonCyan,
        inactiveTrackColor: Colors.white.withAlpha(30),
        thumbColor: Colors.white,
        overlayColor: neonCyan.withAlpha(60),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        trackHeight: 4,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
        bodyLarge: TextStyle(color: Colors.white, fontSize: 15),
        bodyMedium: TextStyle(color: textMuted, fontSize: 13),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  // Neon glowing box decoration helper
  static BoxDecoration neonBoxDecoration({
    Color? glowColor,
    Color? surfaceColor,
    double radius = 18,
    bool showBorder = true,
  }) {
    final glow = glowColor ?? neonCyan;
    return BoxDecoration(
      color: surfaceColor ?? surfaceDark,
      borderRadius: BorderRadius.circular(radius),
      border: showBorder ? Border.all(color: glow.withAlpha(70), width: 1.2) : null,
      boxShadow: [
        BoxShadow(
          color: glow.withAlpha(35),
          blurRadius: 16,
          spreadRadius: 1,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Glass card decoration
  static BoxDecoration glassBoxDecoration({
    double radius = 16,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: surfaceGlass,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? Colors.white.withAlpha(25),
        width: 1,
      ),
    );
  }
}
