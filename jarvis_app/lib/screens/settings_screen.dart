import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../services/groq_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<String, TextEditingController> _ctrls = {};
  final _pinCtrl = TextEditingController();
  final _pinConfirmCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _provider = 'gemini';
  String _otp = '';
  List<Map<String, dynamic>> _saved = [];
  bool _hasPin = false;
  bool _loading = false;
  double _ttsRate = 0.88;
  double _ttsPitch = 1.0;
  double _ttsVolume = 1.0;

  @override
  void initState() {
    super.initState();
    for (final k in GroqService.providers.keys) {
      _ctrls[k] = TextEditingController();
    }
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    _provider = prefs.getString('ai_provider') ?? 'gemini';
    _nameCtrl.text = prefs.getString('user_name') ?? '';
    _ttsRate = prefs.getDouble('tts_rate') ?? 0.88;
    _ttsPitch = prefs.getDouble('tts_pitch') ?? 1.0;
    _ttsVolume = prefs.getDouble('tts_volume') ?? 1.0;
    for (final k in GroqService.providers.keys) {
      _ctrls[k]?.text = prefs.getString('${k}_api_key') ?? '';
    }
    _hasPin = await AuthService.hasPin();
    _saved = await FirebaseService.getSavedData();
    setState(() => _loading = false);
  }

  Future<void> _saveKey(String provider) async {
    final key = _ctrls[provider]?.text.trim() ?? '';
    if (key.isEmpty) { _snack('Key bo\'sh!'); return; }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${provider}_api_key', key);
    await prefs.setString('ai_provider', provider);
    setState(() => _provider = provider);
    await FirebaseService.saveApiKey(provider, key);
    _snack('✅ ${GroqService.providers[provider]!['name']} key saqlandi!');
    _load();
  }

  Future<void> _saveTts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_rate', _ttsRate);
    await prefs.setDouble('tts_pitch', _ttsPitch);
    await prefs.setDouble('tts_volume', _ttsVolume);
    _snack('✅ Ovoz sozlamalari saqlandi!');
  }

  Future<void> _saveName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameCtrl.text.trim());
    _snack('✅ Ism saqlandi!');
  }

  Future<void> _savePin() async {
    if (_pinCtrl.text.length < 4) { _snack('PIN kamida 4 raqam!'); return; }
    if (_pinCtrl.text != _pinConfirmCtrl.text) { _snack('PIN lar mos kelmadi!'); return; }
    await AuthService.setPin(_pinCtrl.text);
    setState(() => _hasPin = true);
    _pinCtrl.clear(); _pinConfirmCtrl.clear();
    _snack('✅ PIN o\'rnatildi!');
  }

  Future<void> _genOtp() async {
    final o = await AuthService.generateOtp();
    setState(() => _otp = o);
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _snack('📋 Nusxa olindi!');
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), duration: Duration(seconds: 2),
      backgroundColor: msg.contains('✅') ? Color(0xFF00FF88) : Colors.red));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF030812),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF00D4FF)),
          onPressed: () => Navigator.pop(context)),
        title: Text('SOZLAMALAR', style: TextStyle(
          color: Color(0xFF00D4FF), fontSize: 16, letterSpacing: 4)),
        actions: [if (_loading) Padding(padding: EdgeInsets.all(16),
          child: SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00D4FF))))],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── SHAXSIY ──
          _title('👤 Shaxsiy Ma\'lumot'),
          _card(Column(children: [
            _input(_nameCtrl, 'Ismingiz', 'Yusuf'),
            SizedBox(height: 10),
            _btn('Ismni saqlash', _saveName),
          ])),

          // ── AI TANLASH ──
          _title('🧠 AI Provider Tanlash'),
          _card(Column(children: GroqService.providers.entries.map((e) =>
            _providerTile(e.key, e.value)).toList())),

          // ── API KEYS ──
          _title('🔑 API Keylar'),
          _card(Column(
            children: GroqService.providers.entries.map((e) =>
              _apiKeySection(e.key, e.value)).toList(),
          )),

          // ── SAQLANGAN KEYLAR ──
          _title('💾 Saqlangan Keylar'),
          _card(_saved.isEmpty
            ? Padding(
                padding: EdgeInsets.all(16),
                child: Text('Hali key saqlanmagan', style: TextStyle(color: Colors.white24)))
            : Column(children: [
                ..._saved.map((d) => _savedTile(d)),
                TextButton.icon(
                  onPressed: _load,
                  icon: Icon(Icons.refresh, color: Color(0xFF00D4FF), size: 16),
                  label: Text('Yangilash', style: TextStyle(color: Color(0xFF00D4FF)))),
              ])),

          // ── OVOZ SOZLAMALARI ──
          _title('🔊 Jarvis Ovozi'),
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sliderRow('🚀 Tezlik', _ttsRate, 0.3, 1.5, (v) => setState(() => _ttsRate = v)),
            _sliderRow('🎵 Balandlik', _ttsPitch, 0.5, 2.0, (v) => setState(() => _ttsPitch = v)),
            _sliderRow('🔉 Ovoz', _ttsVolume, 0.0, 1.0, (v) => setState(() => _ttsVolume = v)),
            SizedBox(height: 10),
            _btn('Ovoz sozlamalarini saqlash', _saveTts),
          ])),

          // ── XAVFSIZLIK ──
          _title('🔒 Xavfsizlik'),
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (!_hasPin) ...[
              _input(_pinCtrl, 'Yangi PIN (4-6 raqam)', '••••', isNum: true, maxLen: 6, obscure: true),
              SizedBox(height: 8),
              _input(_pinConfirmCtrl, 'PIN tasdiqlash', '••••', isNum: true, maxLen: 6, obscure: true),
              SizedBox(height: 10),
              _btn('PIN o\'rnatish', _savePin),
            ] else Row(children: [
              Icon(Icons.check_circle, color: Color(0xFF00FF88), size: 20),
              SizedBox(width: 8),
              Text('PIN o\'rnatilgan', style: TextStyle(color: Color(0xFF00FF88))),
              Spacer(),
              TextButton(
                onPressed: () async { await AuthService.removePin(); setState(() => _hasPin = false); },
                child: Text('O\'chirish', style: TextStyle(color: Colors.red, fontSize: 12))),
            ]),
          ])),

          // ── OTP ──
          _title('🎲 OTP Generatsiya'),
          _card(Column(children: [
            _btn('OTP Yaratish (5 daqiqa)', _genOtp),
            if (_otp.isNotEmpty) ...[
              SizedBox(height: 14),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFF00FF88).withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(children: [
                  Text(_otp, style: TextStyle(
                    color: Color(0xFF00FF88), fontSize: 40,
                    fontWeight: FontWeight.bold, letterSpacing: 10)),
                  SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    TextButton.icon(
                      onPressed: () => _copy(_otp),
                      icon: Icon(Icons.copy, color: Color(0xFF00D4FF), size: 16),
                      label: Text('Nusxa', style: TextStyle(color: Color(0xFF00D4FF), fontSize: 12))),
                  ]),
                ]),
              ),
            ],
          ])),

          SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _title(String t) => Padding(
    padding: EdgeInsets.only(top: 20, bottom: 10),
    child: Text(t, style: TextStyle(color: Color(0xFF00D4FF),
      fontSize: 15, fontWeight: FontWeight.bold)));

  Widget _card(Widget child) => Container(
    width: double.infinity, padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.white.withOpacity(0.08)),
      borderRadius: BorderRadius.circular(18),
      color: Colors.white.withOpacity(0.03)),
    child: child);

  Widget _providerTile(String id, Map<String, String> info) => GestureDetector(
    onTap: () async {
      setState(() => _provider = id);
      final p = await SharedPreferences.getInstance();
      await p.setString('ai_provider', id);
    },
    child: Container(
      margin: EdgeInsets.only(bottom: 8), padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: _provider == id ? Color(0xFF00D4FF) : Colors.white12,
          width: _provider == id ? 1.5 : 1),
        borderRadius: BorderRadius.circular(12),
        color: _provider == id ? Color(0xFF00D4FF).withOpacity(0.08) : Colors.transparent,
      ),
      child: Row(children: [
        Text(info['emoji']!, style: TextStyle(fontSize: 20)),
        SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(info['name']!, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          Text(info['free']!, style: TextStyle(color: Colors.white38, fontSize: 11)),
        ])),
        if (_provider == id) Icon(Icons.check_circle, color: Color(0xFF00D4FF), size: 20),
      ]),
    ),
  );

  Widget _apiKeySection(String id, Map<String, String> info) {
    final ctrl = _ctrls[id]!;
    final hasKey = ctrl.text.isNotEmpty;
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: hasKey
          ? Color(0xFF00FF88).withOpacity(0.2) : Colors.white.withOpacity(0.06)),
        borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('${info['emoji']} ${info['name']}',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
          Spacer(),
          if (hasKey) Icon(Icons.check_circle_outline, color: Color(0xFF00FF88), size: 16),
          // API olish linki
          TextButton(
            onPressed: () {
              final urls = {
                'gemini': 'https://aistudio.google.com',
                'groq': 'https://console.groq.com',
                'openai': 'https://platform.openai.com',
                'mistral': 'https://console.mistral.ai',
                'cohere': 'https://dashboard.cohere.ai',
                'huggingface': 'https://huggingface.co/settings/tokens',
                'openrouter': 'https://openrouter.ai/keys',
              };
              launchUrl(Uri.parse(urls[id] ?? 'https://google.com'),
                mode: LaunchMode.externalApplication);
            },
            child: Text('Key olish', style: TextStyle(color: Color(0xFF00D4FF), fontSize: 11)),
          ),
        ]),
        SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(
            controller: ctrl,
            obscureText: true,
            style: TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Key kiriting...',
              hintStyle: TextStyle(color: Colors.white24),
              filled: true, fillColor: Colors.white.withOpacity(0.04),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white12)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white12)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Color(0xFF00D4FF))),
            ),
          )),
          SizedBox(width: 8),
          // Saqlash
          GestureDetector(
            onTap: () => _saveKey(id),
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFF00D4FF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.save_rounded, color: Color(0xFF00D4FF), size: 20))),
        ]),
      ]),
    );
  }

  Widget _savedTile(Map<String, dynamic> d) => Container(
    margin: EdgeInsets.only(bottom: 8),
    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.white.withOpacity(0.07)),
      borderRadius: BorderRadius.circular(12),
      color: Colors.white.withOpacity(0.03)),
    child: Row(children: [
      Text(GroqService.providers[d['provider']]?['emoji'] ?? '🔑',
        style: TextStyle(fontSize: 18)),
      SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(GroqService.providers[d['provider']]?['name'] ?? d['provider'],
          style: TextStyle(color: Colors.white70, fontSize: 12)),
        Text(d['key'] ?? '****', style: TextStyle(color: Colors.white30, fontSize: 11)),
      ])),
      // Nusxa olish
      GestureDetector(
        onTap: () {
          final fullKey = _ctrls[d['provider']]?.text ?? '';
          if (fullKey.isNotEmpty) _copy(fullKey);
          else _snack('Key topilmadi');
        },
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF00D4FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.copy_rounded, color: Color(0xFF00D4FF), size: 16))),
    ]),
  );

  Widget _sliderRow(String label, double val, double min, double max, Function(double) onChange) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label, style: TextStyle(color: Colors.white60, fontSize: 13)),
        Spacer(),
        Text(val.toStringAsFixed(2), style: TextStyle(color: Color(0xFF00D4FF), fontSize: 12)),
      ]),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: Color(0xFF00D4FF),
          thumbColor: Color(0xFF00D4FF),
          inactiveTrackColor: Colors.white12,
          overlayColor: Color(0xFF00D4FF).withOpacity(0.2),
        ),
        child: Slider(value: val, min: min, max: max, onChanged: onChange),
      ),
    ]);

  Widget _input(TextEditingController ctrl, String label, String hint,
      {bool isNum = false, int? maxLen, bool obscure = false}) =>
    TextField(
      controller: ctrl,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      maxLength: maxLen, obscureText: obscure,
      style: TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label, labelStyle: TextStyle(color: Colors.white38),
        hintText: hint, hintStyle: TextStyle(color: Colors.white24),
        counterText: '', filled: true, fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF00D4FF))),
      ),
    );

  Widget _btn(String label, VoidCallback fn) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: fn,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF00D4FF),
        padding: EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: Text(label, style: TextStyle(
        color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14))));

  @override
  void dispose() {
    for (final c in _ctrls.values) c.dispose();
    _pinCtrl.dispose(); _pinConfirmCtrl.dispose(); _nameCtrl.dispose();
    super.dispose();
  }
}
