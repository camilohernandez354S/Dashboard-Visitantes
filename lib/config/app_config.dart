import 'package:flutter/foundation.dart';

/// Configuración centralizada de endpoints y parámetros globales.
@immutable
class AppConfig {
  AppConfig._({
    required this.apiBaseUrl,
    required this.wsDashboardUrl,
    required this.reverbAppKey,
  });

  /// URL base para peticiones REST.
  final Uri? apiBaseUrl;

  /// URL del WebSocket del dashboard.
  final Uri? wsDashboardUrl;

  /// Clave de la aplicación Reverb (REVERB_APP_KEY).
  final String reverbAppKey;

  /// Carga configuración desde variables `--dart-define`.
  /// Si no se proporcionan, usa valores por defecto para el servidor local.
  ///
  /// NOTA: Laravel Reverb usa el protocolo Pusher.
  /// - HTTP API: http://localhost (puerto 80)
  /// - WebSocket: ws://localhost:80 (puerto 80)
  /// - REVERB_APP_KEY por defecto: 'local' (debe coincidir con .env del backend)
  factory AppConfig.fromEnvironment() {
    final String apiBaseRaw = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.139.237.174:8000',
    );
    final String wsBaseRaw = const String.fromEnvironment(
      'WS_URL',
      defaultValue: 'ws://10.139.237.174:8080',
    );
    final String reverbAppKey = const String.fromEnvironment(
      'REVERB_APP_KEY',
      defaultValue: '8c77ba6acf0de58189211e938930fe72',
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
      reverbAppKey: reverbAppKey,
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
  /// HTTP y WebSocket usan el mismo servidor pero diferentes protocolos.
  static AppConfig fallback() {
    return AppConfig._(
      apiBaseUrl: Uri.parse('http://10.139.237.174:8000'),
      wsDashboardUrl: Uri.parse('ws://10.139.237.174:8080'),
      reverbAppKey: '8c77ba6acf0de58189211e938930fe72',
    );
  }
}
