import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors - Derived from a vibrant HSL palette
  // Pink-Magenta Core: H: 327, S: 82, L: 52
  static const Color primary = Color(0xFFE91E8C);
  static const Color primaryDark = Color(0xFFC4177A);
  static const Color primaryLight = Color(0xFFFF4DA6);
  static const Color primaryBg = Color(0x1AE91E8C); // Restored for compatibility
  static const Color accent = Color(0xFF6366F1); // Indigo accent for contrast
  
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color surface = Color(0xFFFFFFFF);

  // Surfaces & Backgrounds
  static const Color bgPrimary = Color(0xFFFFFFFF);
  static const Color bgSecondary = Color(0xFFF8FAFC);
  static const Color bgTertiary = Color(0xFFF1F5F9);
  static const Color surfaceGlass = Color(0xCCFFFFFF); // 80% opacity for glass effect

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  static const Color borderColor = Color(0xFFE2E8F0);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFFD946EF)], // Pink to Fuchsia
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x33FFFFFF),
      Color(0x0FFFFFFF),
    ],
  );

  // Text Theme
  static final TextTheme _textTheme = GoogleFonts.outfitTextTheme().copyWith(
    displayLarge: GoogleFonts.outfit(
        fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.5),
    displayMedium: GoogleFonts.outfit(
        fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.5),
    displaySmall: GoogleFonts.outfit(
        fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
    headlineMedium: GoogleFonts.outfit(
        fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
    titleLarge: GoogleFonts.outfit(
        fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
    bodyLarge: GoogleFonts.outfit(
        fontSize: 16, fontWeight: FontWeight.normal, color: textPrimary),
    bodyMedium: GoogleFonts.outfit(
        fontSize: 14, fontWeight: FontWeight.normal, color: textSecondary),
    labelLarge: GoogleFonts.outfit(
        fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
  );

  // Light Theme Definition
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: bgPrimary,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: bgSecondary,
      textTheme: _textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
            color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      cardTheme: CardThemeData(
        color: bgPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: const TextStyle(color: textMuted),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primary.withAlpha(26),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // --- Static Helpers for UI Components ---

  static InputDecoration inputDecoration({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: primary, size: 20),
      suffixIcon: suffixIcon,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 14),
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
      filled: true,
      fillColor: Colors.white.withAlpha(25),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 56),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 0,
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
  );

  // Dark Theme Colors
  static const Color darkBgPrimary = Color(0xFF0F172A);
  static const Color darkBgSecondary = Color(0xFF1E293B);
  static const Color darkBgTertiary = Color(0xFF334155);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextMuted = Color(0xFF64748B);
  static const Color darkBorderColor = Color(0xFF334155);

  static final TextTheme _darkTextTheme = GoogleFonts.outfitTextTheme().copyWith(
    displayLarge: GoogleFonts.outfit(
        fontSize: 32, fontWeight: FontWeight.bold, color: darkTextPrimary, letterSpacing: -0.5),
    displayMedium: GoogleFonts.outfit(
        fontSize: 28, fontWeight: FontWeight.bold, color: darkTextPrimary, letterSpacing: -0.5),
    displaySmall: GoogleFonts.outfit(
        fontSize: 24, fontWeight: FontWeight.bold, color: darkTextPrimary),
    headlineMedium: GoogleFonts.outfit(
        fontSize: 20, fontWeight: FontWeight.w600, color: darkTextPrimary),
    titleLarge: GoogleFonts.outfit(
        fontSize: 18, fontWeight: FontWeight.w600, color: darkTextPrimary),
    bodyLarge: GoogleFonts.outfit(
        fontSize: 16, fontWeight: FontWeight.normal, color: darkTextPrimary),
    bodyMedium: GoogleFonts.outfit(
        fontSize: 14, fontWeight: FontWeight.normal, color: darkTextSecondary),
    labelLarge: GoogleFonts.outfit(
        fontSize: 14, fontWeight: FontWeight.w600, color: darkTextPrimary),
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryLight,
        secondary: accent,
        surface: darkSurface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimary,
      ),
      scaffoldBackgroundColor: darkBgPrimary,
      textTheme: _darkTextTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: darkTextPrimary),
        titleTextStyle: TextStyle(
            color: darkTextPrimary, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: darkBorderColor, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBgTertiary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: const TextStyle(color: darkTextMuted),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkBgSecondary,
        indicatorColor: primary.withAlpha(40),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: darkTextSecondary),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        titleTextStyle: const TextStyle(color: darkTextPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        contentTextStyle: const TextStyle(color: darkTextSecondary, fontSize: 14),
      ),
    );
  }
}

