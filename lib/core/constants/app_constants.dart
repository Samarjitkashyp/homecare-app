import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static const String appName = 'Absolute Choice Homecare';

  // Fallback used if .env is missing/unreadable, or BASE_URL isn't set.
  // Update .env's BASE_URL to point the app at a different backend
  // (no code change or rebuild-from-scratch needed — just hot restart).
  static const String _fallbackBaseUrl = 'http://3.6.237.64/homecare-backend/';

  static String get baseUrl {
    try {
      if (dotenv.isInitialized) {
        final envUrl = dotenv.env['BASE_URL']?.trim();
        if (envUrl != null && envUrl.isNotEmpty) return envUrl;
      }
    } catch (_) {
      // fall through to default
    }
    return _fallbackBaseUrl;
  }

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
  static const String userEmailKey = 'user_email';

  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';

  // ADL Values
  static const List<String> adlLevels = ['I', 'S', 'A', 'H'];
  static const Map<String, String> adlLevelMap = {
    'I': 'Independent',
    'S': 'Supervision',
    'A': 'Stand-by Assistance',
    'H': 'Hands On Assistance'
  };
}
