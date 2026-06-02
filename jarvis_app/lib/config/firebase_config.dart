import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized successfully');
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      rethrow;
    }
  }

  // Firebase Database configuration
  static const String databaseUrl = 'https://jarvis-ai-default-rtdb.firebaseio.com';

  // Firebase Auth
  static const String authDomain = 'jarvis-ai.firebaseapp.com';

  // Analytics
  static const String analyticsId = 'jarvis_android_v24';
}