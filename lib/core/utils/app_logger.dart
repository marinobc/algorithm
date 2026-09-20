import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

/// Production-ready logger service providing filterable logging without direct CLI stdout pollution.
class AppLogger {
  static void d(
    String tag,
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _log(LogLevel.debug, tag, message, error, stackTrace);
  }

  static void i(
    String tag,
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _log(LogLevel.info, tag, message, error, stackTrace);
  }

  static void w(
    String tag,
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _log(LogLevel.warning, tag, message, error, stackTrace);
  }

  static void e(
    String tag,
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _log(LogLevel.error, tag, message, error, stackTrace);
  }

  static void _log(
    LogLevel level,
    String tag,
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    // In production/release builds, suppress debug and info logs
    if (kReleaseMode && (level == LogLevel.debug || level == LogLevel.info)) {
      return;
    }

    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final levelStr = level.name.toUpperCase().padRight(5);
    final formattedMessage = '[$timestamp][$levelStr][$tag] $message';

    if (kDebugMode) {
      debugPrint(formattedMessage);
      if (error != null) {
        debugPrint('  Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('  StackTrace:\n$stackTrace');
      }
    }
  }
}
