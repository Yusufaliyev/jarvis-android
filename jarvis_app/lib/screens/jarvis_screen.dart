import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/groq_service.dart';
import '../services/command_service.dart';
import '../widgets/jarvis_orb.dart';

class JarvisScreen extends StatefulWidget {
  @override
  _JarvisScreenState createState() => _JarvisScreenState();
}

class _JarvisScreenState extends State<JarvisScreen> with TickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final GroqService _groq = GroqService();
  final CommandService _cmd = CommandService();

  bool _listening = false, _thinking = false, _speaking = false, _showBtns = false;
  String _userText = '', _jarvisText = '';

  late AnimationController _btnsCtrl, _micCtrl;
  late Animation<double> _btnsAnim, _micPulse;

  final _btns = [
    {'icon': Icons.send_rounded, 'label': 'Telegram', 'cmd': 'Telegram'},
    {'icon': Icons.play_circle_rounded, 'label': 'YouTube', 'cmd': 'YouTube'},
    {'icon': Icons.photo_camera_rounded, 'label': 'Kamera', 'cmd': 'Kamera'},
    {'icon': Icons.message_rounded, 'label': 'SMS', 'cmd': 'SMS'},
    {'icon': Icons.phone_rounded, 'label': 'Qo\'ng\'iroq', 'cmd': 'Qo\'ng\'iroq'},
    {'icon': Icons.settings_rounded, 'label': 'Sozlama', 'cmd': 'Sozlamalar'},
    {'icon': Icons.map_rounded, 'label': 'Xarita', 'cmd': 'Xarita'},
    {'icon': Icons.search_rounded, 'label': 'Qidir', 'cmd': 'Google'},
  ];

  @override
  void initState() {
    super.initState();
    _btnsCtrl = AnimationController(duration: Duration(milliseconds: 500), vsync: this);
    _btnsAnim = CurvedAnimation(parent: _btnsCtrl, curve: Curves.easeOutBack);
    _micCtrl = AnimationController(duration: Duration(milliseconds: 800), vsync: this)..repeat(reverse: true);
    _micPulse = Tween<double>(begin: 1.0, end: 1.12).animate(CurvedAnimation(parent: _micCtrl, curve: Curves.easeInOut));
    _initJarvis();
  }

  Future<void> _initJarvis() async {
    await _tts.setLanguage('uz-UZ');
    await _tts.setSpeechRate(0.88);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() { if (mounted) setState(() => _speaking = false); });
    await Future.delayed(Duration(milliseconds: 1000));
    _speak('Assalomu alaykum! Men Jarvis. Bugun sizga qanday yordam bera olaman?');
  }

  Future<void> _speak(String text) async {
    setState(() { _jarvisText = text; _speaking = true; });
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _listen() async {
    bool ok = await _speech.initialize(onError: (e) => setState(() => _listening = false));
    if (!ok) { _speak('Mikrofon ruxsati kerak!'); return; }
    setState(() { _listening = true; _showBtns = true; _userText = ''; });
    _btnsCtrl.forward();
    _speech.listen(
      onResult: (r) {
        setState(() => _userText = r.recognizedWords);
        if (r.finalResult && _userText.isNotEmpty) _process(_userText);
      },
      localeId: 'uz_UZ',
      listenFor: Duration(seconds: 15),
      pauseFor: Duration(seconds: 3),
    );
  }

  Future<void> _stopListen() async {
    await _speech.stop();
    setState(() => _listening = false);
  }

  Future<void> _process(String text) async {
    _speech.stop();
    setState(() { _listening = false; _thinking = true; _userText = text; });
    String? local = await _cmd.execute(text);
    if (local != null) {
      setState(() => _thinking = false);
      await _speak(local);
    } else {
      String ai = await _groq.ask(text);
      setState(() => _thinking = false);
      await _speak(ai);
    }
    await Future.delayed(Duration(seconds: 4));
    if (mounted) { _btnsCtrl.reverse(); setState(() => _showBtns = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF030812),
      body: Stack(
        children: [
          // Fon
          Container(decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.4), radius: 1.5,
              colors: [Color(0xFF0D1F3C), Color(0xFF030812)],
            ),
          )),
          SafeArea(child: Column(children: [
            _topBar(),
            Expanded(child: Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                JarvisOrb(isListening: _listening, isThinking: _thinking, isSpeaking: _speaking),
                SizedBox(height: 35),
                _textBox(),
                if (_userText.isNotEmpty) ...[SizedBox(height: 12), _userBox()],
              ],
            ))),
            _cmdButtons(),
            _micButton(),
          ])),
        ],
      ),
    );
  }

  Widget _topBar() => Padding(
    padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('JARVIS', style: TextStyle(color: Color(0xFF00D4FF), fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 6)),
        Text('Sun\'iy Intellekt', style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2)),
      ]),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFF00FF88).withOpacity(0.35)),
          borderRadius: BorderRadius.circular(20),
          color: Color(0xFF00FF88).withOpacity(0.05),
        ),
        child: Row(children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: Color(0xFF00FF88), shape: BoxShape.circle)),
          SizedBox(width: 7),
          Text('FAOL', style: TextStyle(color: Color(0xFF00FF88), fontSize: 12, letterSpacing: 1)),
        ]),
      ),
    ]),
  );

  Widget _textBox() {
    final txt = _listening ? '🎙️ Tinglamoqdaman...'
               : _thinking ? '⚡ Fikrlamoqdaman...'
               : _jarvisText.isEmpty ? 'Gapirish uchun mikrofon tugmasini bosing'
               : _jarvisText;
    final borderColor = _listening ? Color(0xFFFF3366) : _thinking ? Color(0xFFFFAA00) : Color(0xFF00D4FF);

    return AnimatedSwitcher(
      duration: Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(txt.substring(0, txt.length.clamp(0, 20))),
        margin: EdgeInsets.symmetric(horizontal: 24),
        padding: EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor.withOpacity(0.25)),
          borderRadius: BorderRadius.circular(22),
          color: borderColor.withOpacity(0.04),
          boxShadow: [BoxShadow(color: borderColor.withOpacity(0.05), blurRadius: 20)],
        ),
        child: Text(txt, style: TextStyle(color: Colors.white.withOpacity(0.88), fontSize: 15, height: 1.7),
          textAlign: TextAlign.center, maxLines: 5, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Widget _userBox() => Padding(
    padding: EdgeInsets.symmetric(horizontal: 24),
    child: Text('🗣️  "$_userText"',
      style: TextStyle(color: Colors.white30, fontSize: 13, fontStyle: FontStyle.italic),
      textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
  );

  Widget _cmdButtons() => AnimatedBuilder(
    animation: _btnsAnim,
    builder: (_, __) => ClipRect(child: Align(
      heightFactor: _btnsAnim.value,
      child: Opacity(
        opacity: _btnsAnim.value.clamp(0.0, 1.0),
        child: Container(
          margin: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Wrap(
            spacing: 10, runSpacing: 10,
            alignment: WrapAlignment.center,
            children: _btns.asMap().entries.map((e) {
              final delay = e.key * 40;
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 350 + delay),
                tween: Tween(begin: 0.0, end: _showBtns ? 1.0 : 0.0),
                curve: Curves.easeOutBack,
                builder: (_, v, __) => Transform.scale(scale: v, child: _cmdBtn(
                  e.value['icon'] as IconData,
                  e.value['label'] as String,
                  e.value['cmd'] as String,
                )),
              );
            }).toList(),
          ),
        ),
      ),
    )),
  );

  Widget _cmdBtn(IconData icon, String label, String cmd) => GestureDetector(
    onTap: () { _btnsCtrl.reverse(); setState(() => _showBtns = false); _process(cmd); },
    child: Container(
      width: 80, padding: EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFF00D4FF).withOpacity(0.25)),
        borderRadius: BorderRadius.circular(16),
        color: Color(0xFF00D4FF).withOpacity(0.06),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Color(0xFF00D4FF), size: 25),
        SizedBox(height: 5),
        Text(label, style: TextStyle(color: Colors.white54, fontSize: 10)),
      ]),
    ),
  );

  Widget _micButton() => Padding(
    padding: EdgeInsets.only(bottom: 32, top: 12),
    child: Column(children: [
      GestureDetector(
        onTap: _listening ? _stopListen : _listen,
        child: AnimatedBuilder(
          animation: _micPulse,
          builder: (_, __) => Transform.scale(
            scale: _listening ? _micPulse.value : 1.0,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: _listening
                    ? [Color(0xFFFF3366), Color(0xFFCC0022)]
                    : _thinking
                    ? [Color(0xFFFFAA00), Color(0xFFCC7700)]
                    : [Color(0xFF00D4FF), Color(0xFF0044CC)],
                ),
                boxShadow: [BoxShadow(
                  color: (_listening ? Color(0xFFFF3366) : Color(0xFF00D4FF)).withOpacity(0.5),
                  blurRadius: 30, spreadRadius: 6,
                )],
              ),
              child: Icon(
                _listening ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white, size: 34,
              ),
            ),
          ),
        ),
      ),
      SizedBox(height: 8),
      Text(
        _listening ? 'To\'xtatish uchun bosing' : 'Gapirish uchun bosing',
        style: TextStyle(color: Colors.white24, fontSize: 11),
      ),
    ]),
  );

  @override
  void dispose() { _btnsCtrl.dispose(); _micCtrl.dispose(); super.dispose(); }
}
