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
  CameraController? _cameraCtrl;
  bool _scanning = false;
  bool _detected = false;
  String _status = 'Yuzingizni kameraga qarating...';
  String _userName = 'Foydalanuvchi';

  late AnimationController _scanAnim;
  late AnimationController _pulseAnim;
  late Animation<double> _scanLine;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _scanAnim = AnimationController(
      duration: Duration(seconds: 2), vsync: this)..repeat();
    _pulseAnim = AnimationController(
      duration: Duration(milliseconds: 800), vsync: this)..repeat(reverse: true);
    _scanLine = Tween<double>(begin: 0, end: 1).animate(_scanAnim);
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(_pulseAnim);
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name') ?? 'Do\'stim';

    await FaceService.init();
    final cam = FaceService.frontCamera;
    if (cam == null) {
      setState(() => _status = 'Kamera topilmadi!');
      return;
    }

    _cameraCtrl = CameraController(cam, ResolutionPreset.medium);
    await _cameraCtrl!.initialize();

    if (mounted) {
      setState(() => _scanning = true);
      _startFaceDetection();
    }
  }

  Future<void> _startFaceDetection() async {
    if (_cameraCtrl == null || !_cameraCtrl!.value.isInitialized) return;

    setState(() => _status = 'Yuz skanlanmoqda...');

    await _cameraCtrl!.startImageStream((image) async {
      if (_detected) return;
      final result = await FaceService.analyzeFace(image);

      if (result != FaceResult.noFace) {
        setState(() => _detected = true);
        await _cameraCtrl!.stopImageStream();
        await Future.delayed(Duration(milliseconds: 500));
        _onFaceDetected(result);
      }
    });
  }

  void _onFaceDetected(FaceResult result) async {
    final greeting = FaceService.getGreeting(result, _userName);
    setState(() => _status = '✅ Yuz aniqlandi!');

    await Future.delayed(Duration(milliseconds: 800));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => JarvisScreen(greeting: greeting),
          transitionDuration: Duration(milliseconds: 800),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  void _skip() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => JarvisScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF030812),
      body: SafeArea(
        child: Column(
          children: [
            // Sarlavha
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('JARVIS', style: TextStyle(
                    color: Color(0xFF00D4FF), fontSize: 24,
                    fontWeight: FontWeight.bold, letterSpacing: 6,
                  )),
                  TextButton(
                    onPressed: _skip,
                    child: Text('O\'tkazib yuborish',
                      style: TextStyle(color: Colors.white30, fontSize: 12)),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Kamera ko'rinishi
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) => Transform.scale(
                        scale: _detected ? 1.05 : _pulse.value,
                        child: Container(
                          width: 240,
                          height: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _detected
                                ? Color(0xFF00FF88)
                                : Color(0xFF00D4FF),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_detected
                                  ? Color(0xFF00FF88)
                                  : Color(0xFF00D4FF)).withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Kamera preview
                                if (_cameraCtrl != null &&
                                    _cameraCtrl!.value.isInitialized)
                                  CameraPreview(_cameraCtrl!)
                                else
                                  Container(
                                    color: Color(0xFF0A1628),
                                    child: Icon(
                                      Icons.face_rounded,
                                      size: 80,
                                      color: Color(0xFF00D4FF).withOpacity(0.3),
                                    ),
                                  ),

                                // Skan chizig'i
                                if (_scanning && !_detected)
                                  AnimatedBuilder(
                                    animation: _scanLine,
                                    builder: (_, __) => Positioned(
                                      top: 300 * _scanLine.value,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: 2,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              Color(0xFF00D4FF).withOpacity(0.8),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                // Yuz doirasi
                                Center(
                                  child: Container(
                                    width: 160,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(80),
                                      border: Border.all(
                                        color: (_detected
                                          ? Color(0xFF00FF88)
                                          : Color(0xFF00D4FF)).withOpacity(0.5),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),

                                // To'rlar (scan grid)
                                Positioned(
                                  top: 8, left: 8,
                                  child: _corner(true, true),
                                ),
                                Positioned(
                                  top: 8, right: 8,
                                  child: _corner(true, false),
                                ),
                                Positioned(
                                  bottom: 8, left: 8,
                                  child: _corner(false, true),
                                ),
                                Positioned(
                                  bottom: 8, right: 8,
                                  child: _corner(false, false),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 30),

                    // Status
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 400),
                      child: Text(
                        _status,
                        key: ValueKey(_status),
                        style: TextStyle(
                          color: _detected
                            ? Color(0xFF00FF88)
                            : Color(0xFF00D4FF),
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    SizedBox(height: 12),

                    if (!_detected && _scanning)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) =>
                          TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 600),
                            tween: Tween(begin: 0.3, end: 1.0),
                            curve: Curves.easeInOut,
                            builder: (_, v, __) => Container(
                              margin: EdgeInsets.symmetric(horizontal: 3),
                              width: 6, height: 6,
                              decoration: BoxDecoration(
                                color: Color(0xFF00D4FF).withOpacity(v),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _corner(bool top, bool left) {
    return SizedBox(
      width: 20, height: 20,
      child: CustomPaint(
        painter: _CornerPainter(top: top, left: left),
      ),
    );
  }

  @override
  void dispose() {
    _scanAnim.dispose();
    _pulseAnim.dispose();
    _cameraCtrl?.dispose();
    FaceService.dispose();
    super.dispose();
  }
}

class _CornerPainter extends CustomPainter {
  final bool top, left;
  _CornerPainter({required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF00D4FF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (top && left) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (top && !left) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!top && left) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
