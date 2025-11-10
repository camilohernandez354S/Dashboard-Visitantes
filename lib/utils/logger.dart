import 'package:flutter/foundation.dart';

/// Niveles básicos para logging interno.
enum LogLevel { debug, info, warning, error }

/// Logger centralizado con emojis consistentes.
class AppLogger {
  const AppLogger._();

  static void debug(String message, {String tag = 'App'}) =>
      _log(LogLevel.debug, message, tag);

  static void info(String message, {String tag = 'App'}) =>
      _log(LogLevel.info, message, tag);

  static void warn(String message, {String tag = 'App'}) =>
      _log(LogLevel.warning, message, tag);

  static void error(String message, {String tag = 'App', Object? err}) =>
      _log(LogLevel.error, err != null ? '$message → $err' : message, tag);

  static void _log(LogLevel level, String message, String tag) {
    if (kReleaseMode && level == LogLevel.debug) return;

    final emoji = switch (level) {
      LogLevel.debug => '🟦',
      LogLevel.info => '🟢',
      LogLevel.warning => '🟠',
      LogLevel.error => '🔴',
    };

    debugPrint('$emoji [$tag] $message');
  }
}
