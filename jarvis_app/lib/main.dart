import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(JarvisApp());
}

class JarvisApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JARVIS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xFF00D4FF),
        scaffoldBackgroundColor: Color(0xFF050A18),
      ),
      home: SplashScreen(),
    );
  }
}
