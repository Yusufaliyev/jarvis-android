// 📁 lib/services/enhanced_auth_service.dart — YANGILANGAN v2.5
// Eski PIN/OTP tizimiga biometrik qo'shildi
// O'zgargan qismlar: // ← NEW v2.5 deb belgilangan

import 'package:flutter/material.dart';
import 'biometric_auth_service.dart';
import 'auth_service.dart'; // mavjud PIN service

class EnhancedAuthService {
  static final _bio = BiometricAuthService();

  // ─── Ilovaga kirish — biometrik yoki PIN ───
  /// Qaytadi: true = kirish muvaffaqiyatli
  static Future<bool> authenticate(BuildContext context) async {
    // 1. Biometrik yoqilganmi?
    final bioEnabled = await _bio.isEnabled();

    if (bioEnabled) {
      // 2. Biometrik holat
      final status = await _bio.getStatus();

      if (status == BiometricStatus.available) {
        // 3. Biometrik bilan urinish
        final result = await _bio.authenticate();
        if (result.success) return true;

        // Doimiy lock — PIN ga o'tish
        if (result.status == BiometricStatus.permanentLockout) {
          return await _fallbackToPin(context);
        }

        // Boshqa xato — PIN fallback taklif qilish
        return await _offerPinFallback(context, result.message);
      }

      // Notavailable/notEnrolled — PIN ga o'tish
      return await _fallbackToPin(context);
    }

    // Biometrik o'chirilgan — to'g'ridan PIN
    return await _fallbackToPin(context);
  }

  // ─── PIN bilan kirish ───
  static Future<bool> _fallbackToPin(BuildContext context) async {
    final pin = await _showPinDialog(context);
    if (pin == null) return false;
    return await AuthService.verifyPin(pin);
  }

  // ─── PIN yoki biometrik taklif ───
  static Future<bool> _offerPinFallback(
      BuildContext context, String errorMsg) async {
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A1628),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tasdiqlash',
          style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(errorMsg, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 16),
          const Text('Davom etish uchun tanlang:',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'retry'),
            child: const Text('Qayta urinish',
              style: TextStyle(color: Color(0xFF00D4FF)))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'pin'),
            child: const Text('PIN kiriting',
              style: TextStyle(color: Colors.white54))),
        ],
      ),
    );

    if (choice == 'retry') {
      final result = await _bio.authenticate();
      return result.success;
    } else if (choice == 'pin') {
      return await _fallbackToPin(context);
    }
    return false;
  }

  // ─── PIN dialog ───
  static Future<String?> _showPinDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A1628),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('PIN kiriting',
          style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(color: Colors.white, letterSpacing: 8),
          decoration: InputDecoration(
            hintText: '••••',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00D4FF)),
            ),
            counterStyle: const TextStyle(color: Colors.white24),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Tasdiqlash',
              style: TextStyle(color: Color(0xFF00D4FF)))),
        ],
      ),
    );
  }
}


// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📁 lib/main.dart — Biometric integratsiya
// Splash/Auth screen ga qo'shing:
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
import 'screens/biometric_screen.dart';
import 'services/biometric_auth_service.dart';
import 'services/enhanced_auth_service.dart';

class SplashScreen extends StatefulWidget { ... }

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final bio = BiometricAuthService();
    final bioEnabled = await bio.isEnabled();
    final hasPin = await AuthService.hasPin();

    if (!hasPin && !bioEnabled) {
      // Yangi foydalanuvchi — setup
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => SetupScreen()));
      return;
    }

    if (bioEnabled) {
      // Biometrik screen ko'rsat
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => BiometricScreen(
          onSuccess: () => Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => HomeScreen())),
          onFallbackPin: () => Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => AuthScreen())),
        )));
    } else {
      // PIN screen
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => AuthScreen()));
    }
  }
}
*/


// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📁 settings_screen.dart ga qo'shish:
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
import '../widgets/biometric_settings_tile.dart';

// Xavfsizlik bo'limiga qo'shing:
_title('🔐 Biometrik Autentifikatsiya'),
BiometricSettingsTile(),
*/
