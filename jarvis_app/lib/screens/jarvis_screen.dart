import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';

// Ensure these paths match your project structure
import '../services/groq_service.dart';
import '../services/command_service.dart';
import '../services/face_service.dart';
import '../widgets/jarvis_orb.dart';
import 'auth_screen.dart';

class JarvisScreen extends StatefulWidget {
  final String? greeting;
  const JarvisScreen({Key? key, this.greeting}) : super(key: key);

  @override
  _JarvisScreenState createState() => _JarvisScreenState();
}

class _JarvisScreenState extends State<JarvisScreen> with TickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final GroqService _groq = GroqService();
  final CommandService _cmd = CommandService();

  bool _listening = false;
  bool _thinking = false;
  bool _speaking = false;
  bool _showBtns = false;
  bool _showCamera = false;

  CameraController? _camCtrl;
  String _emotion = '';
  String _userText = '';
  String _jarvisText = '';

  late AnimationController _btnsCtrl;
  late Animation<double> _btnsAnim;
  late AnimationController _micCtrl;
  late Animation<double> _micPulse;

  @override
  void initState() {
    super.initState();
    _btnsCtrl = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _btnsAnim = CurvedAnimation(parent: _btnsCtrl, curve: Curves.easeOutBack);
    
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
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
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
    if (!ok) return;

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
    await _speech.stop();
    if (!mounted) return;
    setState(() { _listening = false; _thinking = true; _userText = text; });

    final local = await _cmd.execute(text);

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

    await Future.delayed(const Duration(seconds: 4));
    if (mounted && !_listening) {
      _btnsCtrl.reverse();
      setState(() => _showBtns = false);
    }
  }

  Future<void> _openCamera() async {
    await FaceService.init();
    final cam = FaceService.frontCamera;
    if (cam == null) {
      _speak('Kamera topilmadi!');
      return;
    }
    final ctrl = CameraController(cam, ResolutionPreset.medium, enableAudio: false);
    try {
      await ctrl.initialize();
      if (!mounted) { await ctrl.dispose(); return; }
      setState(() { _camCtrl = ctrl; _showCamera = true; });
      await _speak('Kamera yoqildi!');
      
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted || _camCtrl == null) return;

      final photo = await _camCtrl!.takePicture();
      final result = await FaceService.analyzeFile(photo.path);

      if (mounted) {
        setState(() {
          _emotion = result == FaceResult.happy ? '😊 Xursand'
              : result == FaceResult.tired ? '😴 Charchagan'
              : result == FaceResult.neutral ? '😐 Neytral'
              : result == FaceResult.noFace ? '🤔 Noaniq' : '🙂 Normal';
        });
      }
      await _speak(FaceService.getGreeting(result, 'siz'));
    } catch (e) {
      _speak('Kamerada xatolik.');
    }
  }

  void _closeCamera() {
    _camCtrl?.dispose();
    if (mounted) setState(() { _camCtrl = null; _showCamera = false; _emotion = ''; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030812),
      body: Stack(children: [
        Container(decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4), radius: 1.5,
            colors: [Color(0xFF0D1F3C), Color(0xFF030812)],
          ),
        )),
        SafeArea(
          child: Column(children: [
            _topBar(),
            Expanded(child: _showCamera ? _cameraView() : _mainView()),
            if (!_showCamera) _cmdButtons(),
            if (!_showCamera) _micButton(),
          ]),
        ),
      ]),
    );
  }

  Widget _mainView() => Center(
    child: SingleChildScrollView(
      child: Column(children: [
        JarvisOrb(isListening: _listening, isThinking: _thinking, isSpeaking: _speaking),
        const SizedBox(height: 28),
        _textBox(),
        if (_userText.isNotEmpty) ...[
          const SizedBox(height: 12),
          _userBox(),
        ],
      ]),
    ),
  );

  Widget _cameraView() => Column(children: [
    Expanded(
      child: Stack(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: (_camCtrl != null && _camCtrl!.value.isInitialized)
              ? CameraPreview(_camCtrl!)
              : Container(color: Colors.black26),
        ),
        Center(child: Container(
          width: 180, height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(90),
            border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.5), width: 2)),
        )),
        if (_emotion.isNotEmpty)
          Positioned(bottom: 20, left: 0, right: 0,
            child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
              child: Text(_emotion, style: const TextStyle(color: Colors.white, fontSize: 16))))),
      ]),
    ),
    const SizedBox(height: 10),
    ElevatedButton(onPressed: _closeCamera, child: const Text("Yopish")),
    const SizedBox(height: 10),
  ]);

  Widget _topBar() => Padding(
    padding: const EdgeInsets.all(20),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      const Text('JARVIS', style: TextStyle(color: Color(0xFF00D4FF), fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 4)),
      GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen())),
        child: const Icon(Icons.settings, color: Colors.white54),
      ),
    ]),
  );

  Widget _textBox() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 30),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
    child: Text(_listening ? "Eshitmoqdaman..." : _jarvisText, 
      textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 15)),
  );

  Widget _userBox() => Text('🗣️ "$_userText"', style: const TextStyle(color: Colors.white38, fontSize: 12));

  Widget _cmdButtons() => AnimatedBuilder(
    animation: _btnsAnim,
    builder: (context, child) => Opacity(
      opacity: _btnsAnim.value,
      child: Wrap(
        spacing: 10,
        children: [
          _cmdBtn(Icons.camera, "Kamera", "kamera"),
          _cmdBtn(Icons.map, "Xarita", "xarita"),
        ],
      ),
    ),
  );

  Widget _cmdBtn(IconData icon, String label, String cmd) => GestureDetector(
    onTap: () => _process(cmd),
    child: Column(children: [
      CircleAvatar(backgroundColor: Colors.white10, child: Icon(icon, color: const Color(0xFF00D4FF))),
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
    ]),
  );

  Widget _micButton() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: GestureDetector(
      onTap: _listening ? _stopListen : _listen,
      child: ScaleTransition(
        scale: _micPulse,
        child: CircleAvatar(
          radius: 35,
          backgroundColor: _listening ? Colors.redAccent : const Color(0xFF00D4FF),
          child: Icon(_listening ? Icons.stop : Icons.mic, color: Colors.white, size: 30),
        ),
      ),
    ),
  );

  @override
  void dispose() {
    _btnsCtrl.dispose();
    _micCtrl.dispose();
    _camCtrl?.dispose();
    _tts.stop();
    super.dispose();
  }
}

class _CornerPainter extends CustomPainter {
  final Color c; final bool top, left;
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
  @override bool shouldRepaint(_) => false;
}
