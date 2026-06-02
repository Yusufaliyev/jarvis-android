import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_service.dart';

class EnhancedAuthService {
  static const _pinKey = 'app_pin_set';
  static const _otpKey = 'current_otp';
  static const _otpTimeKey = 'otp_time';
  static const _otpValidityMs = 300000; // 5 minutes
  static const _maxAttempts = 5;
  static const _lockoutDurationMs = 900000; // 15 minutes
  static const _lockoutKey = 'auth_lockout_time';
  static const _attemptsKey = 'failed_attempts';

  // ========== PIN Management ==========
  static Future<void> setPin(String pin) async {
    if (pin.length < 4) throw Exception('PIN must be at least 4 digits');
    
    try {
      await SecureStorageService.setPin(pin);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_pinKey, true);
      print('✅ PIN set successfully');
    } catch (e) {
      print('❌ PIN setup error: $e');
      rethrow;
    }
  }

  static Future<bool> verifyPin(String pin) async {
    try {
      // Check lockout status
      if (await _isLockedOut()) {
        throw Exception('Too many failed attempts. Try again later.');
      }

      final saved = await SecureStorageService.getPin();
      
      if (saved == null) {
        return true; // No PIN set
      }

      if (pin == saved) {
        await _resetAttempts();
        return true;
      } else {
        await _recordFailedAttempt();
        return false;
      }
    } catch (e) {
      print('❌ PIN verification error: $e');
      return false;
    }
  }

  static Future<bool> hasPin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_pinKey) ?? false;
    } catch (e) {
      print('❌ PIN check error: $e');
      return false;
    }
  }

  static Future<void> removePin() async {
    try {
      await SecureStorageService.removePin();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pinKey);
      await _resetAttempts();
      print('✅ PIN removed');
    } catch (e) {
      print('❌ PIN removal error: $e');
      rethrow;
    }
  }

  // ========== OTP Management ==========
  static Future<String> generateOtp() async {
    try {
      final otp = (100000 + Random().nextInt(900000)).toString();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_otpKey, otp);
      await prefs.setInt(_otpTimeKey, DateTime.now().millisecondsSinceEpoch);
      
      print('✅ OTP generated: $otp');
      return otp;
    } catch (e) {
      print('❌ OTP generation error: $e');
      rethrow;
    }
  }

  static Future<bool> verifyOtp(String otp) async {
    try {
      if (await _isLockedOut()) {
        throw Exception('Too many failed attempts. Try again later.');
      }

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_otpKey) ?? '';
      final time = prefs.getInt(_otpTimeKey) ?? 0;
      final diff = DateTime.now().millisecondsSinceEpoch - time;

      if (diff > _otpValidityMs) {
        await _recordFailedAttempt();
        return false; // OTP expired
      }

      if (otp == saved) {
        await prefs.remove(_otpKey);
        await prefs.remove(_otpTimeKey);
        await _resetAttempts();
        return true;
      } else {
        await _recordFailedAttempt();
        return false;
      }
    } catch (e) {
      print('❌ OTP verification error: $e');
      return false;
    }
  }

  static Future<int> getOtpRemainingTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final time = prefs.getInt(_otpTimeKey) ?? 0;
      final diff = DateTime.now().millisecondsSinceEpoch - time;
      final remaining = (_otpValidityMs - diff) ~/ 1000;
      return remaining > 0 ? remaining : 0;
    } catch (e) {
      return 0;
    }
  }

  // ========== Lockout & Attempt Management ==========
  static Future<void> _recordFailedAttempt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int attempts = prefs.getInt(_attemptsKey) ?? 0;
      attempts++;

      await prefs.setInt(_attemptsKey, attempts);

      if (attempts >= _maxAttempts) {
        await prefs.setInt(_lockoutKey, DateTime.now().millisecondsSinceEpoch);
        print('⚠️ Account locked due to too many failed attempts');
      }
    } catch (e) {
      print('❌ Attempt recording error: $e');
    }
  }

  static Future<void> _resetAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_attemptsKey);
      await prefs.remove(_lockoutKey);
    } catch (e) {
      print('❌ Attempt reset error: $e');
    }
  }

  static Future<bool> _isLockedOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lockoutTime = prefs.getInt(_lockoutKey) ?? 0;
      
      if (lockoutTime == 0) return false;

      final diff = DateTime.now().millisecondsSinceEpoch - lockoutTime;
      
      if (diff >= _lockoutDurationMs) {
        await _resetAttempts();
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<int> getRemainingLockoutTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lockoutTime = prefs.getInt(_lockoutKey) ?? 0;
      
      if (lockoutTime == 0) return 0;

      final diff = DateTime.now().millisecondsSinceEpoch - lockoutTime;
      final remaining = (_lockoutDurationMs - diff) ~/ 1000;
      
      return remaining > 0 ? remaining : 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<int> getFailedAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_attemptsKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }
}