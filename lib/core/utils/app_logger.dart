import 'package:flutter/foundation.dart';

/// Release-safe logger.
///
/// In release builds every call is a no-op, so debug output — including
/// tokens, emails and API payloads — never reaches production logs.
/// Use this instead of `print(...)` everywhere.
class AppLogger {
  const AppLogger._();

  static void d(Object? message) {
    if (kDebugMode) debugPrint('🟦 $message');
  }

  static void i(Object? message) {
    if (kDebugMode) debugPrint('🟢 $message');
  }

  static void w(Object? message) {
    if (kDebugMode) debugPrint('🟠 $message');
  }

  static void e(Object? message, [Object? error, StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('🔴 $message');
      if (error != null) debugPrint('   error: $error');
      if (stack != null) debugPrint('   stack: $stack');
    }
  }
}
