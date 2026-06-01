import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/permission_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Ekranni vertikal ushlab turish
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  // Barcha ruxsatlarni so'rash
  await PermissionService.requestAll();
  
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
      home: SplashScreen(),
    );
  }
}
