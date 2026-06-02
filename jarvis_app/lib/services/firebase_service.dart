import 'package:shared_preferences/shared_preferences.dart';

class FirebaseService {
  static Future<bool> saveApiKey(String provider, String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${provider}_api_key', key);
    return true;
  }

  static Future<String> getApiKey(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${provider}_api_key') ?? '';
  }

  static Future<List<Map<String, dynamic>>> getSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final providers = ['gemini', 'openai', 'groq'];
    List<Map<String, dynamic>> result = [];
    for (var p in providers) {
      final key = prefs.getString('${p}_api_key') ?? '';
      if (key.isNotEmpty) {
        final masked = key.length > 12
            ? key.substring(0, 8) + '****' + key.substring(key.length - 4)
            : '****';
        result.add({'provider': p, 'key': masked});
      }
    }
    return result;
  }

  static Future<bool> saveFirebaseConfig(Map<String, String> config) async {
    final prefs = await SharedPreferences.getInstance();
    for (var e in config.entries) {
      await prefs.setString('firebase_${e.key}', e.value);
    }
    return true;
  }
}
