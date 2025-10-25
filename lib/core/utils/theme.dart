// lib/core/utils/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta clara (Pijama Surf)
  static const Color primary = Color(0xFF0077B6);
  static const Color primaryVariant = Color(0xFF0096C7);
  static const Color textDark = Color(0xFF222222);
  static const Color bg = Colors.white;
  static const Color bgMuted = Color(0xFFF5F5F5);

  // Paleta oscura (equivalentes)
  static const Color darkBg = Color(0xFF0E0F10);       // fondo base
  static const Color darkSurface = Color(0xFF151618);  // cards/appbar
  static const Color darkText = Color(0xFFEFEFEF);     // texto principal

  // -------- Light Theme --------
  static ThemeData get lightTheme {
    final base = ThemeData.light();
    final textTheme = GoogleFonts.latoTextTheme(base.textTheme).apply(
      bodyColor: textDark,
      displayColor: textDark,
    );

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.light,
        primary: primary,
        secondary: primaryVariant,
        surface: bg,
        onSurface: textDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: textDark,
          fontSize: 18,
          letterSpacing: 0.2,
        ),
        iconTheme: const IconThemeData(color: textDark),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
    );
  }

  // -------- Dark Theme --------
  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    final textTheme = GoogleFonts.latoTextTheme(base.textTheme).apply(
      bodyColor: darkText,
      displayColor: darkText,
    );

    return base.copyWith(
      scaffoldBackgroundColor: darkBg,
      textTheme: textTheme,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: primary,                // mantenemos azul de marca
        secondary: primaryVariant,
        surface: darkSurface,
        onSurface: darkText,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: darkText,
          fontSize: 18,
          letterSpacing: 0.2,
        ),
        iconTheme: const IconThemeData(color: darkText),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
    );
  }
}
