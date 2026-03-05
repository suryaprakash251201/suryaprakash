import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeMode { light, dark, oled }

class AppTheme {
  // ─── Premium Color Palette (Stitch-Inspired) ───
  static const _primaryLight = Color(0xFF4A56E2);
  static const _primaryDark = Color(0xFF6A7BFF);
  static const _secondaryDark = Color(0xFF2CE6C8);

  // Gradient Colors
  static const gradientStart = Color(0xFF4A56E2);
  static const gradientEnd = Color(0xFF12C2FF);
  static const gradientAccent = Color(0xFF2CE6C8);

  // Surface colors
  static const _surfaceLight = Color(0xFF0F1223);
  static const _surfaceDark = Color(0xFF121212);
  static const _surfaceOled = Color(0xFF000000);
  static const _cardDark = Color(0xFF1A1F37);
  static const _cardOled = Color(0xFF0D0D0D);

  // ─── Glassmorphism Decoration Builder ───
  static BoxDecoration glassmorphicCard({
    required bool isDark,
    Color? borderColor,
    double borderRadius = 20,
    double opacity = 0.08,
  }) {
    return BoxDecoration(
      color: isDark
          ? Colors.white.withValues(alpha: opacity)
          : Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ??
            (isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05)),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // ─── Gradient Decoration ───
  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [gradientStart, gradientEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // ─── Text Theme ───
  static TextTheme get _textTheme {
    return GoogleFonts.ubuntuTextTheme();
  }

  // ─── Light Theme ───
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryLight,
        brightness: Brightness.light,
      ),
      textTheme: _textTheme,
      scaffoldBackgroundColor: const Color(0xFFF3F0FF),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: const Color(0xFFF3F0FF),
        titleTextStyle: GoogleFonts.ubuntu(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryLight,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: _primaryLight.withValues(alpha: 0.15),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.ubuntu(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  // ─── Dark Theme ───
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: _primaryDark,
      textTheme: _textTheme.apply(bodyColor: Colors.white70),
      scaffoldBackgroundColor: _surfaceDark,
      cardTheme: CardThemeData(
        color: _cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: _surfaceDark,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: GoogleFonts.ubuntu(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _secondaryDark,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _cardDark,
        surfaceTintColor: Colors.transparent,
        indicatorColor: _primaryDark.withValues(alpha: 0.2),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.ubuntu(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ─── OLED Black Theme ───
  static ThemeData get oled {
    final darkTheme = dark;
    return darkTheme.copyWith(
      scaffoldBackgroundColor: _surfaceOled,
      cardTheme: darkTheme.cardTheme.copyWith(color: _cardOled),
      appBarTheme: darkTheme.appBarTheme.copyWith(
        backgroundColor: _surfaceOled,
      ),
      navigationBarTheme: darkTheme.navigationBarTheme.copyWith(
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: darkTheme.bottomNavigationBarTheme.copyWith(
        backgroundColor: _surfaceOled,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF0A0A0A)),
      drawerTheme: const DrawerThemeData(backgroundColor: _surfaceOled),
    );
  }

  // ─── Get ThemeData by mode ───
  static ThemeData getTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return light;
      case AppThemeMode.dark:
        return dark;
      case AppThemeMode.oled:
        return oled;
    }
  }
}
