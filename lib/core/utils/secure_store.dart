import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:homecare_app/core/utils/app_logger.dart';

/// Secure storage for auth tokens.
///
/// Tokens are kept in the iOS Keychain / Android EncryptedSharedPreferences
/// instead of plain SharedPreferences. All methods fail soft (return null /
/// no-op) so a storage hiccup can never crash the app — at worst the user
/// signs in again.
class SecureStore {
  const SecureStore._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e, s) {
      AppLogger.e('SecureStore.write failed', e, s);
    }
  }

  static Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e, s) {
      AppLogger.e('SecureStore.read failed', e, s);
      return null;
    }
  }

  static Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e, s) {
      AppLogger.e('SecureStore.delete failed', e, s);
    }
  }
}
