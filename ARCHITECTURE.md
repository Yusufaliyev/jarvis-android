# Jarvis Android - Architecture & Design

## 🏗️ System Architecture (v2.4)

```
┌─────────────────────────────────────────────────────────┐
│                    UI Layer (Screens)                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  AuthScreen  │  │SettingsScreen│  │  ChatScreen  │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│              Service Layer (Business Logic)              │
│  ┌──────────────────┐  ┌──────────────────────────────┐ │
│  │  EnhancedAuth    │  │    MultiAIService            │ │
│  │  - PIN           │  │  - Gemini                    │ │
│  │  - OTP           │  │  - OpenAI                    │ │
│  │  - Lockout       │  │  - Groq                      │ │
│  └──────────────────┘  └──────────────────────────────┘ │
│  ┌──────────────────┐  ┌──────────────────────────────┐ │
│  │SecureStorageServ │  │    FirebaseService           │ │
│  │  - PIN Storage   │  │  - Auth                      │ │
│  │  - API Keys      │  │  - Database                  │ │
│  │  - Config        │  │  - Messaging                 │ │
│  └──────────────────┘  └──────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│             Data Layer (Storage & APIs)                  │
│  ┌──────────────────┐  ┌──────────────────────────────┐ │
│  │ Secure Storage   │  │    Firebase                  │ │
│  │  (Encrypted)     │  │  - Realtime DB               │ │
│  └──────────────────┘  └──────────────────────────────┘ │
│  ┌──────────────────┐  ┌──────────────────────────────┐ │
│  │  SharedPrefs     │  │    External APIs             │ │
│  │  (Settings)      │  │  - Gemini API                │ │
│  └──────────────────┘  │  - OpenAI API                │ │
│                        │  - Groq API                  │ │
│                        └──────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
jarvis-android/
├── .github/
│   └── workflows/
│       └── build.yml                 # CI/CD Pipeline
├── android/
│   └── app/
│       ├── build.gradle             # Firebase & Security config
│       └── google-services.json      # Firebase credentials
├── jarvis_app/
│   ├── lib/
│   │   ├── config/
│   │   │   ├── firebase_config.dart
│   │   │   └── firebase_options.dart
│   │   ├── services/
│   │   │   ├── enhanced_auth_service.dart
│   │   │   ├── multi_ai_service.dart
│   │   │   ├── secure_storage_service.dart
│   │   │   ├── firebase_service.dart (legacy)
│   │   │   └── auth_service.dart (legacy)
│   │   ├── screens/
│   │   │   ├── auth_screen.dart
│   │   │   ├── settings_screen.dart
│   │   │   └── chat_screen.dart
│   │   └── main.dart
│   ├── test/                        # Unit tests
│   └── pubspec.yaml                 # Dependencies
├── docs/
│   ├── SETUP_v2.4.md               # Setup guide
│   ├── RELEASE_NOTES_v2.4.md       # Release notes
│   └── CONTRIBUTING.md              # Contributing guide
└── README.md
```

---

## 🔄 Service Flow Diagrams

### Authentication Flow
```
┌─────────┐
│  Start  │
└────┬────┘
     ↓
┌─────────────────────┐
│ Check if PIN exists?│
└────┬────────────┬───┘
     │ Yes        │ No
     ↓            ↓
┌──────────┐  ┌────────────┐
│PIN Entry │  │PIN Setup   │
└────┬─────┘  └──────┬─────┘
     ↓               ↓
┌─────────────────────────┐
│ VerifyPin with lockout  │
└────┬────────────────┬───┘
     │ Success        │ Fail
     ↓                ↓
┌──────────┐    ┌─────────────┐
│Settings  │    │Record attempt│
└──────────┘    │ >= 5? Lock   │
                └─────────────┘
```

### MultiAI Request Flow
```
┌────────────┐
│User Prompt │
└──────┬─────┘
       ↓
┌──────────────────────────┐
│Get active AI provider    │
└──────┬─────────────────┬─┘
       │                 │
   ┌───┴───┐        ┌────┴────┐
   ↓       ↓        ↓         ↓
Gemini OpenAI Groq  Local(v3)
   │       │        │         │
   └───┬───┴────┬───┴────┬────┘
       ↓        ↓        ↓
┌──────────────────────────┐
│Retrieve API Key (secure) │
└──────┬─────────────────┬─┘
       │ Found          │ Not Found
       ↓                ↓
┌─────────────┐  ┌──────────────┐
│Send Request │  │Error: Config │
└──────┬──────┘  │API Key needed│
       ↓         └──────────────┘
┌──────────────────────┐
│Parse & Return Result │
└──────────────────────┘
```

### Firebase Sync Flow
```
┌─────────────┐
│App Launch   │
└──────┬──────┘
       ↓
┌───────────────────────────┐
│Initialize Firebase Core   │
└──────┬────────────────┬───┘
       │ Success        │ Error
       ↓                ↓
┌──────────────┐  ┌──────────────┐
│Check Auth    │  │Log & Offline │
└──────┬───────┘  └──────────────┘
       ↓
┌──────────────────────┐
│Sync User Data        │
└──────┬──────┬────────┘
       │      │
    ┌──┴──┐  └─────┐
    ↓     ↓        ↓
Settings API Keys Profile
    │     │        │
    └─────┴────┬───┘
         ↓
    ┌─────────────┐
    │Cache Update │
    └─────────────┘
```

---

## 🔐 Security Architecture

### Data Protection Layers

```
User Input
    ↓
[Input Validation]
    ↓
[Encryption (AES-GCM)]
    ↓
[Secure Storage]
    ↓
[Rate Limiting]
    ↓
[HTTPS Only]
    ↓
[Firebase Rules]
```

### Storage Hierarchy

| Data Type | Storage | Encryption | Lifetime |
|-----------|---------|-----------|----------|
| PIN | Secure Storage | AES-GCM | Persistent |
| API Keys | Secure Storage | AES-GCM | Persistent |
| OTP | SharedPrefs | None | 5 minutes |
| Session Token | Secure Storage | AES-GCM | Until logout |
| User Settings | SharedPrefs | None | Persistent |
| Firebase Data | Firebase | Server-side | Cloud |

---

## 🚀 Performance Optimization

### Load Time Targets (v2.4)
- Cold start: < 2 seconds
- Hot restart: < 500ms
- Screen transition: < 300ms
- API response: < 2 seconds

### Memory Management
- Target heap: < 150MB
- Frame rate: 60 FPS minimum
- Jank < 1% per session

### Network Optimization
- Request timeout: 10 seconds
- Retry attempts: 3
- Caching: LRU 50MB
- Compression: gzip enabled

---

## 📊 Database Schema (Firebase)

### Realtime Database Structure
```json
{
  "users": {
    "user_id": {
      "profile": {
        "name": "string",
        "email": "string",
        "createdAt": "timestamp"
      },
      "settings": {
        "preferredAI": "gemini|openai|groq",
        "darkMode": "boolean",
        "notifications": "boolean"
      },
      "conversations": {
        "conv_id": {
          "title": "string",
          "created": "timestamp",
          "messages": [
            {
              "role": "user|assistant",
              "content": "string",
              "timestamp": "timestamp"
            }
          ]
        }
      }
    }
  }
}
```

---

## 🔄 State Management Strategy

### Current (v2.4)
- StatefulWidget for UI state
- SharedPreferences for app settings
- Secure Storage for sensitive data
- In-memory service instances

### Planned (v2.7+)
- Provider package for state management
- BLoC pattern for complex logic
- Riverpod for dependency injection
- Redux for time-travel debugging

---

## 🧪 Testing Strategy

### Unit Tests (lib/services/)
```dart
test('PIN should be encrypted in storage', () async {
  await EnhancedAuthService.setPin('1234');
  final stored = await SecureStorageService.getPin();
  expect(stored, '1234');
});
```

### Widget Tests (lib/screens/)
```dart
testWidgets('Auth screen shows PIN entry', (WidgetTester tester) async {
  await tester.pumpWidget(AuthScreen());
  expect(find.byIcon(Icons.lock), findsOneWidget);
});
```

### Integration Tests
```dart
testWidgets('Full authentication flow', (WidgetTester tester) async {
  // Test PIN setup → entry → settings access
});
```

---

## 🔄 Upgrade Path: v2.4 → v2.5

### What's New
1. Biometric authentication
2. Multi-device sync
3. Session management
4. Activity logging

### Migration Steps
```bash
# 1. Backup user data
flutter run --release -- --backup

# 2. Update app
flutter upgrade
flutter pub upgrade

# 3. Run database migration
await FirebaseConfig.migrate();

# 4. Update UI for biometric prompts
```

---

## 📈 Scalability Considerations

### For 10K Users
- Firebase Spark plan sufficient
- Client-side caching essential
- Rate limiting: 100 req/min per user

### For 100K Users
- Firestore recommended (Realtime DB bottleneck)
- Edge caching (CloudFlare)
- Rate limiting: 50 req/min per user

### For 1M+ Users
- Multi-region deployment
- Dedicated API backend
- Message queue (Pub/Sub)
- CDN for static assets

---

**Last Updated:** v2.4 (June 2, 2026)
