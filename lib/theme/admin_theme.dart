import 'package:flutter/material.dart';

/// Paleta y estilos modernos con colores intuitivos y creativos para personal administrativo.
class AdminTheme {
  const AdminTheme._();

  // Paleta de azules (de oscuro a claro)
  static const Color stratos = Color(0xFF001B48);        // Azul muy oscuro - para textos importantes
  static const Color regalBlue = Color(0xFF02457A);     // Azul profundo - para AppBar y elementos principales
  static const Color bondiBlue = Color(0xFF018ABE);    // Azul vibrante - para botones y acciones
  static const Color morningGlory = Color(0xFF97CADB); // Azul claro suave - para fondos de tarjetas
  static const Color botticelli = Color(0xFFD6E8EE);    // Azul muy claro - para fondo general

  // Colores principales (usando la paleta azul)
  static const Color background = botticelli;
  static const Color appBar = regalBlue;
  static const Color primaryBlue = bondiBlue;
  
  // Colores semánticos (combinando azul con toques de color para diferenciación)
  static const Color successGreen = Color(0xFF2E7D32);  // Verde para éxito/entradas
  static const Color warningAmber = Color(0xFFF57C00);   // Naranja para advertencias/salidas
  static const Color infoTeal = bondiBlue;               // Azul para información
  static const Color accentLime = Color(0xFF4CAF50);    // Verde claro para acentos

  // Colores de texto (mejor contraste y legibilidad)
  static const Color textDark = stratos;                // Texto principal - azul muy oscuro
  static const Color textMuted = Color(0xFF5A6C7D);     // Texto secundario - azul grisáceo
  static const Color panelBorder = morningGlory;        // Bordes suaves - azul claro
  
  // Colores adicionales para mejor contraste
  static const Color cardBackground = Color(0xFFFFFFFF); // Fondo de tarjetas - blanco puro
  static const Color shadowLight = Color(0x0A000000);    // Sombra muy sutil minimalista

  static ThemeData buildTheme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: accentLime,
        surface: cardBackground,
        brightness: Brightness.light,
      ),
      fontFamily: 'Roboto',
      textTheme: TextTheme(
        displayLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textDark,
          letterSpacing: -0.5,
        ),
        displayMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textDark,
          letterSpacing: -0.5,
        ),
        titleLarge: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textDark,
          letterSpacing: -0.3,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textDark,
          height: 1.5,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textDark,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textMuted,
          height: 1.4,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBar,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: panelBorder.withOpacity(0.5), width: 1),
        ),
        shadowColor: shadowLight,
      ),
    );
  }
  
  // Sombras minimalistas - una sola sombra muy sutil
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: shadowLight,
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: shadowLight,
      blurRadius: 4,
      offset: const Offset(0, 1),
      spreadRadius: 0,
    ),
  ];
}
