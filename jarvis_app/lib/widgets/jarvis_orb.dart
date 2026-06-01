import 'dart:math';
import 'package:flutter/material.dart';

class JarvisOrb extends StatefulWidget {
  final bool isListening;
  final bool isThinking;
  final bool isSpeaking;
  const JarvisOrb({Key? key, required this.isListening, required this.isThinking, required this.isSpeaking}) : super(key: key);
  @override
  _JarvisOrbState createState() => _JarvisOrbState();
}

class _JarvisOrbState extends State<JarvisOrb> with TickerProviderStateMixin {
  late AnimationController _rotCtrl, _pulseCtrl, _particleCtrl;
  @override
  void initState() {
    super.initState();
    _rotCtrl = AnimationController(duration: Duration(seconds: 6), vsync: this)..repeat();
    _pulseCtrl = AnimationController(duration: Duration(milliseconds: 1200), vsync: this)..repeat(reverse: true);
    _particleCtrl = AnimationController(duration: Duration(seconds: 3), vsync: this)..repeat();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotCtrl, _pulseCtrl, _particleCtrl]),
      builder: (_, __) => CustomPaint(
        size: Size(270, 270),
        painter: OrbPainter(
          rotation: _rotCtrl.value * 2 * pi,
          pulse: _pulseCtrl.value,
          particle: _particleCtrl.value,
          isListening: widget.isListening,
          isThinking: widget.isThinking,
          isSpeaking: widget.isSpeaking,
        ),
      ),
    );
  }
  @override
  void dispose() { _rotCtrl.dispose(); _pulseCtrl.dispose(); _particleCtrl.dispose(); super.dispose(); }
}

class OrbPainter extends CustomPainter {
  final double rotation, pulse, particle;
  final bool isListening, isThinking, isSpeaking;
  OrbPainter({required this.rotation, required this.pulse, required this.particle, required this.isListening, required this.isThinking, required this.isSpeaking});

  Color get color {
    if (isListening) return Color(0xFFFF3366);
    if (isThinking) return Color(0xFFFFAA00);
    if (isSpeaking) return Color(0xFF00FF88);
    return Color(0xFF00D4FF);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    canvas.drawCircle(c, r, Paint()
      ..shader = RadialGradient(colors: [color.withOpacity(0.0), color.withOpacity(0.08 + pulse * 0.08), color.withOpacity(0.0)], stops: [0.4, 0.7, 1.0])
          .createShader(Rect.fromCircle(center: c, radius: r)));

    _ring(canvas, c, r * 0.88, rotation, color, 1.5);
    _ring(canvas, c, r * 0.72, -rotation * 0.8, color.withOpacity(0.7), 1.2);
    _ring(canvas, c, r * 0.56, rotation * 1.4, color.withOpacity(0.5), 0.9);

    _neural(canvas, c, r * 0.65, rotation);
    _particles(canvas, c, r, rotation);

    final coreR = r * 0.32 + pulse * 6;
    canvas.drawCircle(c, coreR, Paint()
      ..shader = RadialGradient(colors: [Colors.white.withOpacity(0.95), color.withOpacity(0.85), color.withOpacity(0.3), Colors.transparent], stops: [0.0, 0.25, 0.6, 1.0])
          .createShader(Rect.fromCircle(center: c, radius: coreR)));

    canvas.drawCircle(c, coreR + 4, Paint()..color = color.withOpacity(0.3 + pulse * 0.3)..style = PaintingStyle.stroke..strokeWidth = 1.0);

    if (isSpeaking || isListening) {
      for (int i = 1; i <= 3; i++) {
        canvas.drawCircle(c, r * 0.35 + i * 15 + pulse * 10, Paint()
          ..color = color.withOpacity((0.3 - i * 0.08) * pulse)
          ..style = PaintingStyle.stroke..strokeWidth = 1.0);
      }
    }
  }

  void _ring(Canvas canvas, Offset c, double r, double angle, Color col, double w) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 0.38),
      Paint()..color = col.withOpacity(0.65)..style = PaintingStyle.stroke..strokeWidth = w);
    canvas.restore();
  }

  void _neural(Canvas canvas, Offset c, double r, double rot) {
    final p = Paint()..color = color.withOpacity(0.12)..strokeWidth = 0.6..style = PaintingStyle.stroke;
    final pts = List.generate(8, (i) {
      final a = (i / 8) * 2 * pi + rot;
      return Offset(c.dx + cos(a) * r, c.dy + sin(a) * r * 0.4);
    });
    for (int i = 0; i < pts.length; i++) {
      canvas.drawLine(pts[i], pts[(i + 3) % pts.length], p);
      canvas.drawLine(pts[i], c, Paint()..color = color.withOpacity(0.07)..strokeWidth = 0.6..style = PaintingStyle.stroke);
    }
  }

  void _particles(Canvas canvas, Offset c, double r, double rot) {
    final rng = Random(42);
    for (int i = 0; i < 14; i++) {
      final a = (i / 14) * 2 * pi + rot + particle * pi * 2;
      final rad = r * (0.45 + rng.nextDouble() * 0.4);
      canvas.drawCircle(Offset(c.dx + cos(a) * rad, c.dy + sin(a) * rad * 0.4),
        1.5 + rng.nextDouble() * 2.5, Paint()..color = color.withOpacity(0.35 + rng.nextDouble() * 0.5));
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
