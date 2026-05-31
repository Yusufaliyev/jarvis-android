import 'package:flutter/material.dart';
import 'dart:async';
import 'jarvis_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: Duration(seconds: 2), vsync: this);
    _scale = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(_ctrl);
    _ctrl.forward();
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => JarvisScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF050A18),
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) => Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 140, height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        Color(0xFF00D4FF), Color(0xFF0050FF), Color(0xFF050A18)
                      ]),
                      boxShadow: [BoxShadow(
                        color: Color(0xFF00D4FF).withOpacity(0.7),
                        blurRadius: 50, spreadRadius: 15,
                      )],
                    ),
                    child: Icon(Icons.psychology, size: 70, color: Colors.white),
                  ),
                  SizedBox(height: 30),
                  Text('J.A.R.V.I.S', style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.bold,
                    color: Color(0xFF00D4FF), letterSpacing: 8,
                  )),
                  SizedBox(height: 10),
                  Text('Yuklanmoqda...', style: TextStyle(
                    color: Colors.white38, fontSize: 13, letterSpacing: 3,
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
}
