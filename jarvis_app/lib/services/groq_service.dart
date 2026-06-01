import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {
  final String _apiKey = 'AQ.Ab8RN6LxRHPtewWwEUlOzOUpcM5NbiJXtbWrnpcazM8pymBkHQ';
  final String _url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  final List<Map<String, dynamic>> _history = [];

  GroqService() {
    _history.addAll([
      {'role': 'user', 'parts': [{'text': '''Sen Jarvis — o\'zbek tilida gaplashadigan sun\'iy intellektsan.
Qoidalar:
- FAQAT o\'zbek tilida javob ber, hech qachon boshqa tilda gapirma
- Qisqa va do\'stona gapir (1-3 gap)
- Foydalanuvchini "siz" deb murojaat qil
- Xissiyotlarni anglа: xursand bo\'lsa sен ham, xafa bo\'lsa hamdard bo\'l
- Buyruqlarga "Bajarildi!" yoki "Hoziroq!" de
- Doim yordamga tayyor ekanligingni his ettir'''}]},
      {'role': 'model', 'parts': [{'text': 'Xop! Men Jarvis, doim o\'zbek tilida, qisqa va do\'stona javob beraman!'}]},
    ]);
  }

  Future<String> ask(String question) async {
    _history.add({'role': 'user', 'parts': [{'text': question}]});
    try {
      final res = await http.post(
        Uri.parse('$_url?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': _history,
          'generationConfig': {'temperature': 0.8, 'maxOutputTokens': 200},
        }),
      );
      if (res.statusCode != 200) return 'Kechirasiz, xatolik yuz berdi.';
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final answer = data['candidates'][0]['content']['parts'][0]['text'] as String;
      _history.add({'role': 'model', 'parts': [{'text': answer}]});
      if (_history.length > 22) _history.removeRange(2, 4);
      return answer.trim();
    } catch (e) {
      return 'Kechirasiz, hozir internet yoki xizmat ishlamayapti.';
    }
  }
}
