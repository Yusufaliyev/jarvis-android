import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'dart:io' show Platform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (Platform.isAndroid) {
      return android;
    } else if (Platform.isIOS) {
      return ios;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
    appId: '1:123456789:android:xxxxxxxxxxxxxxxx',
    messagingSenderId: '123456789',
    projectId: 'jarvis-ai',
    databaseURL: 'https://jarvis-ai-default-rtdb.firebaseio.com',
    storageBucket: 'jarvis-ai.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
    appId: '1:123456789:ios:xxxxxxxxxxxxxxxx',
    messagingSenderId: '123456789',
    projectId: 'jarvis-ai',
    databaseURL: 'https://jarvis-ai-default-rtdb.firebaseio.com',
    storageBucket: 'jarvis-ai.appspot.com',
    iosBundleId: 'com.jarvis.app',
  );
}