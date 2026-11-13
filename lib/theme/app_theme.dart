import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // definition ng mga custom colors used
  static const Color background = Color(0xFF12100E);
  static const Color surface = Color(0xFF1C1916);
  static const Color surfaceElevated = Color(0xFF25211D);
  static const Color surfaceMuted = Color(0xFF161411);

  static const Color border = Color(0xFF332D26);
  static const Color borderSubtle = Color(0xFF26211C);

  static const Color terracotta = Color(0xFFE09F5A);
  static const Color terracottaLight = Color(0xFFEBAC6C);
  static const Color terracottaDark = Color(0xFFC78440);

  static const Color sage = Color(0xFF7D8D70);
  static const Color sageLight = Color(0xFF90A183);

  static const Color wheat = Color(0xFFD8B677);
  static const Color plum = Color(0xFFB09EA7);
  static const Color rose = Color(0xFFC96E54);

  static const Color textPrimary = Color(0xFFF5EFE6);
  static const Color textSecondary = Color(0xFF9C9286);
  static const Color textTertiary = Color(0xFF6E655B);

  static final List<String> binderColors = [
    '0xFF3B82F6', // Blue
    '0xFF10B981', // Emerald
    '0xFFEC4899', // Pink
    '0xFFF59E0B', // Amber
    '0xFF8B5CF6', // Purple
    '0xFFE09F5A', // Terracotta
    '0xFF7D8D70', // Sage
  ];

  // definition ng mga custom text styles
  static TextStyle serifHeading({
    double fontSize = 22,
    FontWeight fontWeight = FontWeight.w600,
    FontStyle fontStyle = FontStyle.normal,
    Color color = textPrimary,
  }) {
    return GoogleFonts.newsreader(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      letterSpacing: -0.2,
    );
  }

  static TextStyle serif({
    double fontSize = 22,
    FontWeight fontWeight = FontWeight.w600,
    FontStyle fontStyle = FontStyle.normal,
    Color color = textPrimary,
  }) => serifHeading(
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    color: color,
  );

  static TextStyle serifItalic({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w400,
    Color color = textPrimary,
  }) {
    return GoogleFonts.newsreader(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: FontStyle.italic,
      color: color,
    );
  }

  static TextStyle overline({
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w700,
    Color color = textSecondary,
    double letterSpacing = 1.6,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle sans({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = textPrimary,
    double? height,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: terracotta,
      colorScheme: const ColorScheme.dark(
        primary: terracotta,
        secondary: sage,
        surface: surface,
        onSurface: textPrimary,
      ),
      dividerColor: border,
      textTheme: TextTheme(
        headlineLarge: serifHeading(fontSize: 28, fontWeight: FontWeight.bold),
        headlineMedium: serifHeading(fontSize: 24, fontWeight: FontWeight.bold),
        headlineSmall: serifHeading(fontSize: 20, fontWeight: FontWeight.w600),
        titleLarge: serifHeading(fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: sans(fontSize: 15, fontWeight: FontWeight.w600),
        titleSmall: sans(fontSize: 13, fontWeight: FontWeight.w600),
        bodyLarge: sans(fontSize: 15),
        bodyMedium: sans(fontSize: 13),
        bodySmall: sans(fontSize: 11, color: textSecondary),
        labelLarge: overline(fontSize: 12),
        labelSmall: overline(fontSize: 10),
      ),
      useMaterial3: true,
    );
  }
}
