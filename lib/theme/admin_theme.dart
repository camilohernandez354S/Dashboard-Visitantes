import 'package:flutter/material.dart';

/// Paleta y estilos base inspirados en AdminLTE v3.
class AdminTheme {
  const AdminTheme._();

  static const Color background = Color(0xFFF4F6F9);
  static const Color appBar = Color(0xFF3C8DBC);
  static const Color primaryBlue = Color(0xFF007BFF);
  static const Color successGreen = Color(0xFF28A745);
  static const Color warningAmber = Color(0xFFF39C12);
  static const Color infoTeal = Color(0xFF17A2B8);
  static const Color accentLime = Color(0xFF00A65A);

  static const Color textDark = Color(0xFF343A40);
  static const Color textMuted = Color(0xFF6C757D);
  static const Color panelBorder = Color(0xFFE0E3E9);

  static ThemeData buildTheme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: accentLime,
        surface: Colors.white,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme().apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: appBar,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
    );
  }
}
