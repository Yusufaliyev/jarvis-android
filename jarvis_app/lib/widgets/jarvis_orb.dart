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
  int _statusIdx = 0;

  final List<String> _statuses = [
    "Neyron tarmoq faollashdi...",
    "Kontekst tahlil qilinmoqda...",
    "Vektor fazosi qidirilmoqda...",
    "Javob optimizatsiya qilinmoqda...",
    "Bilimlar sintezi amalga oshirilmoqda...",
    "Tokenlar tahlil qilinmoqda...",
    "Ehtimollik baholanmoqda...",
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      setState(() {
        _time = elapsed.inMilliseconds.toDouble();
        _rotX += 0.003;
        _rotY += 0.005;
        _statusIdx = (_time / 3000).floor() % _statuses.length;
      });
    });
    _ticker.start();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.isListening ? "Ovozni qayta ishlamoqda..."
        : widget.isThinking ? "Fikrlamoqda..."
        : widget.isSpeaking ? "Javob berilmoqda..."
        : _statuses[_statusIdx];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            size: const Size(320, 320),
            painter: _SpherePainter(
              rotX: _rotX,
              rotY: _rotY,
              time: _time,
              isListening: widget.isListening,
              isThinking: widget.isThinking,
              isSpeaking: widget.isSpeaking,
            ),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 700),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: Text(
            status,
            key: ValueKey(status),
            style: TextStyle(
              color: const Color(0xFF4AF2FF).withOpacity(0.7),
              fontSize: 11,
              letterSpacing: 2,
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

// ─── Painter ──────────────────────────────────────────────────────────────

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

  // 2500 nuqtali Fibonacci shar — bir marta
  static final List<_Dot> _dots = _build();

  static List<_Dot> _build() {
    const n = 2500;
    final rng = Random(12345);
    final list = <_Dot>[];
    for (int i = 0; i < n; i++) {
      final phi = acos(-1 + (2 * i) / n);
      final theta = sqrt(n * pi) * phi;
      list.add(_Dot(
        x: cos(theta) * sin(phi),
        y: sin(theta) * sin(phi),
        z: cos(phi),
        size: rng.nextDouble() * 1.6 + 0.4,
        layer: rng.nextInt(3), // 0=core, 1=mid, 2=outer
      ));
    }
    return list;
  }

  Color get _base {
    if (isListening) return const Color(0xFFFF3366);
    if (isThinking)  return const Color(0xFFFFAA00);
    if (isSpeaking)  return const Color(0xFF00FF88);
    return const Color(0xFF4AF2FF);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width  / 2;
    final cy = size.height / 2;
    final radius = size.width * 0.44;
    final fov    = 1500.0 * (radius / 400.0);

    final cosY = cos(rotY), sinY = sin(rotY);
    final cosX = cos(rotX), sinX = sin(rotX);
    final col  = _base;

    // ── Fon glow ──────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy),
      radius * 0.9,
      Paint()
        ..shader = RadialGradient(colors: [
          col.withOpacity(0.07),
          col.withOpacity(0.02),
          Colors.transparent,
        ], stops: const [0.0, 0.5, 1.0])
            .createShader(Rect.fromCircle(
                center: Offset(cx, cy), radius: radius * 0.9)),
    );

    // ── 3D proektsiya ─────────────────────────────────────────────
    final buf = <_P>[];
    buf.length = _dots.length;

    for (int i = 0; i < _dots.length; i++) {
      final d  = _dots[i];
      final dx = d.x * radius;
      final dy = d.y * radius;
      final dz = d.z * radius;

      // Y rotation
      final x1 = dx * cosY - dz * sinY;
      final z1 = dz * cosY + dx * sinY;

      // X rotation
      final y2 = dy * cosX - z1 * sinX;
      final z2 = z1 * cosX + dy * sinX;

      // Perspective
      final persp = fov / (fov - z2);
      final px = x1 * persp + cx;
      final py = y2 * persp + cy;

      // Pulse wave
      final pulse     = sin(dy * 0.01 + time * 0.005);
      final intensity = max(0.08, pulse);
      final opacity   = max(0.0, (z2 + radius) / (radius * 2));

      buf[i] = _P(px, py, z2, d.size * persp, intensity, opacity, d.layer);
    }

    // ── Z ga qarab saralash ───────────────────────────────────────
    buf.sort((a, b) => a.z.compareTo(b.z));

    // ── Chizish — 3 pass ─────────────────────────────────────────

    // Pass 1: Oddiy nuqtalar
    final normalPaint = Paint()..style = PaintingStyle.fill;
    for (final p in buf) {
      if (p.intensity > 0.75) continue; // keyingi passda
      final s = (p.size * (1 + p.intensity * 0.4)).clamp(0.15, 4.5);
      normalPaint.color = col.withOpacity((p.opacity * 0.55).clamp(0, 1));
      canvas.drawCircle(Offset(p.x, p.y), s, normalPaint);
    }

    // Pass 2: Yorqin nuqtalar (glow bilan)
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    for (final p in buf) {
      if (p.intensity <= 0.75) continue;
      final s = (p.size * (1 + p.intensity * 0.6)).clamp(0.5, 6.0);
      glowPaint.color = Colors.white.withOpacity((p.opacity * 0.9).clamp(0, 1));
      canvas.drawCircle(Offset(p.x, p.y), s, glowPaint);
    }

    // Pass 3: Pulse ring (gapirsa/tinglasa)
    if (isSpeaking || isListening) {
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      final wave = (time % 2000) / 2000;
      for (int i = 1; i <= 3; i++) {
        final r = radius * 0.4 + i * 18 + wave * 30;
        final alpha = (0.4 - i * 0.1) * (1 - wave);
        if (alpha <= 0) continue;
        ringPaint.color = col.withOpacity(alpha.clamp(0, 1));
        canvas.drawCircle(Offset(cx, cy), r, ringPaint);
      }
    }

    // Pass 4: Markaziy yadro
    final coreR = radius * 0.08 + sin(time * 0.003) * 3;
    canvas.drawCircle(
      Offset(cx, cy),
      coreR,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withOpacity(0.95),
          col.withOpacity(0.6),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: coreR)),
    );
  }

  @override
  bool shouldRepaint(_SpherePainter o) =>
      o.rotX != rotX || o.rotY != rotY || o.time != time ||
      o.isListening != isListening || o.isThinking != isThinking ||
      o.isSpeaking != isSpeaking;
}

// ─── Model klasslari ──────────────────────────────────────────────────────

class _Dot {
  final double x, y, z, size;
  final int layer;
  const _Dot({
    required this.x, required this.y, required this.z,
    required this.size, required this.layer,
  });
}

class _P {
  final double x, y, z, size, intensity, opacity;
  final int layer;
  const _P(this.x, this.y, this.z, this.size, this.intensity, this.opacity, this.layer);
}
