import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/groq_service.dart';
import '../services/command_service.dart';

class JarvisScreen extends StatefulWidget {
  @override
  _JarvisScreenState createState() => _JarvisScreenState();
}

class _JarvisScreenState extends State<JarvisScreen>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final GroqService _groq = GroqService();
  final CommandService _cmd = CommandService();

  bool _listening = false;
  bool _thinking = false;
  String _userText = '';
  String _jarvisText = 'Salom! Men Jarvis. Buyuring!';

  late AnimationController _orbCtrl;
  late Animation<double> _orbAnim;

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      duration: Duration(seconds: 2), vsync: this)..repeat(reverse: true);
    _orbAnim = Tween<double>(begin: 0.95, end: 1.05).animate(_orbCtrl);
    _initJarvis();
  }

  Future<void> _initJarvis() async {
    await _tts.setLanguage('uz-UZ');
    await _tts.setSpeechRate(0.85);
    await Future.delayed(Duration(milliseconds: 500));
    await _speak('Assalomu alaykum! Men Jarvis. Bugun sizga qanday yordam bera olaman?');
  }

  Future<void> _speak(String text) async {
    setState(() => _jarvisText = text);
    await _tts.speak(text);
  }

  Future<void> _listen() async {
    bool ok = await _speech.initialize();
    if (!ok) { await _speak('Mikrofon ishlamayapti'); return; }
    setState(() { _listening = true; _userText = ''; });
    _speech.listen(
      onResult: (r) {
        setState(() => _userText = r.recognizedWords);
        if (r.finalResult && _userText.isNotEmpty) _process(_userText);
      },
      localeId: 'uz_UZ',
      listenFor: Duration(seconds: 10),
    );
  }

  Future<void> _process(String text) async {
    _speech.stop();
    setState(() { _listening = false; _thinking = true; });
    String? local = await _cmd.execute(text);
    if (local != null) {
      setState(() => _thinking = false);
      await _speak(local);
    } else {
      String ai = await _groq.ask(text);
      setState(() => _thinking = false);
      await _speak(ai);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF050A18),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(child: Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _orbWidget(),
                SizedBox(height: 30),
                _jarvisBox(),
                SizedBox(height: 15),
                if (_userText.isNotEmpty) _userBox(),
              ],
            ))),
            _quickBtns(),
            _micBtn(),
          ],
        ),
      ),
    );
  }

  Widget _topBar() => Padding(
    padding: EdgeInsets.all(16),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('JARVIS', style: TextStyle(
        color: Color(0xFF00D4FF), fontSize: 22,
        fontWeight: FontWeight.bold, letterSpacing: 5,
      )),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFF00FF88).withOpacity(0.5)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('● FAOL', style: TextStyle(color: Color(0xFF00FF88), fontSize: 12)),
      ),
    ]),
  );

  Widget _orbWidget() => AnimatedBuilder(
    animation: _orbAnim,
    builder: (_, __) => Transform.scale(
      scale: _listening ? 1.15 : (_thinking ? 1.05 : _orbAnim.value),
      child: Container(
        width: 160, height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            _listening ? Colors.red : Color(0xFF00D4FF),
            Color(0xFF0050FF), Color(0xFF050A18),
          ]),
          boxShadow: [BoxShadow(
            color: (_listening ? Colors.red : Color(0xFF00D4FF)).withOpacity(0.6),
            blurRadius: 50, spreadRadius: 15,
          )],
        ),
        child: Icon(
          _listening ? Icons.mic : (_thinking ? Icons.psychology : Icons.face),
          size: 70, color: Colors.white,
        ),
      ),
    ),
  );

  Widget _jarvisBox() => Container(
    margin: EdgeInsets.symmetric(horizontal: 20),
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: Color(0xFF00D4FF).withOpacity(0.3)),
      borderRadius: BorderRadius.circular(16),
      color: Color(0xFF00D4FF).withOpacity(0.05),
    ),
    child: Text(
      _thinking ? '⏳ Fikrlayapman...' :
      _listening ? '🎙️ Tinglamoqdaman...' : _jarvisText,
      style: TextStyle(color: Colors.white, fontSize: 15, height: 1.6),
      textAlign: TextAlign.center,
    ),
  );

  Widget _userBox() => Padding(
    padding: EdgeInsets.symmetric(horizontal: 20),
    child: Text('🗣️ "$_userText"',
      style: TextStyle(color: Colors.white38, fontSize: 13, fontStyle: FontStyle.italic),
      textAlign: TextAlign.center,
    ),
  );

  Widget _quickBtns() {
    final btns = [
      {'icon': Icons.send, 'label': 'Telegram', 'cmd': 'Telegram'},
      {'icon': Icons.play_circle_fill, 'label': 'YouTube', 'cmd': 'YouTube'},
      {'icon': Icons.camera_alt, 'label': 'Kamera', 'cmd': 'Kamera'},
      {'icon': Icons.sms, 'label': 'SMS', 'cmd': 'SMS'},
    ];
    return Container(
      height: 75,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: btns.map((b) => GestureDetector(
          onTap: () => _process(b['cmd'] as String),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(b['icon'] as IconData, color: Color(0xFF00D4FF), size: 26),
            SizedBox(height: 4),
            Text(b['label'] as String,
              style: TextStyle(color: Colors.white54, fontSize: 11)),
          ]),
        )).toList(),
      ),
    );
  }

  Widget _micBtn() => Padding(
    padding: EdgeInsets.only(bottom: 30, top: 10),
    child: GestureDetector(
      onTap: _listening ? () => _speech.stop() : _listen,
      child: Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: _listening
            ? [Color(0xFFFF4444), Color(0xFFCC0000)]
            : [Color(0xFF00D4FF), Color(0xFF0050FF)]),
          boxShadow: [BoxShadow(
            color: (_listening ? Colors.red : Color(0xFF00D4FF)).withOpacity(0.5),
            blurRadius: 25, spreadRadius: 5,
          )],
        ),
        child: Icon(_listening ? Icons.stop : Icons.mic,
          color: Colors.white, size: 38),
      ),
    ),
  );

  @override
  void dispose() { _orbCtrl.dispose(); super.dispose(); }
}
