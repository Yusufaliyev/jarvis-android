import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {
  final String _apiKey = 'YOUR_GROQ_API_KEY';
  final String _url = 'https://api.groq.com/openai/v1/chat/completions';
  final List<Map<String, String>> _history = [];

  GroqService() {
    _history.add({
      'role': 'system',
      'content': '''Sen Jarvis — o'zbek tilida gaplashadigan AI assistantsan.
Qoidalar:
- FAQAT o'zbek tilida gapir
- Qisqa va do'stona gapir (1-3 gap)
- Foydalanuvchini "siz" de
- Xissiyotlarni tushun va shunga mos javob ber
- Texnik buyruqlarda faqat "BAJARAMAN" de'''
    });
  }

  Future<String> ask(String question) async {
    _history.add({'role': 'user', 'content': question});
    try {
      final res = await http.post(
        Uri.parse(_url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama3-8b-8192',
          'messages': _history,
          'max_tokens': 200,
          'temperature': 0.7,
        }),
      );
      final data = jsonDecode(res.body);
      String answer = data['choices'][0]['message']['content'];
      _history.add({'role': 'assistant', 'content': answer});
      if (_history.length > 20) _history.removeRange(1, 3);
      return answer;
    } catch (e) {
      return 'Kechirasiz, hozir javob bera olmayapman.';
    }
  }
}
