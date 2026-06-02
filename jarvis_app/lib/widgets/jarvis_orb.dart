import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class JarvisOrb extends StatefulWidget {
  final bool isListening;
  final bool isThinking;
  final bool isSpeaking;
  const JarvisOrb({
    Key? key,
    required this.isListening,
    required this.isThinking,
    required this.isSpeaking,
  }) : super(key: key);

  @override
  _JarvisOrbState createState() => _JarvisOrbState();
}

class _JarvisOrbState extends State<JarvisOrb>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _rotX = 0;
  double _rotY = 0;
  double _time = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (mounted) {
        setState(() {
          _time = elapsed.inMilliseconds.toDouble();
          _rotX = _time * 0.000003;
          _rotY = _time * 0.000005;
        });
      }
    });
    _ticker.start();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(300, 300),
        painter: SpherePainter(
          rotX: _rotX,
          rotY: _rotY,
          time: _time,
          isListening: isListening,
          isThinking: isThinking,
          isSpeaking: isSpeaking,
        ),
      ),
    );
  }

  bool get isListening => widget.isListening;
  bool get isThinking => widget.isThinking;
  bool get isSpeaking => widget.isSpeaking;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

class SpherePainter extends CustomPainter {
  final double rotX, rotY, time;
  final bool isListening, isThinking, isSpeaking;

  SpherePainter({
    required this.rotX,
    required this.rotY,
    required this.time,
    required this.isListening,
    required this.isThinking,
    required this.isSpeaking,
  });

  // Pre-generated dots (static — faqat bir marta yaratiladi)
  static final List<_Dot> _dots = _generateDots();

  static List<_Dot> _generateDots() {
    const numDots = 400;
    final rng = Random(42);
    List<_Dot> list = [];
    for (int i = 0; i < numDots; i++) {
      final phi = acos(-1 + (2 * i) / numDots);
      final theta = sqrt(numDots * pi) * phi;
      list.add(_Dot(
        x: cos(theta) * sin(phi),
        y: sin(theta) * sin(phi),
        z: cos(phi),
        baseSize: rng.nextDouble() * 1.8 + 0.8,
      ));
    }
    return list;
  }

  Color get _color {
    if (isListening) return const Color(0xFFFF3366);
    if (isThinking) return const Color(0xFFFFAA00);
    if (isSpeaking) return const Color(0xFF00FF88);
    return const Color(0xFF4AF2FF);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.42;

    final cosY = cos(rotY), sinY = sin(rotY);
    final cosX = cos(rotX), sinX = sin(rotX);

    // Barcha nuqtalarni 3D → 2D ga o'tkazish
    final List<_Projected> projected = [];

    for (final dot in _dots) {
      // Koordinatlarni radius bilan kengaytirish
      final dx = dot.x * r;
      final dy = dot.y * r;
      final dz = dot.z * r;

      // Y o'qi atrofida aylantirish
      final x1 = dx * cosY - dz * sinY;
      final z1 = dz * cosY + dx * sinY;

      // X o'qi atrofida aylantirish
      final y2 = dy * cosX - z1 * sinX;
      final z2 = z1 * cosX + dy * sinX;

      // Perspektiv proektsiya
      const fov = 600.0;
      final persp = fov / (fov - z2);
      final px = x1 * persp + cx;
      final py = y2 * persp + cy;

      // Puls effekti (HTML dagi kabi)
      final pulse = sin(dot.y * r * 0.015 + time * 0.005);
      final intensity = pulse.clamp(0.0, 1.0);

      // Chuqurlikka qarab shaffoflik
      final opacity = ((z2 + r) / (r * 2)).clamp(0.05, 1.0);
      final drawSize = dot.baseSize * persp * 0.55;

      projected.add(_Projected(
        x: px, y: py, z: z2,
        size: drawSize,
        intensity: intensity,
        opacity: opacity,
        originalY: dot.y * r,
      ));
    }

    // Z ga qarab saralash (orqa → old)
    projected.sort((a, b) => a.z.compareTo(b.z));

    final color = _color;

    // Oddiy nuqtalar (glow'siz)
    final normalPaint = Paint()..style = PaintingStyle.fill;
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (final p in projected) {
      final s = p.size * (1 + p.intensity * 0.6);

      if (p.intensity > 0.75) {
        // Yorqin nuqtalar — oq rang + glow
        glowPaint.color = Colors.white.withOpacity(p.opacity * 0.95);
        canvas.drawCircle(Offset(p.x, p.y), s, glowPaint);
      } else {
        // Oddiy nuqtalar — asosiy rang
        normalPaint.color = color.withOpacity(p.opacity * 0.65);
        canvas.drawCircle(Offset(p.x, p.y), s, normalPaint);
      }
    }

    // Markaziy yumshoq glow
    final glowGrad = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.15),
          color.withOpacity(0.05),
          Colors.transparent,
        ],
        stops: [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.6));
    canvas.drawCircle(Offset(cx, cy), r * 0.6, glowGrad);
  }

  @override
  bool shouldRepaint(SpherePainter old) =>
      old.rotX != rotX ||
      old.rotY != rotY ||
      old.time != time ||
      old.isListening != isListening ||
      old.isThinking != isThinking ||
      old.isSpeaking != isSpeaking;
}

class _Dot {
  final double x, y, z, baseSize;
  const _Dot({required this.x, required this.y, required this.z, required this.baseSize});
}

class _Projected {
  final double x, y, z, size, intensity, opacity, originalY;
  _Projected({
    required this.x, required this.y, required this.z,
    required this.size, required this.intensity,
    required this.opacity, required this.originalY,
  });
}
