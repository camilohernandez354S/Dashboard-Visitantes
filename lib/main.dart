import 'dart:ui';
import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';

void main() {
  // Capturar errores de Flutter y mostrarlos en consola
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
  };

  // Capturar errores no manejados de la plataforma
  PlatformDispatcher.instance.onError = (error, stack) {
    // ignore: avoid_print
    print('❌ Uncaught error: $error');
    // ignore: avoid_print
    print(stack);
    return true;
  };

  runApp(const DashboardVisitantesApp());
}

class DashboardVisitantesApp extends StatelessWidget {
  const DashboardVisitantesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashboard Visitantes SENA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const DashboardScreen(),
    );
  }
}
