# Contributing to Jarvis v2.5+

## 🎯 Active Development Areas

### Priority 1: Biometric Authentication (v2.5)
- [ ] Implement fingerprint auth
- [ ] Add face recognition (iOS)
- [ ] Biometric token refresh
- [ ] Emergency PIN bypass

### Priority 2: Advanced AI Features (v2.6)
- [ ] Local LLM integration
- [ ] Vision API support
- [ ] Audio processing
- [ ] Multi-turn conversations

### Priority 3: Enterprise Features (v2.8+)
- [ ] Role-based access
- [ ] Team management
- [ ] Advanced analytics
- [ ] Data compliance

---

## 🛠️ Setting Up Development Environment

### Prerequisites
```bash
flutter --version  # 3.12.0+
dart --version
java -version      # 17+
android-studio     # Latest
```

### Clone & Setup
```bash
git clone https://github.com/Yusufaliyev/jarvis-android.git
cd jarvis_app
flutter pub get
flutter pub upgrade
```

### Configure Firebase for Development
1. Create Firebase project: `jarvis-dev`
2. Download `google-services.json`
3. Place in `android/app/`
4. Update `lib/config/firebase_options.dart`

### Run Development Build
```bash
flutter run --debug
# Or on specific device
flutter run -d emulator-5554
```

---

## 📝 Creating Feature Branches

### Branch Naming Convention
```
feature/v2.5-biometric-auth
bugfix/pin-lockout-issue
docs/setup-guide-update
ci/github-actions-upgrade
```

### Create & Push
```bash
git checkout -b feature/your-feature
# Make changes
git add .
git commit -m "feat: Add your feature description"
git push origin feature/your-feature
```

---

## 🧪 Testing Requirements

### Unit Tests
```bash
flutter test
# Or specific file
flutter test test/services/enhanced_auth_service_test.dart
```

### Widget Tests
```bash
flutter test --tags=widget
```

### Integration Tests
```bash
flutter test integration_test/
```

### Coverage Report
```bash
flutter test --coverage
lcov --list coverage/lcov.info
```

---

## 📦 Dependency Updates

### Check for Updates
```bash
flutter pub outdated
flutter pub upgrade --dry-run
```

### Update Safely
```bash
# Update pubspec.yaml manually or use
flutter pub upgrade [package_name]
flutter pub get
flutter test  # Verify no breaking changes
```

---

## 🚀 Release Checklist

### Before Release
- [ ] All tests passing
- [ ] Code reviewed by maintainer
- [ ] Version bumped in pubspec.yaml
- [ ] CHANGELOG.md updated
- [ ] Release notes prepared

### Build Commands
```bash
# Clean build
flutter clean
flutter pub get

# Build release APK
flutter build apk --release

# Build App Bundle for Play Store
flutter build appbundle --release

# Sign APK (if needed)
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
  -keystore ~/.android/release.jks \
  build/app/outputs/flutter-apk/app-release.apk jarvis-key
```

---

## 📊 Code Quality Standards

### Dart Analysis
```bash
flutter analyze
dart fix --apply  # Auto-fix issues
```

### Format Code
```bash
dart format --fix .
```

### Linting
```bash
flutter pub global activate dart_code_metrics
dcm analyze lib/
```

---

## 🔍 Code Review Process

1. **Create PR** with clear description
2. **GitHub Actions** runs automated tests
3. **Code review** by maintainer
4. **Address feedback** in new commits
5. **Merge** when approved

### PR Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Feature
- [ ] Bug fix
- [ ] Documentation
- [ ] Refactoring

## Testing
Describe testing performed

## Checklist
- [ ] Code follows style guidelines
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No new warnings
```

---

## 📚 Documentation Updates

### Update Setup Guide
```bash
vim SETUP_v2.4.md
# Add new configuration sections
```

### Update Architecture Docs
```bash
# Create new doc for major features
touch docs/architecture/v25-biometric-auth.md
```

### Generate API Docs
```bash
dartdoc --output docs/api
```

---

## 🐛 Bug Reporting

### Template for Issues
```markdown
## Description
[Clear description of bug]

## Steps to Reproduce
1. ...
2. ...
3. ...

## Expected Behavior
[What should happen]

## Actual Behavior
[What actually happened]

## Device Info
- Device: [e.g., Pixel 6]
- OS: Android 13
- Flutter version: 3.12.0
- App version: 2.4.0

## Logs
[Paste error logs]
```

---

## 🔐 Security Guidelines

### Do's
- ✅ Use flutter_secure_storage for sensitive data
- ✅ Validate all user input
- ✅ Use HTTPS for all API calls
- ✅ Implement rate limiting
- ✅ Log security events

### Don'ts
- ❌ Don't log API keys or tokens
- ❌ Don't hardcode secrets
- ❌ Don't expose user data
- ❌ Don't use deprecated APIs
- ❌ Don't skip security tests

---

## 📅 Release Schedule

| Version | Target Date | Major Features |
|---------|------------|-----------------|
| v2.5 | Q3 2026 | Biometric Auth |
| v2.6 | Q4 2026 | Advanced AI |
| v2.7 | Q1 2027 | UX Enhancements |
| v2.8 | Q2 2027 | Enterprise |
| v3.0 | Q3 2027 | Platform Expansion |

---

## 💡 Feature Request Process

1. **Check existing issues** - Avoid duplicates
2. **Create issue** with clear description
3. **Tag appropriately** - `enhancement`, `v2.5`, etc.
4. **Discuss with maintainer** - Get feedback
5. **Submit PR** when ready

---

## 🎓 Learning Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase for Flutter](https://firebase.google.com/docs/flutter)
- [Dart Language Guide](https://dart.dev/guides)
- [Material Design](https://material.io/design)

---

## 📞 Contact

- **Maintainer:** @Yusufaliyev
- **Issues:** GitHub Issues
- **Discussions:** GitHub Discussions

---

**Happy Contributing!** 🎉
