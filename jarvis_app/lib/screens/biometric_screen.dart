// 📁 lib/screens/biometric_screen.dart
// JARVIS v2.5 — Biometric Auth Screen
// Futuristic dark UI with animated scanner

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/biometric_auth_service.dart';

class BiometricScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback? onFallbackPin;

  const BiometricScreen({
    Key? key,
    required this.onSuccess,
    this.onFallbackPin,
  }) : super(key: key);

  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen>
    with TickerProviderStateMixin {

  final _bio = BiometricAuthService();

  // Animation controllers
  late AnimationController _pulseCtrl;
  late AnimationController _scanCtrl;
  late AnimationController _rotateCtrl;
  late AnimationController _shakeCtrl;
  late AnimationController _successCtrl;

  late Animation<double> _pulseAnim;
  late Animation<double> _scanAnim;
  late Animation<double> _rotateAnim;
  late Animation<double> _shakeAnim;
  late Animation<double> _successAnim;

  // State
  BiometricType _bioType = BiometricType.fingerprint;
  BiometricStatus _status = BiometricStatus.available;
  String _statusMessage = 'Barmoq izingizni qo\'ying';
  bool _isScanning = false;
  bool _isSuccess = false;
  bool _isError = false;
  int _failedAttempts = 0;
  String _bioIcon = '👆';
  String _bioLabel = 'Barmoq izi';

  // Colors
  static const _cyan = Color(0xFF00D4FF);
  static const _green = Color(0xFF00FF88);
  static const _red = Color(0xFFFF4444);
  static const _bg = Color(0xFF030812);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadBiometricInfo();
    // Auto-trigger on open
    Future.delayed(const Duration(milliseconds: 800), _authenticate);
  }

  void _initAnimations() {
    // Pulse (ring animation)
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 2000), vsync: this)
      ..repeat();
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Scan line
    _scanCtrl = AnimationController(
      duration: const Duration(milliseconds: 1500), vsync: this)
      ..repeat();
    _scanAnim = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut));

    // Rotate ring
    _rotateCtrl = AnimationController(
      duration: const Duration(milliseconds: 4000), vsync: this)
      ..repeat();
    _rotateAnim = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _rotateCtrl, curve: Curves.linear));

    // Shake (error)
    _shakeCtrl = AnimationController(
      duration: const Duration(milliseconds: 500), vsync: this);
    _shakeAnim = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));

    // Success expand
    _successCtrl = AnimationController(
      duration: const Duration(milliseconds: 600), vsync: this);
    _successAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut));
  }

  Future<void> _loadBiometricInfo() async {
    _bioIcon = await _bio.getBiometricIcon();
    _bioLabel = await _bio.getBiometricLabel();
    _bioType = await _bio.getPrimaryBiometricType();
    _failedAttempts = await _bio.getFailedAttempts();
    if (mounted) setState(() {});
  }

  Future<void> _authenticate() async {
    if (_isScanning || _isSuccess) return;

    setState(() {
      _isScanning = true;
      _isError = false;
      _statusMessage = 'Skanlanmoqda...';
    });

    HapticFeedback.mediumImpact();

    final result = await _bio.authenticate(
      reason: 'JARVIS ga kirish uchun $_bioLabel dan foydalaning',
    );

    if (!mounted) return;

    if (result.success) {
      _onSuccess();
    } else {
      _onError(result.message, result.status);
    }
  }

  void _onSuccess() {
    setState(() {
      _isScanning = false;
      _isSuccess = true;
      _statusMessage = '✅ Tasdiqlandi!';
    });
    HapticFeedback.heavyImpact();
    _successCtrl.forward();

    Future.delayed(const Duration(milliseconds: 800), widget.onSuccess);
  }

  void _onError(String message, BiometricStatus status) async {
    setState(() {
      _isScanning = false;
      _isError = true;
      _statusMessage = message;
      _status = status;
    });

    _failedAttempts = await _bio.getFailedAttempts();
    HapticFeedback.vibrate();
    _shakeCtrl.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _isError = false);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scanCtrl.dispose();
    _rotateCtrl.dispose();
    _shakeCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  // ─────────────────── BUILD ───────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(children: [
        _buildBackground(),
        SafeArea(
          child: Column(children: [
            _buildHeader(),
            const Spacer(),
            _buildScannerWidget(),
            const SizedBox(height: 32),
            _buildStatusText(),
            const SizedBox(height: 16),
            _buildAttemptsBar(),
            const Spacer(),
            _buildBottomActions(),
            const SizedBox(height: 40),
          ]),
        ),
      ]),
    );
  }

  // ─── Background grid ───
  Widget _buildBackground() {
    return CustomPaint(
      size: Size.infinite,
      painter: _GridPainter(),
    );
  }

  // ─── Header ───
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(children: [
        // JARVIS logo
        RichText(text: const TextSpan(
          children: [
            TextSpan(text: 'J', style: TextStyle(
              color: _cyan, fontSize: 22, fontWeight: FontWeight.w900,
              letterSpacing: 0)),
            TextSpan(text: 'ARVIS', style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w300,
              letterSpacing: 6)),
          ],
        )),
        const Spacer(),
        // Version badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: _cyan.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('v2.5', style: TextStyle(
            color: _cyan, fontSize: 11, letterSpacing: 2)),
        ),
      ]),
    );
  }

  // ─── Main Scanner ───
  Widget _buildScannerWidget() {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) {
        final shake = _isError
            ? sin(_shakeAnim.value * pi) * 8 : 0.0;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: child,
        );
      },
      child: SizedBox(
        width: 240, height: 240,
        child: Stack(alignment: Alignment.center, children: [
          // Outer rotating ring
          AnimatedBuilder(
            animation: _rotateAnim,
            builder: (_, __) => Transform.rotate(
              angle: _rotateAnim.value,
              child: CustomPaint(
                size: const Size(240, 240),
                painter: _ArcPainter(
                  color: _isSuccess ? _green : _isError ? _red : _cyan,
                ),
              ),
            ),
          ),

          // Pulse ring
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Transform.scale(
              scale: _isScanning ? _pulseAnim.value : 1.0,
              child: Container(
                width: 180, height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (_isSuccess ? _green : _isError ? _red : _cyan)
                        .withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),

          // Main circle
          GestureDetector(
            onTap: _authenticate,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: _isSuccess
                      ? [_green.withOpacity(0.2), _bg]
                      : _isError
                      ? [_red.withOpacity(0.15), _bg]
                      : [_cyan.withOpacity(0.08), _bg],
                ),
                border: Border.all(
                  color: _isSuccess ? _green : _isError ? _red : _cyan,
                  width: 1.5,
                ),
              ),
              child: Stack(alignment: Alignment.center, children: [
                // Scan line
                if (_isScanning) AnimatedBuilder(
                  animation: _scanAnim,
                  builder: (_, __) => Positioned(
                    top: 80 + (_scanAnim.value * 60),
                    child: Container(
                      width: 100, height: 1.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.transparent,
                          _cyan.withOpacity(0.8),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ),
                ),

                // Icon / Success checkmark
                _isSuccess
                    ? ScaleTransition(
                        scale: _successAnim,
                        child: const Icon(Icons.check_rounded,
                          color: _green, size: 60))
                    : Text(
                        _bioIcon,
                        style: const TextStyle(fontSize: 52)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ─── Status text ───
  Widget _buildStatusText() {
    return Column(children: [
      // Title
      Text(
        _isSuccess ? 'Xush kelibsiz!' : _bioLabel,
        style: TextStyle(
          color: _isSuccess ? _green : Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 8),
      // Message
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Text(
          _statusMessage,
          key: ValueKey(_statusMessage),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _isSuccess ? _green
                : _isError ? _red
                : Colors.white54,
            fontSize: 14,
          ),
        ),
      ),
    ]);
  }

  // ─── Attempts bar ───
  Widget _buildAttemptsBar() {
    if (_failedAttempts == 0) return const SizedBox.shrink();
    return Column(children: [
      Text(
        '${BiometricAuthService.maxFailedAttempts - _failedAttempts} urinish qoldi',
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(BiometricAuthService.maxFailedAttempts, (i) =>
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 24, height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: i < _failedAttempts ? _red : Colors.white12,
            ),
          ),
        ),
      ),
    ]);
  }

  // ─── Bottom actions ───
  Widget _buildBottomActions() {
    return Column(children: [
      // Retry button
      if (!_isSuccess) GestureDetector(
        onTap: _authenticate,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: _cyan.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(colors: [
              _cyan.withOpacity(0.1),
              Colors.transparent,
            ]),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.fingerprint, color: _cyan, size: 18),
            const SizedBox(width: 8),
            Text(
              _isScanning ? 'Skanlanmoqda...' : 'Qayta urinish',
              style: const TextStyle(color: _cyan, fontSize: 14, letterSpacing: 1),
            ),
          ]),
        ),
      ),

      const SizedBox(height: 16),

      // PIN fallback
      if (widget.onFallbackPin != null)
        TextButton(
          onPressed: widget.onFallbackPin,
          child: const Text(
            'PIN bilan kirish',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ),
    ]);
  }
}

// ─── Custom Painters ───

class _ArcPainter extends CustomPainter {
  final Color color;
  _ArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // 4 ta arc (burchaklar)
    for (int i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        (pi / 2 * i) + 0.3,
        pi / 2 - 0.6,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.color != color;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 0.5;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Radial glow center
    final gradient = RadialGradient(
      colors: [
        const Color(0xFF00D4FF).withOpacity(0.04),
        Colors.transparent,
      ],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = gradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}
