import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'face_auth_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionScreen extends StatefulWidget {
  @override
  _PermissionScreenState createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  Map<String, PermissionStatus> _statuses = {};
  bool _loading = true;

  final List<_PermItem> _permissions = [
    _PermItem(Permission.microphone, '🎙️', 'Mikrofon',
        'Ovozli buyruqlar berish uchun', true),
    _PermItem(Permission.camera, '📷', 'Kamera',
        'Yuz aniqlash va video uchun', true),
    _PermItem(Permission.location, '📍', 'Lokatsiya',
        'Joylashuvga asoslangan xizmatlar', true),
    _PermItem(Permission.phone, '📞', 'Qo\'ng\'iroq',
        'To\'g\'ridan-to\'g\'ri qo\'ng\'iroq qilish', true),
    _PermItem(Permission.sms, '💬', 'SMS',
        'Xabar yuborish va o\'qish', true),
    _PermItem(Permission.contacts, '👥', 'Kontaktlar',
        'Ismlar bo\'yicha qidiruv', true),
    _PermItem(Permission.notification, '🔔', 'Bildirishnomalar',
        'Eslatmalar va ogohlantirishlar', true),
    _PermItem(Permission.storage, '💾', 'Xotira',
        'Fayllar saqlash va o\'qish', false),
    _PermItem(Permission.systemAlertWindow, '🪟', 'Oyna ustida',
        'Maxsus Jarvis paneli (ixtiyoriy)', false),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: Duration(milliseconds: 600), vsync: this);
    _checkAll();
  }

  Future<void> _checkAll() async {
    Map<String, PermissionStatus> s = {};
    for (final p in _permissions) {
      s[p.permission.toString()] = await p.permission.status;
    }
    setState(() { _statuses = s; _loading = false; });
    _ctrl.forward();
  }

  Future<void> _requestAll() async {
    setState(() => _loading = true);

    // Oddiy ruxsatlar
    final basic = _permissions
        .where((p) => p.required)
        .map((p) => p.permission)
        .toList();

    await basic.request();

    // Maxsus ruxsatlar
    if (!await Permission.systemAlertWindow.isGranted) {
      await Permission.systemAlertWindow.request();
    }

    await _checkAll();
  }

  Future<void> _requestSingle(_PermItem item) async {
    final result = await item.permission.request();
    if (result.isPermanentlyDenied) {
      AppSettings.openAppSettings();
    }
    await _checkAll();
  }

  bool get _allRequired => _permissions
      .where((p) => p.required)
      .every((p) => _statuses[p.permission.toString()]?.isGranted ?? false);

  void _continue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissions_done', true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => FaceAuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF030812),
      body: SafeArea(
        child: Column(children: [
          // Sarlavha
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(children: [
              Text('JARVIS', style: TextStyle(
                color: Color(0xFF00D4FF), fontSize: 28,
                fontWeight: FontWeight.bold, letterSpacing: 6,
              )),
              SizedBox(height: 6),
              Text('Ruxsatlar kerak', style: TextStyle(
                color: Colors.white38, fontSize: 13, letterSpacing: 2,
              )),
            ]),
          ),

          // Izoh
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFF00D4FF).withOpacity(0.2)),
              borderRadius: BorderRadius.circular(16),
              color: Color(0xFF00D4FF).withOpacity(0.04),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, color: Color(0xFF00D4FF), size: 20),
              SizedBox(width: 10),
              Expanded(child: Text(
                'Jarvis to\'liq ishlashi uchun quyidagi ruxsatlar kerak. '
                'Yashil — berilgan, qizil — berilmagan.',
                style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
              )),
            ]),
          ),

          SizedBox(height: 12),

          // Ruxsatlar ro'yxati
          Expanded(
            child: _loading
              ? Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF)))
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _permissions.length,
                  itemBuilder: (_, i) {
                    final item = _permissions[i];
                    final granted = _statuses[item.permission.toString()]?.isGranted ?? false;
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 400 + i * 60),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (_, v, __) => Opacity(
                        opacity: v,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - v)),
                          child: _permTile(item, granted),
                        ),
                      ),
                    );
                  },
                ),
          ),

          // Tugmalar
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(children: [
              // Hammasini so'rash
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _requestAll,
                  icon: Icon(Icons.security_rounded, color: Colors.black),
                  label: Text('Barcha ruxsatlarni berish',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00D4FF),
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              SizedBox(height: 10),
              // Davom etish
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _continue,
                  icon: Icon(Icons.arrow_forward_rounded,
                    color: _allRequired ? Colors.black : Colors.white54),
                  label: Text(
                    _allRequired ? 'Davom etish ✅' : 'O\'tkazib yuborish',
                    style: TextStyle(
                      color: _allRequired ? Colors.black : Colors.white54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _allRequired
                      ? Color(0xFF00FF88)
                      : Colors.white.withOpacity(0.08),
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _permTile(_PermItem item, bool granted) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: granted
            ? Color(0xFF00FF88).withOpacity(0.3)
            : item.required
              ? Color(0xFFFF3366).withOpacity(0.3)
              : Colors.white12,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
        color: granted
          ? Color(0xFF00FF88).withOpacity(0.05)
          : Colors.white.withOpacity(0.03),
      ),
      child: Row(children: [
        // Emoji
        Text(item.emoji, style: TextStyle(fontSize: 24)),
        SizedBox(width: 14),
        // Ma'lumot
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(item.label, style: TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600,
            )),
            SizedBox(width: 6),
            if (item.required)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xFF00D4FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Kerakli', style: TextStyle(
                  color: Color(0xFF00D4FF), fontSize: 9, letterSpacing: 0.5,
                )),
              ),
          ]),
          SizedBox(height: 3),
          Text(item.description, style: TextStyle(
            color: Colors.white38, fontSize: 11,
          )),
        ])),
        SizedBox(width: 10),
        // Status / Tugma
        if (granted)
          Icon(Icons.check_circle_rounded, color: Color(0xFF00FF88), size: 26)
        else
          GestureDetector(
            onTap: () => _requestSingle(item),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF00D4FF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color(0xFF00D4FF).withOpacity(0.4)),
              ),
              child: Text('Berish', style: TextStyle(
                color: Color(0xFF00D4FF), fontSize: 12,
              )),
            ),
          ),
      ]),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
}

class _PermItem {
  final Permission permission;
  final String emoji, label, description;
  final bool required;
  const _PermItem(this.permission, this.emoji, this.label, this.description, this.required);
}
