import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'settings_screen.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _isOtpMode = false;
  bool _error = false;
  String _generatedOtp = '';
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(duration: Duration(milliseconds: 500), vsync: this);
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);
  }

  void _addDigit(String d) {
    if (_pin.length < 6) {
      setState(() { _pin += d; _error = false; });
      if (_pin.length == 4 && !_isOtpMode) _verify();
      if (_pin.length == 6 && _isOtpMode) _verifyOtp();
    }
  }

  void _delete() { if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1)); }

  Future<void> _verify() async {
    final ok = await AuthService.verifyPin(_pin);
    if (ok) { Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SettingsScreen())); }
    else { setState(() { _error = true; _pin = ''; }); _shakeCtrl.forward(from: 0); }
  }

  Future<void> _verifyOtp() async {
    final ok = await AuthService.verifyOtp(_pin);
    if (ok) { Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SettingsScreen())); }
    else { setState(() { _error = true; _pin = ''; }); _shakeCtrl.forward(from: 0); }
  }

  Future<void> _generateOtp() async {
    final otp = await AuthService.generateOtp();
    setState(() => _generatedOtp = otp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF030812),
      body: SafeArea(child: Column(children: [
        SizedBox(height: 60),
        Icon(Icons.lock_rounded, color: Color(0xFF00D4FF), size: 50),
        SizedBox(height: 16),
        Text('SOZLAMALAR', style: TextStyle(color: Color(0xFF00D4FF), fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4)),
        SizedBox(height: 8),
        Text(_isOtpMode ? '6 xonali OTP kiriting' : '4 xonali PIN kiriting', style: TextStyle(color: Colors.white38, fontSize: 14)),
        SizedBox(height: 40),
        AnimatedBuilder(
          animation: _shakeAnim,
          builder: (_, __) => Transform.translate(
            offset: Offset(_error ? 10 * (0.5 - _shakeAnim.value).abs() * 4 : 0, 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_isOtpMode ? 6 : 4, (i) => Container(
                margin: EdgeInsets.symmetric(horizontal: 8), width: 16, height: 16,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: i < _pin.length ? (_error ? Colors.red : Color(0xFF00D4FF)) : Colors.white12),
              ))),
          ),
        ),
        if (_error) ...[SizedBox(height: 12), Text('Noto\'g\'ri kod!', style: TextStyle(color: Colors.red))],
        SizedBox(height: 40),
        Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Column(children: [
          _row(['1','2','3']), SizedBox(height: 16),
          _row(['4','5','6']), SizedBox(height: 16),
          _row(['7','8','9']), SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            SizedBox(width: 72, height: 72),
            _digitBtn('0'),
            _actionBtn(Icons.backspace_rounded, _delete),
          ]),
        ])),
        SizedBox(height: 20),
        TextButton(onPressed: () => setState(() { _isOtpMode = !_isOtpMode; _pin = ''; }),
          child: Text(_isOtpMode ? 'PIN bilan kirish' : 'OTP bilan kirish', style: TextStyle(color: Color(0xFF00D4FF)))),
        if (_isOtpMode) ...[
          TextButton(onPressed: _generateOtp, child: Text('OTP generatsiya', style: TextStyle(color: Colors.white38))),
          if (_generatedOtp.isNotEmpty) Container(
            margin: EdgeInsets.symmetric(horizontal: 40),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border.all(color: Color(0xFF00D4FF).withOpacity(0.3)), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Text('OTP kodingiz:', style: TextStyle(color: Colors.white38, fontSize: 12)),
              SizedBox(height: 6),
              Text(_generatedOtp, style: TextStyle(color: Color(0xFF00FF88), fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 8)),
              Text('5 daqiqa', style: TextStyle(color: Colors.white24, fontSize: 11)),
            ]),
          ),
        ],
      ])),
    );
  }

  Widget _row(List<String> d) => Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: d.map(_digitBtn).toList());
  Widget _digitBtn(String d) => GestureDetector(onTap: () => _addDigit(d),
    child: Container(width: 72, height: 72,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06), border: Border.all(color: Colors.white12)),
      child: Center(child: Text(d, style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w300)))));
  Widget _actionBtn(IconData icon, VoidCallback fn) => GestureDetector(onTap: fn,
    child: Container(width: 72, height: 72,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.04)),
      child: Center(child: Icon(icon, color: Colors.white54, size: 26))));

  @override
  void dispose() { _shakeCtrl.dispose(); super.dispose(); }
}
