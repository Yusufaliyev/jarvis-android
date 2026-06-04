// 📁 lib/widgets/biometric_settings_tile.dart
// JARVIS v2.5 — Settings Screen uchun biometrik widget
// Bu widgetni settings_screen.dart ga qo'shing

import 'package:flutter/material.dart';
import '../services/biometric_auth_service.dart';

class BiometricSettingsTile extends StatefulWidget {
  const BiometricSettingsTile({Key? key}) : super(key: key);

  @override
  State<BiometricSettingsTile> createState() => _BiometricSettingsTileState();
}

class _BiometricSettingsTileState extends State<BiometricSettingsTile> {
  final _bio = BiometricAuthService();

  bool _enabled = false;
  bool _loading = true;
  bool _supported = false;
  String _label = 'Biometrik';
  String _icon = '🔐';
  BiometricStatus _status = BiometricStatus.disabled;

  static const _cyan = Color(0xFF00D4FF);
  static const _green = Color(0xFF00FF88);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _enabled = await _bio.isEnabled();
    _supported = await _bio.isDeviceSupported() && await _bio.canCheckBiometrics();
    _label = await _bio.getBiometricLabel();
    _icon = await _bio.getBiometricIcon();
    _status = await _bio.getStatus();
    setState(() => _loading = false);
  }

  Future<void> _toggle(bool value) async {
    if (!_supported && value) {
      _snack('Qurilmangiz biometrikni qo\'llab-quvvatlamaydi');
      return;
    }

    // Yoqishdan oldin bir marta tasdiqlash
    if (value) {
      final result = await _bio.authenticate(
        reason: 'Biometrik autentifikatsiyani yoqish uchun tasdiqlang',
      );
      if (!result.success) {
        _snack(result.message);
        return;
      }
    }

    await _bio.setEnabled(value);
    await _load();
    _snack(value
        ? '✅ $_label yoqildi!'
        : '$_label o\'chirildi');
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 2),
      backgroundColor: msg.contains('✅') ? _green : Colors.red.shade900,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: _enabled
              ? _cyan.withOpacity(0.3)
              : Colors.white.withOpacity(0.07),
        ),
        borderRadius: BorderRadius.circular(16),
        color: _enabled
            ? _cyan.withOpacity(0.04)
            : Colors.transparent,
      ),
      child: _loading
          ? const Center(child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: _cyan)))
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ─── Toggle row ───
              Row(children: [
                Text(_icon, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_label, style: const TextStyle(
                      color: Colors.white, fontSize: 15,
                      fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        color: _getStatusColor().withOpacity(0.7),
                        fontSize: 11),
                    ),
                  ],
                )),
                Switch.adaptive(
                  value: _enabled,
                  onChanged: _supported ? _toggle : null,
                  activeColor: _cyan,
                  inactiveThumbColor: Colors.white30,
                  inactiveTrackColor: Colors.white12,
                ),
              ]),

              // ─── Not supported warning ───
              if (!_supported) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withOpacity(0.2)),
                  ),
                  child: Row(children: const [
                    Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Expanded(child: Text(
                      'Qurilmangizda biometrik sensor topilmadi yoki sozlanmagan',
                      style: TextStyle(color: Colors.orange, fontSize: 11),
                    )),
                  ]),
                ),
              ],

              // ─── Enabled info ───
              if (_enabled && _supported) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _green.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    Icon(Icons.shield_outlined, color: _green, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      '$_label bilan JARVIS himoyalangan',
                      style: TextStyle(color: _green, fontSize: 11),
                    ),
                  ]),
                ),
              ],
            ]),
    );
  }

  String _getStatusText() {
    if (!_supported) return 'Qurilma qo\'llab-quvvatlamaydi';
    switch (_status) {
      case BiometricStatus.available:
        return _enabled ? 'Faol — Ilovaga kirish himoyalangan' : 'O\'chirilgan';
      case BiometricStatus.notEnrolled:
        return 'Telefon sozlamalarida $_label qo\'shing';
      case BiometricStatus.lockedOut:
        return '⏳ Vaqtinchalik bloklangan';
      case BiometricStatus.permanentLockout:
        return '🔒 Doimiy bloklangan';
      default:
        return 'O\'chirilgan';
    }
  }

  Color _getStatusColor() {
    switch (_status) {
      case BiometricStatus.available:
        return _enabled ? _green : Colors.white38;
      case BiometricStatus.lockedOut:
      case BiometricStatus.permanentLockout:
        return Colors.red;
      case BiometricStatus.notEnrolled:
        return Colors.orange;
      default:
        return Colors.white38;
    }
  }
}


// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📁 android/app/src/main/AndroidManifest.xml — qo'shish kerak:
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
  <manifest ...>

    <!-- BIOMETRIK RUXSATLAR — bu 3 qatorni qo'shing -->
    <uses-permission android:name="android.permission.USE_BIOMETRIC" />
    <uses-permission android:name="android.permission.USE_FINGERPRINT" />
    <uses-feature android:name="android.hardware.fingerprint" android:required="false" />

    <application ...>
      ...
    </application>
  </manifest>
*/


// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📁 pubspec.yaml — qo'shish kerak (dependencies bo'limiga):
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
dependencies:
  flutter:
    sdk: flutter

  # ─── Mavjud ───
  firebase_core: ^3.1.0
  firebase_auth: ^5.1.0
  firebase_database: ^11.0.0
  flutter_secure_storage: ^9.2.2
  shared_preferences: ^2.2.0
  http: ^1.1.0

  # ─── v2.5 YANGI — bu qatorni qo'shing ───
  local_auth: ^2.3.0
*/


// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📁 android/app/build.gradle — minSdkVersion tekshirish
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
  android {
    defaultConfig {
      minSdkVersion 24    // ← kamida 24 bo'lishi kerak (biometrik uchun)
      targetSdkVersion 35
    }
  }
*/
