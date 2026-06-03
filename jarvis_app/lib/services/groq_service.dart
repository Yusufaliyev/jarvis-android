import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GroqService {
  final List<Map<String, dynamic>> _history = [];

  // Barcha bepul AI providerlari
  static const Map<String, Map<String, String>> providers = {
    'gemini': {
      'name': 'Google Gemini',
      'url': 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent',
      'type': 'gemini',
      'free': 'Bepul • 1500/kun',
      'emoji': '🟢',
    },
    'groq': {
      'name': 'Groq (Llama)',
      'url': 'https://api.groq.com/openai/v1/chat/completions',
      'type': 'openai',
      'free': 'Bepul • 14400/kun',
      'emoji': '⚡',
    },
    'openai': {
      'name': 'OpenAI GPT-4',
      'url': 'https://api.openai.com/v1/chat/completions',
      'type': 'openai',
      'free': 'Pullik',
      'emoji': '🔵',
    },
    'mistral': {
      'name': 'Mistral AI',
      'url': 'https://api.mistral.ai/v1/chat/completions',
      'type': 'openai',
      'free': 'Bepul sinov',
      'emoji': '🌊',
    },
    'cohere': {
      'name': 'Cohere',
      'url': 'https://api.cohere.ai/v1/generate',
      'type': 'cohere',
      'free': 'Bepul • 5M token/oy',
      'emoji': '🟣',
    },
    'huggingface': {
      'name': 'HuggingFace',
      'url': 'https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.1',
      'type': 'huggingface',
      'free': '100% Bepul',
      'emoji': '🤗',
    },
    'openrouter': {
      'name': 'OpenRouter (Bepul)',
      'url': 'https://openrouter.ai/api/v1/chat/completions',
      'type': 'openai',
      'free': 'Bepul modellar',
      'emoji': '🔀',
    },
  };

  GroqService() {
    _history.addAll([
      {'role': 'user', 'parts': [{'text': '''Sen JARVIS — o\'zbek tilidagi AI assistantsan.
- FAQAT o\'zbek tilida gapir
- Qisqa javob (1-2 gap)
- "siz" de
- Xursand bo\'lsa: "Zo\'r!", xafa bo\'lsa hamdard bo\'l
- Buyruq: "Bajarildi!"'''}]},
      {'role': 'model', 'parts': [{'text': 'Tayyor! Doim o\'zbek tilida xizmat qilaman!'}]},
    ]);
  }

  Future<String> ask(String question) async {
    final prefs = await SharedPreferences.getInstance();
    final provider = prefs.getString('ai_provider') ?? 'gemini';
    final apiKey = prefs.getString('${provider}_api_key') ?? '';

    if (apiKey.isEmpty) {
      return 'API key kiritilmagan! ⚙️ Sozlamalarga kiring va "$provider" uchun key kiriting.';
    }

    final pInfo = providers[provider];
    if (pInfo == null) return 'Noma\'lum AI provider!';

    _history.add({'role': 'user', 'parts': [{'text': question}]});

    try {
      String result;
      switch (pInfo['type']) {
        case 'gemini':
          result = await _askGemini(apiKey, pInfo['url']!, question);
          break;
        case 'openai':
          result = await _askOpenAI(apiKey, pInfo['url']!, question);
          break;
        case 'huggingface':
          result = await _askHuggingFace(apiKey, pInfo['url']!, question);
          break;
        case 'cohere':
          result = await _askCohere(apiKey, question);
          break;
        default:
          result = await _askOpenAI(apiKey, pInfo['url']!, question);
      }

      _history.add({'role': 'model', 'parts': [{'text': result}]});
      if (_history.length > 24) _history.removeRange(2, 4);
      return result;
    } catch (e) {
      return 'Internet yoki server xatosi. Qayta urinib ko\'ring.';
    }
  }

  // Gemini
  Future<String> _askGemini(String key, String url, String q) async {
    final msgs = _history.map((h) => {
      'role': h['role'],
      'parts': h['parts'],
    }).toList();

    final res = await http.post(
      Uri.parse('$url?key=$key'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': msgs,
        'generationConfig': {'temperature': 0.8, 'maxOutputTokens': 256},
      }),
    ).timeout(Duration(seconds: 15));

    if (res.statusCode == 200) {
      final d = jsonDecode(utf8.decode(res.bodyBytes));
      return d['candidates'][0]['content']['parts'][0]['text'].trim();
    } else if (res.statusCode == 400) {
      return 'Gemini API key noto\'g\'ri! Sozlamalardan yangilang.';
    }
    return 'Gemini xatosi (${res.statusCode})';
  }

  // OpenAI formatli (Groq, Mistral, OpenRouter)
  Future<String> _askOpenAI(String key, String url, String q) async {
    final msgs = [
      {'role': 'system', 'content': 'Sen JARVIS — o\'zbek tilida gaplashadigan AI assistantsan. Qisqa, do\'stona javob ber.'},
      ..._history.skip(2).map((h) => {
        'role': h['role'] == 'model' ? 'assistant' : 'user',
        'content': (h['parts'] as List).first['text'],
      }),
    ];

    final res = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $key',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': url.contains('groq') ? 'llama3-8b-8192'
            : url.contains('mistral') ? 'mistral-small-latest'
            : url.contains('openrouter') ? 'meta-llama/llama-3.1-8b-instruct:free'
            : 'gpt-3.5-turbo',
        'messages': msgs,
        'max_tokens': 200,
        'temperature': 0.8,
      }),
    ).timeout(Duration(seconds: 15));

    if (res.statusCode == 200) {
      final d = jsonDecode(utf8.decode(res.bodyBytes));
      return d['choices'][0]['message']['content'].trim();
    } else if (res.statusCode == 401) {
      return 'API key noto\'g\'ri! Sozlamalardan yangilang.';
    }
    return 'Xatolik (${res.statusCode})';
  }

  // HuggingFace
  Future<String> _askHuggingFace(String key, String url, String q) async {
    final res = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $key',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'inputs': '[INST] O\'zbek tilida qisqa javob ber: $q [/INST]',
        'parameters': {'max_new_tokens': 200, 'temperature': 0.7},
      }),
    ).timeout(Duration(seconds: 20));

    if (res.statusCode == 200) {
      final d = jsonDecode(res.body);
      String text = d[0]['generated_text'] ?? '';
      if (text.contains('[/INST]')) {
        text = text.split('[/INST]').last.trim();
      }
      return text.isEmpty ? 'Javob olishda xatolik' : text;
    }
    return 'HuggingFace xatosi (${res.statusCode})';
  }

  // Cohere
  Future<String> _askCohere(String key, String q) async {
    final res = await http.post(
      Uri.parse('https://api.cohere.ai/v1/generate'),
      headers: {
        'Authorization': 'Bearer $key',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'command',
        'prompt': 'O\'zbek tilida qisqa javob ber: $q',
        'max_tokens': 200,
        'temperature': 0.8,
      }),
    ).timeout(Duration(seconds: 15));

    if (res.statusCode == 200) {
      final d = jsonDecode(res.body);
      return d['generations'][0]['text'].trim();
    }
    return 'Cohere xatosi (${res.statusCode})';
  }
}
