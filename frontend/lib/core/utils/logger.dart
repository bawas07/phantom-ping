import 'package:flutter/foundation.dart';

/// Simple logging utility for the application
/// Uses debug print in development and can be extended for production logging
class Logger {
  final String _tag;

  Logger(this._tag);

  /// Log debug information
  void debug(String message) {
    if (kDebugMode) {
      debugPrint('[$_tag] DEBUG: $message');
    }
  }

  /// Log informational messages
  void info(String message) {
    if (kDebugMode) {
      debugPrint('[$_tag] INFO: $message');
    }
  }

  /// Log warning messages
  void warning(String message) {
    if (kDebugMode) {
      debugPrint('[$_tag] WARNING: $message');
    }
  }

  /// Log error messages
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[$_tag] ERROR: $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }
  }
}
