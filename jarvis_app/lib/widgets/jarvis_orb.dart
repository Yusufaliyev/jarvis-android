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
  int _statusIndex = 0;

  // HTML dagi tasks[] ro'yxati — o'zbek tilida
  final List<String> _statuses = [
    "Neyron og'irliklari ishga tushdi...",
    "Kontekst tahlil qilinmoqda...",
    "Vektor fazosi qidirilmoqda...",
    "Javob optimizatsiya qilinmoqda...",
    "Bilimlar sintezi amalga oshirilmoqda...",
    "Parametrlar sozlanmoqda...",
    "Ehtimollik taqsimoti baholanmoqda...",
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      setState(() {
        _time = elapsed.inMilliseconds.toDouble();
        // HTML: rotationX += 0.003; rotationY += 0.005;
        _rotX += 0.003;
        _rotY += 0.005;
        // Status matnni har 3 soniyada almashtirish
        _statusIndex = (_time / 3000).floor() % _statuses.length;
      });
    });
    _ticker.start();
  }

  @override
  Widget build(BuildContext context) {
    final statusMsg = widget.isListening
        ? "Ovozni qayta ishlamoqda..."
        : widget.isThinking
            ? "Fikrlamoqda..."
            : widget.isSpeaking
                ? "Javob tayyorlanmoqda..."
                : _statuses[_statusIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 3D Shar
        CustomPaint(
          size: const Size(300, 300),
          painter: _SpherePainter(
            rotX: _rotX,
            rotY: _rotY,
            time: _time,
            isListening: widget.isListening,
            isThinking: widget.isThinking,
            isSpeaking: widget.isSpeaking,
          ),
        ),
        const SizedBox(height: 14),
        // HTML dagi #status-text
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: Text(
            statusMsg,
            key: ValueKey(statusMsg),
            style: TextStyle(
              color: const Color(0xFF4AF2FF).withOpacity(0.75),
              fontSize: 11,
              letterSpacing: 1.8,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

// ─── CustomPainter ─────────────────────────────────────────────────────────

class _SpherePainter extends CustomPainter {
  final double rotX, rotY, time;
  final bool isListening, isThinking, isSpeaking;

  _SpherePainter({
    required this.rotX,
    required this.rotY,
    required this.time,
    required this.isListening,
    required this.isThinking,
    required this.isSpeaking,
  });

  // HTML: 600 nuqtali Fibonacci shar — bir marta yaratiladi
  static final List<_Dot> _dots = _buildDots();

  static List<_Dot> _buildDots() {
    const numDots = 600;
    final rng = Random(42);
    final list = <_Dot>[];
    for (int i = 0; i < numDots; i++) {
      final phi = acos(-1 + (2 * i) / numDots);
      final theta = sqrt(numDots * pi) * phi;
      list.add(_Dot(
        // Normalized koordinatalar [-1, 1]
        x: cos(theta) * sin(phi),
        y: sin(theta) * sin(phi),
        z: cos(phi),
        // HTML: Math.random() * 2 + 1
        baseSize: rng.nextDouble() * 2 + 1,
      ));
    }
    return list;
  }

  // Holatga qarab asosiy rang
  Color get _primaryColor {
    if (isListening) return const Color(0xFFFF3366);
    if (isThinking) return const Color(0xFFFFAA00);
    if (isSpeaking) return const Color(0xFF00FF88);
    return const Color(0xFF4AF2FF); // HTML: #4af2ff
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // HTML: radius = 400 (canvas 1600x1600 da)
    // Flutter: 300x300 uchun proportional
    final radius = size.width * 0.43;

    // HTML: perspective = 1500 / (1500 - z2)
    // radius bilan scale qilamiz: fov = 1500 * (radius/400)
    final fov = 1500.0 * (radius / 400.0);

    final cosY = cos(rotY);
    final sinY = sin(rotY);
    final cosX = cos(rotX);
    final sinX = sin(rotX);

    final color = _primaryColor;

    // HTML: subtle background glow
    final bgGrad = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF142840).withOpacity(0.15),
          Colors.transparent,
        ],
      ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius * 1.5));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), bgGrad);

    // Har bir nuqtani 3D → 2D ga proyeksiya qilish
    final projected = <_Projected>[];

    for (final dot in _dots) {
      // Radius bilan kengaytirish (normalized → real)
      final dx = dot.x * radius;
      final dy = dot.y * radius;
      final dz = dot.z * radius;

      // HTML: Rotate Y
      // x1 = dot.x * cos(rotY) - dot.z * sin(rotY)
      // z1 = dot.z * cos(rotY) + dot.x * sin(rotY)
      final x1 = dx * cosY - dz * sinY;
      final z1 = dz * cosY + dx * sinY;

      // HTML: Rotate X
      // y2 = dot.y * cos(rotX) - z1 * sin(rotX)
      // z2 = z1 * cos(rotX) + dot.y * sin(rotX)
      final y2 = dy * cosX - z1 * sinX;
      final z2 = z1 * cosX + dy * sinX;

      // HTML: perspective = 1500 / (1500 - z2)
      final perspective = fov / (fov - z2);
      final px = x1 * perspective + cx;
      final py = y2 * perspective + cy;

      // HTML: pulse = sin(dot.original.y * 0.01 + time * 0.005)
      // dot.original.y HTML da radius birligida, biz dy ishlatamiz
      final pulse = sin(dy * 0.01 + time * 0.005);

      // HTML: intensity = Math.max(0.1, pulse)
      final intensity = max(0.1, pulse);

      // HTML: opacity = Math.max(0, (dot.z + radius) / (radius * 2))
      final opacity = max(0.0, (z2 + radius) / (radius * 2));

      // HTML: size = dot.original.baseSize * dot.perspective
      final dotSize = dot.baseSize * perspective;

      projected.add(_Projected(
        x: px, y: py, z: z2,
        size: dotSize,
        intensity: intensity,
        opacity: opacity,
      ));
    }

    // HTML: projectedDots.sort((a, b) => a.z - b.z)
    projected.sort((a, b) => a.z.compareTo(b.z));

    // Rasmga chizish
    final normalPaint = Paint()..style = PaintingStyle.fill;
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    for (final p in projected) {
      // HTML: size * (1 + intensity * 0.5)
      final s = (p.size * (1 + p.intensity * 0.5)).clamp(0.2, 9.0);

      if (p.intensity > 0.8) {
        // HTML: fillStyle = rgba(255,255,255,opacity) + shadowBlur=15 + shadowColor=#4af2ff
        glowPaint.color = Colors.white.withOpacity(p.opacity.clamp(0.0, 1.0));
        canvas.drawCircle(Offset(p.x, p.y), s, glowPaint);
      } else {
        // HTML: fillStyle = rgba(74, 242, 255, opacity * 0.6)
        normalPaint.color = color.withOpacity((p.opacity * 0.6).clamp(0.0, 1.0));
        canvas.drawCircle(Offset(p.x, p.y), s, normalPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_SpherePainter old) =>
      old.rotX != rotX || old.rotY != rotY || old.time != time ||
      old.isListening != isListening || old.isThinking != isThinking ||
      old.isSpeaking != isSpeaking;
}

// ─── Ma'lumot klasslari ────────────────────────────────────────────────────

class _Dot {
  final double x, y, z, baseSize;
  const _Dot({
    required this.x, required this.y,
    required this.z, required this.baseSize,
  });
}

class _Projected {
  final double x, y, z, size, intensity, opacity;
  const _Projected({
    required this.x, required this.y, required this.z,
    required this.size, required this.intensity, required this.opacity,
  });
}
