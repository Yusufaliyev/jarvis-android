import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/permission_screen.dart';
import 'screens/face_auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
        scaffoldBackgroundColor: Color(0xFF030812),
      ),
      home: _StartScreen(),
    );
  }
}

class _StartScreen extends StatefulWidget {
  @override
  __StartScreenState createState() => __StartScreenState();
}

class __StartScreenState extends State<_StartScreen> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final firstTime = prefs.getBool('permissions_done') ?? false;

    if (!firstTime) {
      // Birinchi marta — ruxsatlar ekrani
      Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => PermissionScreen()));
    } else {
      // Keyingi kirish — yuz aniqlash
      Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => FaceAuthScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF030812),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF))),
    );
  }
}
