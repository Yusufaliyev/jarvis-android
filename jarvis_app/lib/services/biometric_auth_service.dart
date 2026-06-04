// 📁 lib/services/biometric_auth_service.dart
// JARVIS v2.5 — Biometric Authentication Service
// Supports: Fingerprint, Face ID, Iris
// Author: @Yusufaliyev

import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_service.dart';

// ─────────────────────────────────────────
// Biometrik holat modeli
// ─────────────────────────────────────────
enum BiometricStatus {
  available,        // Ishlatish mumkin
  notAvailable,     // Qurilma qo'llab-quvvatlamaydi
  notEnrolled,      // Biometrik sozlanmagan
  lockedOut,        // Vaqtinchalik bloklangan
  permanentLockout, // Doimiy bloklangan
  disabled,         // Foydalanuvchi o'chirgan
}

enum BiometricType {
  fingerprint,
  faceId,
  iris,
  multiple,
  none,
}

class BiometricResult {
  final bool success;
  final String message;
  final BiometricStatus status;

  const BiometricResult({
    required this.success,
    required this.message,
    required this.status,
  });
}

// ─────────────────────────────────────────
// Biometric Auth Service
// ─────────────────────────────────────────
class BiometricAuthService {
  static final BiometricAuthService _instance = BiometricAuthService._();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._();

  final LocalAuthentication _auth = LocalAuthentication();

  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricTypeKey = 'biometric_type';
  static const String _failedAttemptsKey = 'bio_failed_attempts';
  static const String _lockoutTimeKey = 'bio_lockout_time';

  static const int maxFailedAttempts = 5;
  static const int lockoutMinutes = 15;

  // ─── Qurilma imkoniyatlarini tekshirish ───
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  // ─── Mavjud biometrik turlarini olish ───
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final available = await _auth.getAvailableBiometrics();
      return available.map((b) {
        switch (b) {
          case BiometricType.fingerprint:
            return BiometricType.fingerprint;
          case BiometricType.face:
            return BiometricType.faceId;
          case BiometricType.iris:
            return BiometricType.iris;
          default:
            return BiometricType.none;
        }
      }).where((t) => t != BiometricType.none).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Biometrik turini aniqlash ───
  Future<BiometricType> getPrimaryBiometricType() async {
    final types = await getAvailableBiometrics();
    if (types.isEmpty) return BiometricType.none;
    if (types.length > 1) return BiometricType.multiple;
    return types.first;
  }

  // ─── Umumiy holat ───
  Future<BiometricStatus> getStatus() async {
    // Foydalanuvchi o'chirganmi?
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_biometricEnabledKey) ?? false;
    if (!enabled) return BiometricStatus.disabled;

    // Lockout tekshirish
    if (await _isLockedOut()) return BiometricStatus.lockedOut;

    // Qurilma tekshirish
    final supported = await isDeviceSupported();
    if (!supported) return BiometricStatus.notAvailable;

    final canCheck = await canCheckBiometrics();
    if (!canCheck) return BiometricStatus.notAvailable;

    // Biometrik sozlanganmi?
    final biometrics = await getAvailableBiometrics();
    if (biometrics.isEmpty) return BiometricStatus.notEnrolled;

    return BiometricStatus.available;
  }

  // ─── Biometrik autentifikatsiya ───
  Future<BiometricResult> authenticate({
    String reason = 'JARVIS ga kirish uchun biometrikni tasdiqlang',
  }) async {
    // Lockout tekshirish
    if (await _isLockedOut()) {
      final remaining = await _getLockoutRemaining();
      return BiometricResult(
        success: false,
        message: '🔒 $remaining daqiqa kutib turing',
        status: BiometricStatus.lockedOut,
      );
    }

    // Holat tekshirish
    final status = await getStatus();
    if (status == BiometricStatus.disabled) {
      return BiometricResult(
        success: false,
        message: 'Biometrik autentifikatsiya o\'chirilgan',
        status: BiometricStatus.disabled,
      );
    }
    if (status == BiometricStatus.notAvailable) {
      return BiometricResult(
        success: false,
        message: 'Qurilmangiz biometrikni qo\'llab-quvvatlamaydi',
        status: BiometricStatus.notAvailable,
      );
    }
    if (status == BiometricStatus.notEnrolled) {
      return BiometricResult(
        success: false,
        message: 'Telefon sozlamalarida biometrik qo\'shing',
        status: BiometricStatus.notEnrolled,
      );
    }

    // Autentifikatsiya
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,        // Fon rejimida ham ishlaydi
          biometricOnly: false,    // PIN fallback ruxsat
          sensitiveTransaction: true,
          useErrorDialogs: true,
        ),
      );

      if (authenticated) {
        await _resetFailedAttempts();
        return BiometricResult(
          success: true,
          message: '✅ Muvaffaqiyatli tasdiqlandi',
          status: BiometricStatus.available,
        );
      } else {
        await _recordFailedAttempt();
        return BiometricResult(
          success: false,
          message: 'Biometrik tasdiqlanmadi',
          status: BiometricStatus.available,
        );
      }
    } on PlatformException catch (e) {
      return _handlePlatformException(e);
    }
  }

  // ─── Xatolarni qayta ishlash ───
  BiometricResult _handlePlatformException(PlatformException e) {
    switch (e.code) {
      case auth_error.notAvailable:
        return BiometricResult(
          success: false,
          message: 'Biometrik sensor mavjud emas',
          status: BiometricStatus.notAvailable,
        );
      case auth_error.notEnrolled:
        return BiometricResult(
          success: false,
          message: 'Biometrik ma\'lumot sozlanmagan',
          status: BiometricStatus.notEnrolled,
        );
      case auth_error.lockedOut:
        _triggerLockout();
        return BiometricResult(
          success: false,
          message: 'Ko\'p urinishlar! $lockoutMinutes daqiqa kuting',
          status: BiometricStatus.lockedOut,
        );
      case auth_error.permanentlyLockedOut:
        return BiometricResult(
          success: false,
          message: 'Doimiy bloklangan. PIN ishlatng',
          status: BiometricStatus.permanentLockout,
        );
      default:
        return BiometricResult(
          success: false,
          message: 'Xatolik: ${e.message ?? "Noma\'lum"}',
          status: BiometricStatus.available,
        );
    }
  }

  // ─── Biometrikni yoqish/o'chirish ───
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  // ─── Lockout boshqarish ───
  Future<bool> _isLockedOut() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutTime = prefs.getInt(_lockoutTimeKey) ?? 0;
    if (lockoutTime == 0) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final lockoutEnd = lockoutTime + (lockoutMinutes * 60 * 1000);
    if (now >= lockoutEnd) {
      await _resetFailedAttempts();
      return false;
    }
    return true;
  }

  Future<int> _getLockoutRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutTime = prefs.getInt(_lockoutTimeKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final lockoutEnd = lockoutTime + (lockoutMinutes * 60 * 1000);
    final remaining = ((lockoutEnd - now) / 60000).ceil();
    return remaining > 0 ? remaining : 0;
  }

  Future<void> _recordFailedAttempt() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = (prefs.getInt(_failedAttemptsKey) ?? 0) + 1;
    await prefs.setInt(_failedAttemptsKey, attempts);
    if (attempts >= maxFailedAttempts) {
      await _triggerLockout();
    }
  }

  Future<void> _triggerLockout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lockoutTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _resetFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_failedAttemptsKey, 0);
    await prefs.setInt(_lockoutTimeKey, 0);
  }

  Future<int> getFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_failedAttemptsKey) ?? 0;
  }

  // ─── Biometrik turini ikonka sifatida olish ───
  Future<String> getBiometricIcon() async {
    final type = await getPrimaryBiometricType();
    switch (type) {
      case BiometricType.faceId:
        return '🫥'; // Face ID
      case BiometricType.fingerprint:
        return '👆'; // Fingerprint
      case BiometricType.iris:
        return '👁️'; // Iris
      case BiometricType.multiple:
        return '🔐'; // Multiple
      default:
        return '🔒';
    }
  }

  Future<String> getBiometricLabel() async {
    final type = await getPrimaryBiometricType();
    switch (type) {
      case BiometricType.faceId:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Barmoq izi';
      case BiometricType.iris:
        return 'Ko\'z tarki';
      case BiometricType.multiple:
        return 'Biometrik';
      default:
        return 'Biometrik';
    }
  }
}
