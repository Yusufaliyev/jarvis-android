import 'package:dio/dio.dart';
import 'secure_storage_service.dart';

class MultiAIService {
  static const String _geminiEndpoint = 'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _openaiEndpoint = 'https://api.openai.com/v1';
  static const String _groqEndpoint = 'https://api.groq.com/openai/v1';

  final Dio _dio = Dio();
  String _activeProvider = 'gemini';

  // ========== AI Model Selection ==========
  static const Map<String, String> modelMap = {
    'gemini': 'gemini-2.0-flash',
    'openai': 'gpt-4-turbo',
    'groq': 'mixtral-8x7b-32768',
  };

  Future<void> setActiveProvider(String provider) async {
    if (modelMap.containsKey(provider)) {
      _activeProvider = provider;
      print('✅ Provider switched to: $_activeProvider');
    } else {
      throw Exception('Unknown provider: $provider');
    }
  }

  // ========== Gemini API ==========
  Future<String> sendToGemini(String prompt) async {
    try {
      final apiKey = await SecureStorageService.getApiKey('gemini');
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Gemini API key not configured');
      }

      final response = await _dio.post(
        '$_geminiEndpoint/${modelMap['gemini']}:generateContent',
        queryParameters: {'key': apiKey},
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          }
        },
        options: Options(
          contentType: Headers.jsonContentType,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        final text = response.data['candidates'][0]['content']['parts'][0]['text'];
        return text ?? 'No response';
      } else {
        throw Exception('Gemini API error: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      print('❌ Gemini API error: $e');
      rethrow;
    }
  }

  // ========== OpenAI API ==========
  Future<String> sendToOpenAI(String prompt) async {
    try {
      final apiKey = await SecureStorageService.getApiKey('openai');
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('OpenAI API key not configured');
      }

      final response = await _dio.post(
        '$_openaiEndpoint/chat/completions',
        data: {
          'model': modelMap['openai'],
          'messages': [
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'temperature': 0.7,
          'max_tokens': 1024,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        final text = response.data['choices'][0]['message']['content'];
        return text ?? 'No response';
      } else {
        throw Exception('OpenAI API error: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      print('❌ OpenAI API error: $e');
      rethrow;
    }
  }

  // ========== Groq API ==========
  Future<String> sendToGroq(String prompt) async {
    try {
      final apiKey = await SecureStorageService.getApiKey('groq');
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Groq API key not configured');
      }

      final response = await _dio.post(
        '$_groqEndpoint/chat/completions',
        data: {
          'model': modelMap['groq'],
          'messages': [
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'temperature': 0.7,
          'max_tokens': 1024,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        final text = response.data['choices'][0]['message']['content'];
        return text ?? 'No response';
      } else {
        throw Exception('Groq API error: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      print('❌ Groq API error: $e');
      rethrow;
    }
  }

  // ========== Universal Send ==========
  Future<String> sendPrompt(String prompt, {String? provider}) async {
    final targetProvider = provider ?? _activeProvider;

    switch (targetProvider) {
      case 'gemini':
        return sendToGemini(prompt);
      case 'openai':
        return sendToOpenAI(prompt);
      case 'groq':
        return sendToGroq(prompt);
      default:
        throw Exception('Unknown provider: $targetProvider');
    }
  }

  // ========== Provider Configuration ==========
  Future<void> configureProvider(String provider, String apiKey) async {
    if (!modelMap.containsKey(provider)) {
      throw Exception('Unknown provider: $provider');
    }

    try {
      await SecureStorageService.setApiKey(provider, apiKey);
      print('✅ Configured $provider');
    } catch (e) {
      print('❌ Configuration error: $e');
      rethrow;
    }
  }

  Future<bool> isProviderConfigured(String provider) async {
    try {
      final key = await SecureStorageService.getApiKey(provider);
      return key != null && key.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getConfiguredProviders() async {
    final providers = <String>[];
    for (var provider in modelMap.keys) {
      if (await isProviderConfigured(provider)) {
        providers.add(provider);
      }
    }
    return providers;
  }

  String get activeProvider => _activeProvider;
  String get activeModel => modelMap[_activeProvider] ?? '';
}