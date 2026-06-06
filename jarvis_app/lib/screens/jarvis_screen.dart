import 'dart:io';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';
import '../services/groq_service.dart';
import '../services/command_service.dart';
import '../services/face_service.dart';
import '../widgets/jarvis_orb.dart';
import 'auth_screen.dart';

class JarvisScreen extends StatefulWidget {
  final String? greeting;
  const JarvisScreen({Key? key, this.greeting}) : super(key: key);
  @override
  State<JarvisScreen> createState() => _JarvisScreenState();
}

class _JarvisScreenState extends State<JarvisScreen>
    with TickerProviderStateMixin {

  // ── Xizmatlar ──────────────────────────────────────────────────
  final SpeechToText  _speech = SpeechToText();
  final FlutterTts    _tts    = FlutterTts();
  final GroqService   _groq   = GroqService();
  final CommandService _cmd   = CommandService();

  // ── Holat o'zgaruvchilari ──────────────────────────────────────
  bool   _listening  = false;
  bool   _thinking   = false;
  bool   _speaking   = false;
  bool   _showBtns   = false;
  bool   _showCamera = false;
  String _userText   = '';
  String _jarvisText = '';
  String _emotion    = '';

  // ── Kamera ────────────────────────────────────────────────────
  CameraController? _cam;
  String?           _photoPath;

  // ── Animatsiya ────────────────────────────────────────────────
  late final AnimationController _btnsCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 450));
  late final Animation<double> _btnsAnim =
      CurvedAnimation(parent: _btnsCtrl, curve: Curves.easeOutBack);

  late final AnimationController _micCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800))
    ..repeat(reverse: true);
  late final Animation<double> _micPulse =
      Tween<double>(begin: 1.0, end: 1.13)
          .animate(CurvedAnimation(parent: _micCtrl, curve: Curves.easeInOut));

  // ── Tez tugmalar ──────────────────────────────────────────────
  static const _quickBtns = [
    {'icon': Icons.send,              'label': 'Telegram',     'cmd': 'telegram'},
    {'icon': Icons.play_circle_fill,  'label': 'YouTube',      'cmd': 'youtube'},
    {'icon': Icons.photo_camera,      'label': 'Kamera',       'cmd': 'kamerani yoq'},
    {'icon': Icons.sms,               'label': 'SMS',          'cmd': 'sms'},
    {'icon': Icons.phone,             'label': 'Qo\'ng\'iroq', 'cmd': 'qo\'ng\'iroq'},
    {'icon': Icons.map,               'label': 'Xarita',       'cmd': 'xarita'},
    {'icon': Icons.cloud,             'label': 'Ob-havo',      'cmd': 'havo qanday'},
    {'icon': Icons.search,            'label': 'Qidir',        'cmd': 'google'},
  ];

  // ══════════════════════════════════════════════════════════════
  //  INIT
  // ══════════════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    final p = await SharedPreferences.getInstance();
    await _tts.setLanguage('uz-UZ');
    await _tts.setSpeechRate(p.getDouble('tts_rate')   ?? 0.88);
    await _tts.setVolume(    p.getDouble('tts_volume')  ?? 1.0);
    await _tts.setPitch(     p.getDouble('tts_pitch')   ?? 1.0);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
    await Future.delayed(const Duration(milliseconds: 900));
    _say(widget.greeting ?? 'Assalomu alaykum! Men Jarvis. Buyuring!');
  }

  // ══════════════════════════════════════════════════════════════
  //  OVOZ
  // ══════════════════════════════════════════════════════════════
  void _say(String text) {
    if (!mounted) return;
    setState(() { _jarvisText = text; _speaking = true; });
    _tts.stop().then((_) => _tts.speak(text));
  }

  Future<void> _startListen() async {
    if (!await Permission.microphone.request().then((s) => s.isGranted)) {
      _say('Mikrofon ruxsati kerak!'); return;
    }
    final ok = await _speech.initialize(
      onError: (_) { if (mounted) setState(() => _listening = false); },
    );
    if (!ok) { _say('Mikrofon ishlamayapti!'); return; }

    if (!mounted) return;
    setState(() { _listening = true; _userText = ''; _showBtns = true; });
    _btnsCtrl.forward();

    _speech.listen(
      onResult: (r) {
        if (!mounted) return;
        setState(() => _userText = r.recognizedWords);
        if (r.finalResult && _userText.isNotEmpty) _run(_userText);
      },
      localeId: 'uz_UZ',
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void _stopListen() {
    _speech.stop();
    if (mounted) setState(() => _listening = false);
  }

  // ══════════════════════════════════════════════════════════════
  //  BUYRUQ BAJARISH
  // ══════════════════════════════════════════════════════════════
  Future<void> _run(String text) async {
    _speech.stop();
    if (!mounted) return;
    setState(() { _listening = false; _thinking = true; _userText = text; });

    final local = await _cmd.execute(text);

    if (local == '__CAMERA__') {
      if (mounted) setState(() => _thinking = false);
      await _openCamera();
    } else if (local != null) {
      if (mounted) setState(() => _thinking = false);
      _say(local);
    } else {
      final ai = await _groq.ask(text);
      if (mounted) setState(() => _thinking = false);
      _say(ai);
    }

    await Future.delayed(const Duration(seconds: 4));
    if (mounted) { _btnsCtrl.reverse(); setState(() => _showBtns = false); }
  }

  // ══════════════════════════════════════════════════════════════
  //  KAMERA
  // ══════════════════════════════════════════════════════════════
  Future<void> _openCamera() async {
    await FaceService.init();
    final camDesc = FaceService.frontCamera;
    if (camDesc == null) { _say('Kamera topilmadi!'); return; }

    final ctrl = CameraController(
        camDesc, ResolutionPreset.medium, enableAudio: false);
    try {
      await ctrl.initialize();
    } catch (_) {
      ctrl.dispose();
      _say('Kamera ishlamadi!');
      return;
    }

    if (!mounted) { ctrl.dispose(); return; }
    setState(() { _cam = ctrl; _showCamera = true; _emotion = ''; _photoPath = null; });
    _say('Kamera yoqildi! Yuzingizni ko\'rsating...');

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted || _cam == null) return;

    try {
      final xfile = await _cam!.takePicture();
      final result = await FaceService.analyzeFile(xfile.path);

      if (!mounted) return;
      setState(() {
        _photoPath = xfile.path;
        _emotion = _emotionLabel(result);
      });
      _say(FaceService.getGreeting(result, 'siz'));
    } catch (_) {
      _say('Yuzni tahlil qilishda xatolik.');
    }
  }

  void _closeCamera() {
    _cam?.dispose();
    if (mounted) setState(() {
      _cam = null;
      _showCamera = false;
      _emotion = '';
      _photoPath = null;
    });
  }

  String _emotionLabel(FaceResult r) => switch (r) {
    FaceResult.happy   => '😊 Xursand',
    FaceResult.tired   => '😴 Charchagan',
    FaceResult.neutral => '😐 Neytral',
    FaceResult.normal  => '🙂 Normal',
    FaceResult.noFace  => '🤔 Yuz topilmadi',
  };

  // ══════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030812),
      body: Stack(children: [
        // Gradient fon
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.35),
              radius: 1.4,
              colors: [Color(0xFF0D1F3C), Color(0xFF030812)],
            ),
          ),
          child: SizedBox.expand(),
        ),

        // Kontent
        SafeArea(child: Column(children: [
          _buildTopBar(),
          Expanded(child: _showCamera ? _buildCameraView() : _buildMainView()),
          if (!_showCamera) _buildCmdButtons(),
          if (!_showCamera) _buildMicButton(),
        ])),
      ]),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────
  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('JARVIS', style: TextStyle(
          color: Color(0xFF00D4FF), fontSize: 26,
          fontWeight: FontWeight.bold, letterSpacing: 6)),
        Text('Sun\'iy Intellekt', style: TextStyle(
          color: Colors.white24, fontSize: 10, letterSpacing: 2)),
      ]),
      Row(children: [
        _iconBtn(Icons.settings_rounded, () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => AuthScreen()))),
        const SizedBox(width: 8),
        _statusBadge(),
      ]),
    ]),
  );

  Widget _iconBtn(IconData icon, VoidCallback fn) => GestureDetector(
    onTap: fn,
    child: Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white12)),
      child: Icon(icon, color: const Color(0xFF00D4FF), size: 20)));

  Widget _statusBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.4)),
      borderRadius: BorderRadius.circular(20),
      color: const Color(0xFF00FF88).withOpacity(0.06)),
    child: Row(children: [
      Container(width: 7, height: 7,
        decoration: const BoxDecoration(
          color: Color(0xFF00FF88), shape: BoxShape.circle)),
      const SizedBox(width: 6),
      const Text('FAOL', style: TextStyle(
        color: Color(0xFF00FF88), fontSize: 12, letterSpacing: 1)),
    ]));

  // ── Asosiy ko'rinish ──────────────────────────────────────────
  Widget _buildMainView() => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Column(children: [
      JarvisOrb(
        isListening: _listening,
        isThinking: _thinking,
        isSpeaking: _speaking),
      const SizedBox(height: 28),
      _buildTextBox(),
      if (_userText.isNotEmpty) ...[
        const SizedBox(height: 10),
        _buildUserText(),
      ],
      const SizedBox(height: 20),
    ]),
  );

  // ── Kamera ko'rinishi ─────────────────────────────────────────
  Widget _buildCameraView() => Column(children: [
    Expanded(child: Padding(
      padding: const EdgeInsets.all(16),
      child: Stack(children: [
        // Kamera yoki rasm
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: _photoPath != null
            ? Image.file(File(_photoPath!),
                width: double.infinity, fit: BoxFit.cover)
            : (_cam != null && _cam!.value.isInitialized
                ? CameraPreview(_cam!)
                : Container(color: const Color(0xFF0A1628),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00D4FF))))),
        ),

        // Yuz doirasi
        Center(child: Container(
          width: 190, height: 230,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(95),
            border: Border.all(
              color: const Color(0xFF00D4FF).withOpacity(0.55),
              width: 1.5)))),

        // Yopish
        Positioned(top: 10, right: 10,
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
          Positioned(bottom: 14, left: 0, right: 0,
            child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(20)),
              child: Text(_emotion, style: const TextStyle(
                color: Colors.white, fontSize: 20, letterSpacing: 2))))),
      ]),
    )),

    // Jarvis javobi
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildTextBox()),

    // Tugmalar
    Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Expanded(child: ElevatedButton.icon(
          onPressed: _closeCamera,
          icon: const Icon(Icons.close, color: Colors.black, size: 18),
          label: const Text('Yopish',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white54,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14))))),
        const SizedBox(width: 10),
        Expanded(child: ElevatedButton.icon(
          onPressed: () { setState(() => _photoPath = null); _openCamera(); },
          icon: const Icon(Icons.refresh, color: Colors.black, size: 18),
          label: const Text('Qayta skan',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D4FF),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14))))),
      ]),
    ),
  ]);

  // ── Matn qutilar ──────────────────────────────────────────────
  Widget _buildTextBox() {
    final String txt = _listening ? '🎙️ Tinglamoqdaman...'
        : _thinking ? '⚡ Fikrlamoqdaman...'
        : _jarvisText.isEmpty
            ? 'Gapirish uchun mikrofon tugmasini bosing'
            : _jarvisText;

    final Color bc = _listening
        ? const Color(0xFFFF3366)
        : _thinking
            ? const Color(0xFFFFAA00)
            : const Color(0xFF00D4FF);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: Container(
        key: ValueKey(txt.hashCode),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: bc.withOpacity(0.25)),
          borderRadius: BorderRadius.circular(20),
          color: bc.withOpacity(0.04)),
        child: Text(txt,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 15, height: 1.7),
          textAlign: TextAlign.center,
          maxLines: 5,
          overflow: TextOverflow.ellipsis)));
  }

  Widget _buildUserText() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22),
    child: Text('🗣️  "$_userText"',
      style: const TextStyle(
        color: Colors.white30, fontSize: 13, fontStyle: FontStyle.italic),
      textAlign: TextAlign.center,
      maxLines: 2, overflow: TextOverflow.ellipsis));

  // ── Buyruq tugmalari ──────────────────────────────────────────
  Widget _buildCmdButtons() => AnimatedBuilder(
    animation: _btnsAnim,
    builder: (_, __) => ClipRect(child: Align(
      heightFactor: _btnsAnim.value.clamp(0.0, 1.0),
      child: Opacity(
        opacity: _btnsAnim.value.clamp(0.0, 1.0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          child: Wrap(
            spacing: 8, runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(_quickBtns.length, (i) {
              final b = _quickBtns[i];
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 260 + i * 30),
                tween: Tween(begin: 0.0, end: _showBtns ? 1.0 : 0.0),
                curve: Curves.easeOutBack,
                builder: (_, v, __) => Transform.scale(scale: v,
                  child: _quickBtn(
                    b['icon'] as IconData,
                    b['label'] as String,
                    b['cmd'] as String)));
            })))))));

  Widget _quickBtn(IconData icon, String label, String cmd) =>
    GestureDetector(
      onTap: () {
        _btnsCtrl.reverse();
        setState(() => _showBtns = false);
        _run(cmd);
      },
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.22)),
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF00D4FF).withOpacity(0.05)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: const Color(0xFF00D4FF), size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(
            color: Colors.white54, fontSize: 10)),
        ])));

  // ── Mikrofon tugmasi ──────────────────────────────────────────
  Widget _buildMicButton() => Padding(
    padding: const EdgeInsets.only(bottom: 26, top: 6),
    child: Column(children: [
      GestureDetector(
        onTap: _listening ? _stopListen : _startListen,
        child: AnimatedBuilder(
          animation: _micPulse,
          builder: (_, __) => Transform.scale(
            scale: _listening ? _micPulse.value : 1.0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _listening
                    ? const [Color(0xFFFF3366), Color(0xFFBB0022)]
                    : _thinking
                      ? const [Color(0xFFFFAA00), Color(0xFFCC7700)]
                      : const [Color(0xFF00D4FF), Color(0xFF0040CC)]),
                boxShadow: [BoxShadow(
                  color: (_listening
                    ? const Color(0xFFFF3366)
                    : const Color(0xFF00D4FF)).withOpacity(0.48),
                  blurRadius: 28, spreadRadius: 4)]),
              child: SizedBox(width: 72, height: 72,
                child: Icon(
                  _listening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white, size: 32))))),
      const SizedBox(height: 6),
      Text(
        _listening ? 'To\'xtatish uchun bosing' : 'Gapirish uchun bosing',
        style: const TextStyle(color: Colors.white24, fontSize: 11)),
    ]));

  // ══════════════════════════════════════════════════════════════
  //  DISPOSE
  // ══════════════════════════════════════════════════════════════
  @override
  void dispose() {
    _btnsCtrl.dispose();
    _micCtrl.dispose();
    _cam?.dispose();
    _tts.stop();
    _speech.stop();
    super.dispose();
  }
}
