import 'package:flutter/foundation.dart';

/// Configuración centralizada de endpoints y parámetros globales.
@immutable
class AppConfig {
  AppConfig._({required this.apiBaseUrl, required this.wsDashboardUrl});

  /// URL base para peticiones REST.
  final Uri? apiBaseUrl;

  /// URL del WebSocket del dashboard.
  final Uri? wsDashboardUrl;

  /// Carga configuración desde variables `--dart-define`.
  factory AppConfig.fromEnvironment() {
    final String apiBaseRaw = const String.fromEnvironment('API_BASE_URL');
    final String wsBaseRaw = const String.fromEnvironment(
      'WS_URL',
      defaultValue: '',
    );

    Uri? parseUri(String raw) {
      if (raw.isEmpty) return null;
      try {
        final uri = Uri.parse(raw);
        if (!uri.hasScheme) return null;
        return uri;
      } catch (_) {
        return null;
      }
    }

    return AppConfig._(
      apiBaseUrl: parseUri(apiBaseRaw),
      wsDashboardUrl: parseUri(wsBaseRaw),
    );
  }

  /// Construye una ruta relativa a la API base.
  Uri? resolveApiPath(String path) {
    if (apiBaseUrl == null) return null;
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return apiBaseUrl!.resolve(normalized);
  }

  /// Determina si existe configuración de WebSocket.
  bool get hasWebSocket => wsDashboardUrl != null;

  /// Configuración por defecto pensada para entornos locales.
  static AppConfig fallback() {
    return AppConfig._(
      apiBaseUrl: Uri.parse('http://localhost:8000/api/'),
      wsDashboardUrl: Uri.parse('ws://localhost:8000/ws/dashboard'),
    );
  }
}
