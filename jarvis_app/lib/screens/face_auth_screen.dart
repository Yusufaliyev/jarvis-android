import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/face_service.dart';
import 'jarvis_screen.dart';

class FaceAuthScreen extends StatefulWidget {
  @override
  _FaceAuthScreenState createState() => _FaceAuthScreenState();
}

class _FaceAuthScreenState extends State<FaceAuthScreen>
    with TickerProviderStateMixin {
  CameraController? _camCtrl;
  bool _ready = false;
  bool _scanning = false;
  bool _done = false;
  String _status = 'Kamera tayyorlanmoqda...';
  String _userName = 'Do\'stim';

  late AnimationController _scanAnim;
  late AnimationController _pulseAnim;
  late Animation<double> _scan;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _scanAnim = AnimationController(duration: Duration(seconds: 2), vsync: this)..repeat();
    _pulseAnim = AnimationController(duration: Duration(milliseconds: 900), vsync: this)..repeat(reverse: true);
    _scan = Tween<double>(begin: 0.0, end: 1.0).animate(_scanAnim);
    _pulse = Tween<double>(begin: 0.96, end: 1.04).animate(_pulseAnim);
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name') ?? 'Do\'stim';

    await FaceService.init();
    final cam = FaceService.frontCamera;

    if (cam == null) {
      setState(() => _status = 'Kamera topilmadi!');
      await Future.delayed(Duration(seconds: 2));
      _goMain('Assalomu alaykum! Men Jarvis. Buyuring!');
      return;
    }

    _camCtrl = CameraController(cam, ResolutionPreset.medium, enableAudio: false);
    try {
      await _camCtrl!.initialize();
      if (mounted) {
        setState(() { _ready = true; _status = 'Yuzingizni kadrga qarating...'; });
        await Future.delayed(Duration(seconds: 2));
        _takePicture();
      }
    } catch (e) {
      _goMain('Assalomu alaykum! Men Jarvis. Buyuring!');
    }
  }

  Future<void> _takePicture() async {
    if (_camCtrl == null || !_camCtrl!.value.isInitialized || _done) return;
    setState(() { _scanning = true; _status = 'Yuz skanlanmoqda...'; });

    try {
      final photo = await _camCtrl!.takePicture();
      final result = await FaceService.analyzeFile(photo.path);
      final greeting = FaceService.getGreeting(result, _userName);

      setState(() { _done = true; _status = '✅ Aniqlandi!'; });
      await Future.delayed(Duration(milliseconds: 700));
      _goMain(greeting);
    } catch (e) {
      _goMain('Assalomu alaykum! Men Jarvis. Buyuring!');
    }
  }

  void _goMain(String greeting) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => JarvisScreen(greeting: greeting),
        transitionDuration: Duration(milliseconds: 800),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF030812),
      body: SafeArea(child: Column(children: [
        // Tepa
        Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('JARVIS', style: TextStyle(
              color: Color(0xFF00D4FF), fontSize: 24,
              fontWeight: FontWeight.bold, letterSpacing: 6,
            )),
            TextButton(
              onPressed: () => _goMain('Assalomu alaykum! Men Jarvis. Buyuring!'),
              child: Text("O'tkazib yuborish",
                style: TextStyle(color: Colors.white24, fontSize: 12)),
            ),
          ]),
        ),

        Expanded(child: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Kamera oyna
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Transform.scale(
                scale: _done ? 1.05 : _pulse.value,
                child: Container(
                  width: 230, height: 290,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _done ? Color(0xFF00FF88) : Color(0xFF00D4FF),
                      width: 2,
                    ),
                    boxShadow: [BoxShadow(
                      color: (_done ? Color(0xFF00FF88) : Color(0xFF00D4FF)).withOpacity(0.35),
                      blurRadius: 25, spreadRadius: 5,
                    )],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(fit: StackFit.expand, children: [
                      // Kamera ko'rinishi
                      if (_ready && _camCtrl != null)
                        CameraPreview(_camCtrl!)
                      else
                        Container(
                          color: Color(0xFF0A1628),
                          child: Icon(Icons.face_rounded, size: 80,
                            color: Color(0xFF00D4FF).withOpacity(0.3)),
                        ),

                      // Skan chizig'i
                      if (_scanning && !_done)
                        AnimatedBuilder(
                          animation: _scan,
                          builder: (_, __) => Positioned(
                            top: 290 * _scan.value,
                            left: 0, right: 0,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(gradient: LinearGradient(colors: [
                                Colors.transparent,
                                Color(0xFF00D4FF).withOpacity(0.9),
                                Colors.transparent,
                              ])),
                            ),
                          ),
                        ),

                      // Yuz doirasi
                      Center(child: Container(
                        width: 150, height: 190,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(75),
                          border: Border.all(
                            color: (_done ? Color(0xFF00FF88) : Color(0xFF00D4FF)).withOpacity(0.6),
                            width: 1.5,
                          ),
                        ),
                      )),

                      // Burchaklar
                      ..._corners(),
                    ]),
                  ),
                ),
              ),
            ),

            SizedBox(height: 28),

            // Status
            AnimatedSwitcher(
              duration: Duration(milliseconds: 400),
              child: Text(_status,
                key: ValueKey(_status),
                style: TextStyle(
                  color: _done ? Color(0xFF00FF88) : Color(0xFF00D4FF),
                  fontSize: 14, letterSpacing: 1.5,
                ),
              ),
            ),

            SizedBox(height: 16),

            if (!_done)
              Row(mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: Color(0xFF00D4FF).withOpacity(
                      0.2 + 0.8 * (((_scanAnim.value * 3 + i) % 1.0))),
                    shape: BoxShape.circle,
                  ),
                )),
              ),
          ],
        ))),
      ])),
    );
  }

  List<Widget> _corners() {
    final color = _done ? Color(0xFF00FF88) : Color(0xFF00D4FF);
    return [
      Positioned(top: 8, left: 8, child: _corner(color, true, true)),
      Positioned(top: 8, right: 8, child: _corner(color, true, false)),
      Positioned(bottom: 8, left: 8, child: _corner(color, false, true)),
      Positioned(bottom: 8, right: 8, child: _corner(color, false, false)),
    ];
  }

  Widget _corner(Color c, bool top, bool left) => SizedBox(
    width: 22, height: 22,
    child: CustomPaint(painter: _CP(c, top, left)),
  );

  @override
  void dispose() {
    _scanAnim.dispose();
    _pulseAnim.dispose();
    _camCtrl?.dispose();
    FaceService.dispose();
    super.dispose();
  }
}

class _CP extends CustomPainter {
  final Color c;
  final bool top, left;
  _CP(this.c, this.top, this.left);

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
