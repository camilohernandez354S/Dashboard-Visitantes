import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema personalizado del Dashboard SENA
class AppTheme {
  // Colores institucionales SENA
  static const Color senaPrimary = Color(0xFF00A65A);
  static const Color senaBackground = Color(0xFFF6F9F4);
  static const Color cardWhite = Colors.white;

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: senaPrimary,
      primary: senaPrimary,
    ),
    scaffoldBackgroundColor: senaBackground,

    // Tema de tarjetas
    cardTheme: CardThemeData(
      color: cardWhite,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),

    // Tipografía profesional
    textTheme: GoogleFonts.robotoTextTheme().copyWith(
      titleLarge: GoogleFonts.roboto(
        fontWeight: FontWeight.w700,
        fontSize: 24,
        color: const Color(0xFF2B2B2B),
      ),
      titleMedium: GoogleFonts.roboto(
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: const Color(0xFF2B2B2B),
      ),
      bodyLarge: GoogleFonts.roboto(
        fontSize: 16,
        color: const Color(0xFF2B2B2B),
      ),
      bodyMedium: GoogleFonts.roboto(
        fontSize: 14,
        color: const Color(0xFF555555),
      ),
    ),

    // AppBar personalizado
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFE8F3E8),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.black87,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.black87),
    ),

    // Botón flotante
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: senaPrimary,
      foregroundColor: Colors.white,
      elevation: 6,
    ),
  );
}
