import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static Future<String> getWeather(String city) async {
    try {
      final res = await http.get(Uri.parse('https://wttr.in/$city?format=j1')).timeout(Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final current = data['current_condition'][0];
        final temp = current['temp_C'];
        final desc = current['weatherDesc'][0]['value'];
        final feels = current['FeelsLikeC'];
        return '$city da hozir $temp°C, $desc. Seziladi: $feels°C';
      }
      return 'Ob-havo ma\'lumoti topilmadi.';
    } catch (e) {
      return 'Ob-havo ma\'lumotini olishda xatolik.';
    }
  }
}
