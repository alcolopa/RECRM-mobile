import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1E293B);
  static const Color secondaryColor = Color(0xFF334155);
  static const Color tertiaryColor = Color(0xFF0EA5E9);
  static const Color backgroundColor = Color(0xFFF7F9FB); // Base layer
  static const Color surfaceContainer = Color(0xFFECEEF0); // Inset
  static const Color surfaceLift = Color(0xFFFFFFFF); // Lift (Lowest surface)
  static const Color onSurface = Color(0xFF191C1E);
  static const Color onSurfaceVariant = Color(0xFF45464D);
  static const Color errorColor = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);

  // Obsidian Dark Palette
  static const Color obsidianBackground = Color(0xFF0B1326);
  static const Color obsidianSurface = Color(0xFF131B2E);
  static const Color obsidianSurfaceHigh = Color(0xFF222A3D);
  static const Color obsidianPrimary = Color(0xFF10B981); // Emerald
  static const Color obsidianOnSurface = Color(0xFFDAE2FD);
  static const Color obsidianOnSurfaceVariant = Color(0xFFBBCABF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: obsidianPrimary,
        secondary: Color(0xFF64748B),
        surface: backgroundColor,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        error: errorColor,
        errorContainer: errorContainer,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.manropeTextTheme().copyWith(
        displayLarge: GoogleFonts.manrope(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: obsidianPrimary,
        ),
        displayMedium: GoogleFonts.manrope(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: onSurface,
        ),
        headlineLarge: GoogleFonts.manrope(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: onSurface),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: onSurfaceVariant),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: obsidianPrimary, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: GoogleFonts.inter(color: onSurfaceVariant),
        errorStyle: GoogleFonts.inter(color: errorColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: obsidianPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: obsidianPrimary,
        secondary: Color(0xFFB7C8E1),
        surface: obsidianBackground,
        onSurface: obsidianOnSurface,
        onSurfaceVariant: obsidianOnSurfaceVariant,
        error: Color(0xFFFFB4AB),
      ),
      scaffoldBackgroundColor: obsidianBackground,
      textTheme: GoogleFonts.manropeTextTheme().copyWith(
        displayLarge: GoogleFonts.manrope(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: obsidianPrimary,
        ),
        displayMedium: GoogleFonts.manrope(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: obsidianOnSurface,
        ),
        headlineLarge: GoogleFonts.manrope(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: obsidianOnSurface,
        ),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: obsidianOnSurface),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: obsidianOnSurfaceVariant,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: obsidianSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: obsidianPrimary, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: obsidianPrimary,
          foregroundColor: Color(0xFF003824),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
