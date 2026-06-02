import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _geminiCtrl = TextEditingController();
  final _openaiCtrl = TextEditingController();
  final _groqCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _pinConfirmCtrl = TextEditingController();
  String _selectedProvider = 'gemini';
  String _generatedOtp = '';
  List<Map<String, dynamic>> _savedData = [];
  bool _hasPin = false;
  bool _loading = false;
  Map<String, bool> _visible = {'gemini': false, 'openai': false, 'groq': false};

  @override
  void initState() { super.initState(); _loadAll(); }

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    _nameCtrl.text = prefs.getString('user_name') ?? '';
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    _geminiCtrl.text = prefs.getString('gemini_api_key') ?? '';
    _openaiCtrl.text = prefs.getString('openai_api_key') ?? '';
    _groqCtrl.text = prefs.getString('groq_api_key') ?? '';
    _selectedProvider = prefs.getString('ai_provider') ?? 'gemini';
    _hasPin = await AuthService.hasPin();
    _savedData = await FirebaseService.getSavedData();
    setState(() => _loading = false);
  }

  Future<void> _saveKey(String provider, String key) async {
    if (key.trim().isEmpty) { _msg('Key bo\'sh bo\'lmasin!'); return; }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${provider}_api_key', key.trim());
    await prefs.setString('ai_provider', _selectedProvider);
    await FirebaseService.saveApiKey(provider, key.trim());
    _msg('✅ Saqlandi!');
    _loadAll();
  }

  Future<void> _savePin() async {
    if (_pinCtrl.text.length < 4) { _msg('PIN kamida 4 raqam!'); return; }
    if (_pinCtrl.text != _pinConfirmCtrl.text) { _msg('PIN lar mos kelmadi!'); return; }
    await AuthService.setPin(_pinCtrl.text);
    setState(() => _hasPin = true);
    _pinCtrl.clear(); _pinConfirmCtrl.clear();
    _msg('✅ PIN o\'rnatildi!');
  }

  Future<void> _generateOtp() async {
    final otp = await AuthService.generateOtp();
    setState(() => _generatedOtp = otp);
  }

  void _msg(String m) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(m), duration: Duration(seconds: 2)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF030812),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: Color(0xFF00D4FF)), onPressed: () => Navigator.pop(context)),
        title: Text('SOZLAMALAR', style: TextStyle(color: Color(0xFF00D4FF), letterSpacing: 4, fontSize: 16)),
        actions: [if (_loading) Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00D4FF))))],
      ),
      body: SingleChildScrollView(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _title('🧠 AI Tanlash'),
        _card(Column(children: [
          _provider('gemini', 'Google Gemini', '🟢 Bepul'),
          _provider('openai', 'OpenAI GPT', '🔵 Pullik'),
          _provider('groq', 'Groq Llama', '🟡 Bepul'),
        ])),
        _title('🔑 API Key'),
        _card(Column(children: [
          if (_selectedProvider == 'gemini') ...[
            Text('aistudio.google.com → API Keys', style: TextStyle(color: Colors.white30, fontSize: 12)),
            SizedBox(height: 8),
            _keyField(_geminiCtrl, 'AIzaSy...', 'gemini'),
            SizedBox(height: 12),
            _btn('Gemini keyni saqlash', () => _saveKey('gemini', _geminiCtrl.text)),
          ],
          if (_selectedProvider == 'openai') ...[
            Text('platform.openai.com → API Keys', style: TextStyle(color: Colors.white30, fontSize: 12)),
            SizedBox(height: 8),
            _keyField(_openaiCtrl, 'sk-...', 'openai'),
            SizedBox(height: 12),
            _btn('OpenAI keyni saqlash', () => _saveKey('openai', _openaiCtrl.text)),
          ],
          if (_selectedProvider == 'groq') ...[
            Text('console.groq.com → API Keys', style: TextStyle(color: Colors.white30, fontSize: 12)),
            SizedBox(height: 8),
            _keyField(_groqCtrl, 'gsk_...', 'groq'),
            SizedBox(height: 12),
            _btn('Groq keyni saqlash', () => _saveKey('groq', _groqCtrl.text)),
          ],
        ])),
        _title('💾 Saqlangan Ma\'lumotlar'),
        _card(_savedData.isEmpty
          ? Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Hali saqlangan key yo\'q', style: TextStyle(color: Colors.white24))))
          : Column(children: [
              ..._savedData.map((d) => Container(margin: EdgeInsets.only(bottom: 8), padding: EdgeInsets.all(12),
                decoration: BoxDecoration(border: Border.all(color: Colors.white12), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Icon(Icons.key, color: Color(0xFF00D4FF), size: 16),
                  SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d['provider'].toString().toUpperCase(), style: TextStyle(color: Colors.white60, fontSize: 12)),
                    Text(d['key'] ?? '', style: TextStyle(color: Colors.white30, fontSize: 11)),
                  ])),
                  Icon(Icons.check_circle_outline, color: Color(0xFF00FF88), size: 16),
                ])) as Widget).toList(),
              TextButton.icon(onPressed: _loadAll, icon: Icon(Icons.refresh, color: Color(0xFF00D4FF), size: 16),
                label: Text('Yangilash', style: TextStyle(color: Color(0xFF00D4FF)))),
            ])),
        _title('🔒 PIN Xavfsizlik'),
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!_hasPin) ...[
            _inputField(_pinCtrl, 'Yangi PIN (4-6 raqam)', isNumber: true, maxLen: 6, obscure: true),
            SizedBox(height: 10),
            _inputField(_pinConfirmCtrl, 'PIN tasdiqlash', isNumber: true, maxLen: 6, obscure: true),
            SizedBox(height: 12),
            _btn('PIN o\'rnatish', _savePin),
          ] else Row(children: [
            Icon(Icons.check_circle, color: Color(0xFF00FF88), size: 18),
            SizedBox(width: 8),
            Text('PIN o\'rnatilgan', style: TextStyle(color: Color(0xFF00FF88))),
            Spacer(),
            TextButton(onPressed: () async { await AuthService.removePin(); setState(() => _hasPin = false); },
              child: Text('O\'chirish', style: TextStyle(color: Colors.red, fontSize: 12))),
          ]),
        ])),
        _title('🎲 OTP Generatsiya'),
        _card(Column(children: [
          Text('5 daqiqa amal qiladigan bir martalik kod', style: TextStyle(color: Colors.white30, fontSize: 12)),
          SizedBox(height: 12),
          _btn('OTP Generatsiya', _generateOtp),
          if (_generatedOtp.isNotEmpty) ...[
            SizedBox(height: 16),
            Container(padding: EdgeInsets.all(20),
              decoration: BoxDecoration(border: Border.all(color: Color(0xFF00FF88).withOpacity(0.3)), borderRadius: BorderRadius.circular(16), color: Color(0xFF00FF88).withOpacity(0.05)),
              child: Column(children: [
                Text('OTP kodingiz:', style: TextStyle(color: Colors.white38, fontSize: 12)),
                SizedBox(height: 8),
                Text(_generatedOtp, style: TextStyle(color: Color(0xFF00FF88), fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: 12)),
                SizedBox(height: 8),
                GestureDetector(onTap: () { Clipboard.setData(ClipboardData(text: _generatedOtp)); _msg('Nusxa olindi!'); },
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.copy, color: Color(0xFF00D4FF), size: 16),
                    SizedBox(width: 4),
                    Text('Nusxa olish', style: TextStyle(color: Color(0xFF00D4FF), fontSize: 12)),
                  ])),
              ])),
          ],
        ])),
        _title('🎙️ Buyruqlar'),
        _card(Column(children: [
          _cmd('Ilovalar', 'Telegram, YouTube, Instagram, WhatsApp, TikTok, Spotify'),
          _cmd('Qidiruv', '"[narsa] qidir"'),
          _cmd('Qo\'ng\'iroq', '"[raqam]ga qo\'ng\'iroq"'),
          _cmd('SMS', '"[raqam]ga SMS"'),
          _cmd('Ob-havo', '"Bugun havo qanday?"'),
          _cmd('Vaqt', '"Soat necha?"'),
          _cmd('Musiqa', '"[qo\'shiq] qo\'y"'),
        ])),
        SizedBox(height: 30),
      ])),
    );
  }

  Widget _title(String t) => Padding(padding: EdgeInsets.only(top: 20, bottom: 10),
    child: Text(t, style: TextStyle(color: Color(0xFF00D4FF), fontSize: 15, fontWeight: FontWeight.bold)));

  Widget _card(Widget child) => Container(width: double.infinity, padding: EdgeInsets.all(16),
    decoration: BoxDecoration(border: Border.all(color: Colors.white.withOpacity(0.08)), borderRadius: BorderRadius.circular(18), color: Colors.white.withOpacity(0.03)),
    child: child);

  Widget _provider(String id, String name, String desc) => GestureDetector(
    onTap: () async { setState(() => _selectedProvider = id); final p = await SharedPreferences.getInstance(); await p.setString('ai_provider', id); },
    child: Container(margin: EdgeInsets.only(bottom: 8), padding: EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border.all(color: _selectedProvider == id ? Color(0xFF00D4FF) : Colors.white12, width: _selectedProvider == id ? 1.5 : 1), borderRadius: BorderRadius.circular(14), color: _selectedProvider == id ? Color(0xFF00D4FF).withOpacity(0.08) : Colors.transparent),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          Text(desc, style: TextStyle(color: Colors.white38, fontSize: 12)),
        ])),
        if (_selectedProvider == id) Icon(Icons.check_circle, color: Color(0xFF00D4FF), size: 20),
      ])));

  Widget _keyField(TextEditingController c, String hint, String key) => TextField(
    controller: c, obscureText: !(_visible[key] ?? false),
    style: TextStyle(color: Colors.white, fontSize: 13),
    decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.white24), filled: true, fillColor: Colors.white.withOpacity(0.04),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFF00D4FF))),
      suffixIcon: IconButton(icon: Icon(_visible[key]! ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 20),
        onPressed: () => setState(() => _visible[key] = !(_visible[key] ?? false)))));

  Widget _inputField(TextEditingController c, String hint, {bool isNumber = false, int? maxLen, bool obscure = false}) => TextField(
    controller: c, keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    maxLength: maxLen, obscureText: obscure,
    style: TextStyle(color: Colors.white, fontSize: 13),
    decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.white24), counterText: '', filled: true, fillColor: Colors.white.withOpacity(0.04),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFF00D4FF)))));

  Widget _btn(String label, VoidCallback fn) => SizedBox(width: double.infinity,
    child: ElevatedButton(onPressed: fn, style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00D4FF), padding: EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: Text(label, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14))));

  Widget _cmd(String t, String d) => Padding(padding: EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 4, height: 4, margin: EdgeInsets.only(top: 7, right: 8), decoration: BoxDecoration(color: Color(0xFF00D4FF), shape: BoxShape.circle)),
      Expanded(child: RichText(text: TextSpan(children: [
        TextSpan(text: '$t: ', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
        TextSpan(text: d, style: TextStyle(color: Colors.white30, fontSize: 12)),
      ]))),
    ]));

  @override
  void dispose() { _geminiCtrl.dispose(); _openaiCtrl.dispose(); _groqCtrl.dispose(); _pinCtrl.dispose(); _pinConfirmCtrl.dispose(); super.dispose(); }
}
