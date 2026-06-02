import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_available_when_unlocked_this_device_only,
    ),
  );

  // PIN Storage (Encrypted)
  static Future<void> setPin(String pin) async {
    try {
      await _storage.write(key: 'app_pin', value: pin);
      print('✅ PIN stored securely');
    } catch (e) {
      print('❌ PIN storage error: $e');
      rethrow;
    }
  }

  static Future<String?> getPin() async {
    try {
      return await _storage.read(key: 'app_pin');
    } catch (e) {
      print('❌ PIN retrieval error: $e');
      return null;
    }
  }

  static Future<void> removePin() async {
    try {
      await _storage.delete(key: 'app_pin');
      print('✅ PIN removed');
    } catch (e) {
      print('❌ PIN removal error: $e');
    }
  }

  // API Keys Storage (Encrypted)
  static Future<void> setApiKey(String provider, String key) async {
    try {
      await _storage.write(key: '${provider}_api_key', value: key);
      print('✅ API key stored securely for $provider');
    } catch (e) {
      print('❌ API key storage error: $e');
      rethrow;
    }
  }

  static Future<String?> getApiKey(String provider) async {
    try {
      return await _storage.read(key: '${provider}_api_key');
    } catch (e) {
      print('❌ API key retrieval error: $e');
      return null;
    }
  }

  // Firebase Config Storage
  static Future<void> setFirebaseConfig(String key, String value) async {
    try {
      await _storage.write(key: 'firebase_$key', value: value);
    } catch (e) {
      print('❌ Firebase config storage error: $e');
    }
  }

  static Future<String?> getFirebaseConfig(String key) async {
    try {
      return await _storage.read(key: 'firebase_$key');
    } catch (e) {
      print('❌ Firebase config retrieval error: $e');
      return null;
    }
  }

  // Biometric Auth Token
  static Future<void> setBiometricToken(String token) async {
    try {
      await _storage.write(key: 'biometric_token', value: token);
    } catch (e) {
      print('❌ Biometric token storage error: $e');
    }
  }

  static Future<String?> getBiometricToken() async {
    try {
      return await _storage.read(key: 'biometric_token');
    } catch (e) {
      print('❌ Biometric token retrieval error: $e');
      return null;
    }
  }

  // Clear all sensitive data
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      print('✅ All secure storage cleared');
    } catch (e) {
      print('❌ Secure storage clear error: $e');
    }
  }
}