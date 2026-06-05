import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';
import '../services/groq_service.dart';
import '../services/command_service.dart';
import '../services/weather_service.dart';
import '../services/face_service.dart';
import '../widgets/jarvis_orb.dart';
import 'auth_screen.dart';

class JarvisScreen extends StatefulWidget {
  final String? greeting;
  const JarvisScreen({Key? key, this.greeting}) : super(key: key);

  @override
  _JarvisScreenState createState() => _JarvisScreenState();
}

class _JarvisScreenState extends State<JarvisScreen>
    with TickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final GroqService _groq = GroqService();
  final CommandService _cmd = CommandService();

  // Holat
  bool _listening = false;
  bool _thinking = false;
  bool _speaking = false;
  bool _showBtns = false;
  bool _showCamera = false;

  // Kamera
  CameraController? _camCtrl;
  String _emotion = '';

  // Matn
  String _userText = '';
  String _jarvisText = '';

  // Animatsiya
  late AnimationController _btnsCtrl;
  late Animation<double> _btnsAnim;
  late AnimationController _micCtrl;
  late Animation<double> _micPulse;

  @override
  void initState() {
    super.initState();
    _btnsCtrl = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _btnsAnim =
        CurvedAnimation(parent: _btnsCtrl, curve: Curves.easeOutBack);
    _micCtrl = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this)
      ..repeat(reverse: true);
    _micPulse = Tween<double>(begin: 1.0, end: 1.12).animate(
        CurvedAnimation(parent: _micCtrl, curve: Curves.easeInOut));
    _initJarvis();
  }

  Future<void> _initJarvis() async {
    final prefs = await SharedPreferences.getInstance();
    await _tts.setLanguage('uz-UZ');
    await _tts.setSpeechRate(prefs.getDouble('tts_rate') ?? 0.88);
    await _tts.setVolume(prefs.getDouble('tts_volume') ?? 1.0);
    await _tts.setPitch(prefs.getDouble('tts_pitch') ?? 1.0);
    _tts.setCompletionHandler(
        () { if (mounted) setState(() => _speaking = false); });
    await Future.delayed(const Duration(milliseconds: 800));
    _speak(widget.greeting ?? 'Assalomu alaykum! Men Jarvis. Buyuring!');
  }

  Future<void> _speak(String text) async {
    if (!mounted) return;
    setState(() { _jarvisText = text; _speaking = true; });
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _listen() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _speak('Mikrofon ruxsati kerak!');
      return;
    }
    final ok = await _speech.initialize(
        onError: (_) { if (mounted) setState(() => _listening = false); });
    if (!ok) { _speak('Mikrofon ishlamayapti!'); return; }

    setState(() {
      _listening = true;
      _showBtns = true;
      _userText = '';
    });
    _btnsCtrl.forward();

    _speech.listen(
      onResult: (r) {
        if (!mounted) return;
        setState(() => _userText = r.recognizedWords);
        if (r.finalResult && _userText.isNotEmpty) _process(_userText);
      },
      localeId: 'uz_UZ',
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> _stopListen() async {
    await _speech.stop();
    if (mounted) setState(() => _listening = false);
  }

  Future<void> _process(String text) async {
    _speech.stop();
    if (!mounted) return;
    setState(() { _listening = false; _thinking = true; _userText = text; });

    final local = await _cmd.execute(text);

    // In-app kamera buyrug'i
    if (local == '__CAMERA__') {
      if (mounted) setState(() => _thinking = false);
      await _openCamera();
      return;
    }

    if (local != null) {
      if (mounted) setState(() => _thinking = false);
      await _speak(local);
    } else {
      final ai = await _groq.ask(text);
      if (mounted) setState(() => _thinking = false);
      await _speak(ai);
    }

    // Tugmalarni yashirish
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      _btnsCtrl.reverse();
      setState(() => _showBtns = false);
    }
  }

  // ── In-app kamera ─────────────────────────────────────────────
  Future<void> _openCamera() async {
    await FaceService.init();
    final cam = FaceService.frontCamera;
    if (cam == null) {
      await _speak('Kamera topilmadi!');
      return;
    }
    final ctrl = CameraController(cam, ResolutionPreset.medium, enableAudio: false);
    try {
      await ctrl.initialize();
      if (!mounted) { ctrl.dispose(); return; }
      setState(() { _camCtrl = ctrl; _showCamera = true; });
      await _speak('Kamera yoqildi! Yuzingizni ko\'rmoqdaman...');
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      final photo = await _camCtrl!.takePicture();
      final result = await FaceService.analyzeFile(photo.path);

      final emotionText = result == FaceResult.happy ? '😊 Xursand'
          : result == FaceResult.tired ? '😴 Charchagan'
          : result == FaceResult.neutral ? '😐 Neytral'
          : result == FaceResult.noFace ? '🤔 Yuz topilmadi'
          : '🙂 Normal';

      if (mounted) setState(() => _emotion = emotionText);

      final greeting = FaceService.getGreeting(result, 'siz');
      await _speak(greeting);
    } catch (e) {
      await _speak('Kamerada xatolik yuz berdi.');
    }
  }

  void _closeCamera() {
    _camCtrl?.dispose();
    if (mounted) setState(() { _camCtrl = null; _showCamera = false; _emotion = ''; });
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030812),
      body: Stack(children: [
        // Fon
        Container(decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4), radius: 1.5,
            colors: [Color(0xFF0D1F3C), Color(0xFF030812)],
          ),
        )),

        // Asosiy kontent
        SafeArea(child: Column(children: [
          _topBar(),
          Expanded(child: _showCamera ? _cameraView() : _mainView()),
          if (!_showCamera) _cmdButtons(),
          if (!_showCamera) _micButton(),
        ])),
      ]),
    );
  }

  // ── Asosiy ko'rinish ──────────────────────────────────────────
  Widget _mainView() => Center(
    child: SingleChildScrollView(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        JarvisOrb(
          isListening: _listening,
          isThinking: _thinking,
          isSpeaking: _speaking,
        ),
        const SizedBox(height: 28),
        _textBox(),
        if (_userText.isNotEmpty) ...[
          const SizedBox(height: 12),
          _userBox(),
        ],
        const SizedBox(height: 20),
      ]),
    ),
  );

  // ── Kamera ko'rinishi ─────────────────────────────────────────
  Widget _cameraView() => Expanded(
    child: Column(children: [
      // Kamera preview
      Expanded(
        child: Stack(children: [
          // Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _camCtrl != null && _camCtrl!.value.isInitialized
                ? CameraPreview(_camCtrl!)
                : Container(
                    color: const Color(0xFF0A1628),
                    child: const Center(child: CircularProgressIndicator(
                      color: Color(0xFF00D4FF)))),
          ),
          // Burchaklar
          ..._cameraCorners(),
          // Yuz doirasi
          Center(child: Container(
            width: 180, height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(90),
              border: Border.all(
                  color: const Color(0xFF00D4FF).withOpacity(0.6), width: 1.5)),
          )),
          // Yopish tugmasi
          Positioned(top: 12, right: 12,
            child: GestureDetector(
              onTap: _closeCamera,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.close, color: Colors.white, size: 22)))),
          // Xissiyot
          if (_emotion.isNotEmpty)
            Positioned(bottom: 16, left: 0, right: 0,
              child: Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20)),
                child: Text(_emotion, style: const TextStyle(
                  color: Colors.white, fontSize: 18, letterSpacing: 1))))),
        ]),
      ),
      // Jarvis javobi
      Padding(
        padding: const EdgeInsets.all(16),
        child: _textBox(),
      ),
      // Yopish tugmasi
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ElevatedButton.icon(
          onPressed: _closeCamera,
          icon: const Icon(Icons.camera_alt_outlined, color: Colors.black),
          label: const Text('Kamerani yopish',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D4FF),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ),
      ),
    ]),
  ) as Widget;

  List<Widget> _cameraCorners() {
    final c = const Color(0xFF00D4FF);
    return [
      Positioned(top: 8, left: 8, child: _corner(c, true, true)),
      Positioned(top: 8, right: 8, child: _corner(c, true, false)),
      Positioned(bottom: 8, left: 8, child: _corner(c, false, true)),
      Positioned(bottom: 8, right: 8, child: _corner(c, false, false)),
    ];
  }

  Widget _corner(Color c, bool top, bool left) => SizedBox(
    width: 24, height: 24,
    child: CustomPaint(painter: _CornerPainter(c, top, left)));

  // ── Yuqori panel ──────────────────────────────────────────────
  Widget _topBar() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('JARVIS', style: TextStyle(
          color: Color(0xFF00D4FF), fontSize: 26,
          fontWeight: FontWeight.bold, letterSpacing: 6)),
        const Text('Sun\'iy Intellekt', style: TextStyle(
          color: Colors.white24, fontSize: 10, letterSpacing: 2)),
      ]),
      Row(children: [
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => AuthScreen())),
          child: Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.06),
              border: Border.all(color: Colors.white12)),
            child: const Icon(Icons.settings_rounded,
                color: Color(0xFF00D4FF), size: 20))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.35)),
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFF00FF88).withOpacity(0.05)),
          child: Row(children: [
            Container(width: 7, height: 7, decoration: const BoxDecoration(
                color: Color(0xFF00FF88), shape: BoxShape.circle)),
            const SizedBox(width: 7),
            const Text('FAOL', style: TextStyle(
                color: Color(0xFF00FF88), fontSize: 12, letterSpacing: 1)),
          ])),
      ]),
    ]),
  );

  // ── Matn qutisi ───────────────────────────────────────────────
  Widget _textBox() {
    final txt = _listening ? '🎙️ Tinglamoqdaman...'
        : _thinking ? '⚡ Fikrlamoqdaman...'
        : _jarvisText.isEmpty ? 'Gapirish uchun mikrofon tugmasini bosing'
        : _jarvisText;
    final bc = _listening ? const Color(0xFFFF3366)
        : _thinking ? const Color(0xFFFFAA00)
        : const Color(0xFF00D4FF);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(txt.hashCode),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: bc.withOpacity(0.25)),
          borderRadius: BorderRadius.circular(22),
          color: bc.withOpacity(0.04)),
        child: Text(txt,
          style: TextStyle(color: Colors.white.withOpacity(0.88),
              fontSize: 15, height: 1.7),
          textAlign: TextAlign.center,
          maxLines: 5, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Widget _userBox() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Text('🗣️  "$_userText"',
      style: const TextStyle(color: Colors.white30, fontSize: 13,
          fontStyle: FontStyle.italic),
      textAlign: TextAlign.center, maxLines: 2,
      overflow: TextOverflow.ellipsis),
  );

  // ── Buyruq tugmalari (yashirin) ───────────────────────────────
  final List<Map<String, dynamic>> _btns = const [
    {'icon': Icons.send_rounded,        'label': 'Telegram',    'cmd': 'telegram'},
    {'icon': Icons.play_circle_rounded, 'label': 'YouTube',     'cmd': 'youtube'},
    {'icon': Icons.photo_camera_rounded,'label': 'Kamera',      'cmd': 'kamera'},
    {'icon': Icons.message_rounded,     'label': 'SMS',         'cmd': 'sms yubor'},
    {'icon': Icons.phone_rounded,       'label': 'Qo\'ng\'iroq','cmd': 'qo\'ng\'iroq'},
    {'icon': Icons.map_rounded,         'label': 'Xarita',      'cmd': 'xarita'},
    {'icon': Icons.cloud_rounded,       'label': 'Ob-havo',     'cmd': 'havo qanday'},
    {'icon': Icons.search_rounded,      'label': 'Qidir',       'cmd': 'google'},
  ];

  Widget _cmdButtons() => AnimatedBuilder(
    animation: _btnsAnim,
    builder: (_, __) => ClipRect(child: Align(
      heightFactor: _btnsAnim.value,
      child: Opacity(
        opacity: _btnsAnim.value.clamp(0.0, 1.0),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          child: Wrap(
            spacing: 8, runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _btns.asMap().entries.map((e) =>
              TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 280 + e.key * 35),
                tween: Tween(begin: 0.0, end: _showBtns ? 1.0 : 0.0),
                curve: Curves.easeOutBack,
                builder: (_, v, __) => Transform.scale(scale: v,
                  child: _cmdBtn(
                    e.value['icon'] as IconData,
                    e.value['label'] as String,
                    e.value['cmd'] as String)),
              )).toList()),
      ),
    )),
  );

  Widget _cmdBtn(IconData icon, String label, String cmd) =>
    GestureDetector(
      onTap: () {
        _btnsCtrl.reverse();
        setState(() => _showBtns = false);
        _process(cmd);
      },
      child: Container(
        width: 78, padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.25)),
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF00D4FF).withOpacity(0.06)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: const Color(0xFF00D4FF), size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ])));

  // ── Mikrofon ──────────────────────────────────────────────────
  Widget _micButton() => Padding(
    padding: const EdgeInsets.only(bottom: 28, top: 8),
    child: Column(children: [
      GestureDetector(
        onTap: _listening ? _stopListen : _listen,
        child: AnimatedBuilder(
          animation: _micPulse,
          builder: (_, __) => Transform.scale(
            scale: _listening ? _micPulse.value : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: _listening
                    ? [const Color(0xFFFF3366), const Color(0xFFCC0022)]
                    : _thinking
                      ? [const Color(0xFFFFAA00), const Color(0xFFCC7700)]
                      : [const Color(0xFF00D4FF), const Color(0xFF0044CC)]),
                boxShadow: [BoxShadow(
                  color: (_listening ? const Color(0xFFFF3366) : const Color(0xFF00D4FF)).withOpacity(0.5),
                  blurRadius: 28, spreadRadius: 5)]),
              child: Icon(
                _listening ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white, size: 32)))),
      const SizedBox(height: 6),
      Text(
        _listening ? 'To\'xtatish uchun bosing' : 'Gapirish uchun bosing',
        style: const TextStyle(color: Colors.white24, fontSize: 11)),
    ]),
  );

  @override
  void dispose() {
    _btnsCtrl.dispose();
    _micCtrl.dispose();
    _camCtrl?.dispose();
    _tts.stop();
    _speech.stop();
    super.dispose();
  }
}

// ── Burchak rasmi ─────────────────────────────────────────────────────────

class _CornerPainter extends CustomPainter {
  final Color c;
  final bool top, left;
  _CornerPainter(this.c, this.top, this.left);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = c..strokeWidth = 2..style = PaintingStyle.stroke;
    final path = Path();
    if (top && left) { path.moveTo(0, size.height); path.lineTo(0, 0); path.lineTo(size.width, 0); }
    else if (top) { path.moveTo(0, 0); path.lineTo(size.width, 0); path.lineTo(size.width, size.height); }
    else if (left) { path.moveTo(0, 0); path.lineTo(0, size.height); path.lineTo(size.width, size.height); }
    else { path.moveTo(0, size.height); path.lineTo(size.width, size.height); path.lineTo(size.width, 0); }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_) => false;
}
