import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'jarvis_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainCtrl, _rotCtrl, _textCtrl;
  late Animation<double> _scale, _opacity, _textFade;

  @override
  void initState() {
    super.initState();
    _mainCtrl = AnimationController(duration: Duration(milliseconds: 1800), vsync: this);
    _rotCtrl = AnimationController(duration: Duration(seconds: 6), vsync: this)..repeat();
    _textCtrl = AnimationController(duration: Duration(milliseconds: 1000), vsync: this);

    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainCtrl, curve: Curves.elasticOut));
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainCtrl, curve: Interval(0.0, 0.4)));
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(_textCtrl);

    _mainCtrl.forward().then((_) => _textCtrl.forward());

    Timer(Duration(milliseconds: 3800), () {
      if (mounted) Navigator.pushReplacement(context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => JarvisScreen(),
          transitionDuration: Duration(milliseconds: 900),
          transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: ScaleTransition(scale: Tween(begin: 1.05, end: 1.0).animate(anim), child: child)),
        ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF030812),
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_mainCtrl, _rotCtrl, _textCtrl]),
          builder: (_, __) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: _opacity.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: CustomPaint(size: Size(200, 200), painter: _SplashOrb(_rotCtrl.value * 2 * pi)),
                ),
              ),
              SizedBox(height: 45),
              Opacity(
                opacity: _textFade.value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - _textFade.value)),
                  child: Column(children: [
                    Text('J.A.R.V.I.S', style: TextStyle(
                      color: Color(0xFF00D4FF), fontSize: 38,
                      fontWeight: FontWeight.bold, letterSpacing: 10,
                    )),
                    SizedBox(height: 8),
                    Text('SUN\'IY INTELLEKT ASSISTANT', style: TextStyle(
                      color: Colors.white24, fontSize: 11, letterSpacing: 4,
                    )),
                    SizedBox(height: 35),
                    Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) => AnimatedContainer(
                        duration: Duration(milliseconds: 400),
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                          color: Color(0xFF00D4FF).withOpacity(
                            0.2 + 0.8 * sin((_rotCtrl.value * 6 + i * 2) % (2 * pi)).abs()),
                          shape: BoxShape.circle,
                        ),
                      )),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() { _mainCtrl.dispose(); _rotCtrl.dispose(); _textCtrl.dispose(); super.dispose(); }
}

class _SplashOrb extends CustomPainter {
  final double r;
  _SplashOrb(this.r);
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final rad = size.width / 2;
    final color = Color(0xFF00D4FF);

    canvas.drawCircle(c, rad, Paint()
      ..shader = RadialGradient(colors: [color.withOpacity(0.2), Colors.transparent])
          .createShader(Rect.fromCircle(center: c, radius: rad)));

    for (int i = 0; i < 4; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(r + i * pi / 4);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: (rad * 0.85 - i * 12) * 2, height: (rad * 0.85 - i * 12) * 0.38),
        Paint()..color = color.withOpacity(0.6 - i * 0.1)..style = PaintingStyle.stroke..strokeWidth = 1.5,
      );
      canvas.restore();
    }

    canvas.drawCircle(c, rad * 0.28, Paint()
      ..shader = RadialGradient(colors: [Colors.white.withOpacity(0.95), color.withOpacity(0.8), Colors.transparent])
          .createShader(Rect.fromCircle(center: c, radius: rad * 0.28)));
  }
  @override
  bool shouldRepaint(_) => true;
}
