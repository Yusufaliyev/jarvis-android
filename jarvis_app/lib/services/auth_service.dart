import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _pinKey = 'settings_pin';
  static const _otpKey = 'current_otp';
  static const _otpTimeKey = 'otp_time';

  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
  }

  static Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_pinKey) ?? '';
    if (saved.isEmpty) return true;
    return pin == saved;
  }

  static Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey)?.isNotEmpty ?? false;
  }

  static Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
  }

  static Future<String> generateOtp() async {
    final prefs = await SharedPreferences.getInstance();
    final otp = (100000 + Random().nextInt(900000)).toString();
    await prefs.setString(_otpKey, otp);
    await prefs.setInt(_otpTimeKey, DateTime.now().millisecondsSinceEpoch);
    return otp;
  }

  static Future<bool> verifyOtp(String otp) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_otpKey) ?? '';
    final time = prefs.getInt(_otpTimeKey) ?? 0;
    final diff = DateTime.now().millisecondsSinceEpoch - time;
    if (diff > 300000) return false;
    return otp == saved;
  }
}
