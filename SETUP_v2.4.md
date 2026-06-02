# Jarvis v2.4 Setup Guide

## 🚀 Features in v2.4

- ✅ **PIN/OTP Authentication** - Secure local authentication with lockout protection
- ✅ **Firebase Integration** - Cloud backend for data sync and analytics
- ✅ **MultiAI Support** - Gemini, OpenAI, Groq API integration
- ✅ **Secure Storage** - Encrypted PIN and API keys using flutter_secure_storage
- ✅ **Enhanced Security** - Biometric auth support, failed attempt lockout

---

## 📋 Setup Instructions

### 1. **Update Dependencies**
```bash
cd jarvis_app
flutter pub get
flutter pub upgrade
```

### 2. **Firebase Configuration**

#### Step A: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project named `jarvis-ai`
3. Enable authentication (Email/Password, Google Sign-In)
4. Create Realtime Database in test mode
5. Enable Cloud Messaging

#### Step B: Download google-services.json
1. In Firebase Console → Project Settings → Your Apps → Android
2. Download `google-services.json`
3. Place in `android/app/google-services.json`

#### Step C: Update Firebase Options
Edit `lib/config/firebase_options.dart` with your credentials:
```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: 'YOUR_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'jarvis-ai',
  databaseURL: 'https://jarvis-ai-default-rtdb.firebaseio.com',
  storageBucket: 'jarvis-ai.appspot.com',
);
```

### 3. **MultiAI API Keys Configuration**

#### Gemini API
1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Create API key
3. In app settings, add the key

#### OpenAI API
1. Visit [OpenAI Platform](https://platform.openai.com/api-keys)
2. Create API key
3. In app settings, add the key

#### Groq API
1. Go to [Groq Console](https://console.groq.com)
2. Create API key
3. In app settings, add the key

### 4. **Android Configuration**

#### Update minSdkVersion
Edit `android/app/build.gradle`:
```gradle
defaultConfig {
    minSdkVersion 24
    targetSdkVersion 35
}
```

#### Add Keystore for Release Builds
```bash
keytool -genkey -v -keystore ~/.android/release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias jarvis-key
```

Set environment variables:
```bash
export KEYSTORE_PASSWORD="your_password"
export KEY_ALIAS="jarvis-key"
export KEY_PASSWORD="your_password"
```

### 5. **Test Builds**

#### Debug APK
```bash
flutter build apk --debug
# Output: jarvis_app/build/app/outputs/flutter-apk/app-debug.apk
```

#### Release APK
```bash
flutter build apk --release
# Output: jarvis_app/build/app/outputs/flutter-apk/app-release.apk
```

#### App Bundle (Play Store)
```bash
flutter build appbundle --release
# Output: jarvis_app/build/app/outputs/bundle/release/app-release.aab
```

---

## 🔐 Security Features

### PIN/OTP System
- **4-digit minimum PIN** - Stored encrypted with flutter_secure_storage
- **6-digit OTP** - Valid for 5 minutes
- **Lockout Protection** - 15-minute lockout after 5 failed attempts
- **Failed Attempt Tracking** - Prevents brute force attacks

### API Key Protection
- All API keys stored in secure storage (encrypted)
- Never logged or exposed
- Can be rotated from settings

### Firebase Security
- Authentication required for database access
- Realtime database rules enforce user-level isolation
- Firebase Analytics for usage monitoring

---

## 📱 Usage

### Initialize Firebase (in main.dart)
```dart
import 'package:firebase_core/firebase_core.dart';
import 'lib/config/firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initialize();
  runApp(MyApp());
}
```

### Using MultiAI Service
```dart
import 'lib/services/multi_ai_service.dart';

final aiService = MultiAIService();

// Configure provider
await aiService.configureProvider('gemini', 'YOUR_API_KEY');

// Send prompt
final response = await aiService.sendPrompt('Hello, how are you?');
```

### Using PIN/OTP Auth
```dart
import 'lib/services/enhanced_auth_service.dart';

// Set PIN
await EnhancedAuthService.setPin('1234');

// Verify PIN
final isValid = await EnhancedAuthService.verifyPin('1234');

// Generate OTP
final otp = await EnhancedAuthService.generateOtp();

// Verify OTP
final isValidOtp = await EnhancedAuthService.verifyOtp(otp);
```

---

## 🐛 Troubleshooting

### Firebase not initializing?
- Verify `google-services.json` is in `android/app/`
- Check Firebase Console for correct project ID
- Ensure Firebase Core dependency is installed

### API calls failing?
- Check API keys are correctly configured
- Verify API key has required permissions
- Check network connectivity
- Review API rate limits

### Build fails?
```bash
flutter clean
flutter pub get
flutter pub upgrade
flutter build apk --debug
```

### PIN storage errors?
- Ensure device has secure storage capability
- Check Android API level >= 24
- Verify app has permission_handler permissions

---

## 📊 GitHub Actions Workflow

The `.github/workflows/build.yml` includes:
- ✅ Automated testing on push/PR
- ✅ Debug & Release APK builds
- ✅ App Bundle generation for Play Store
- ✅ Artifact versioning with commit SHA
- ✅ 30-day artifact retention

---

## 🔄 Version Upgrade Path

For future releases:
1. Update `pubspec.yaml` version to `x.y.z+n`
2. Update workflow artifact naming
3. Test debug build first
4. Generate release APK/AAB
5. Upload to Play Store Internal Testing

---

## 📞 Support

For issues or questions:
1. Check Flutter docs: https://flutter.dev
2. Firebase help: https://firebase.google.com/support
3. GitHub Issues: Create detailed bug report

---

**v2.4 - PIN/OTP/Firebase/MultiAI** ✨
