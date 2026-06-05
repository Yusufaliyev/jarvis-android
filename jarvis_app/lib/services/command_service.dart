import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'contact_service.dart';
import 'weather_service.dart';
import 'nlp_service.dart';

class CommandService {
  Future<String?> execute(String command) async {
    final result = NlpService.analyze(command);

    switch (result.intent) {
      // ── Qo'ng'iroq ──
      case Intent.call:
        return await _handleCall(command, result.contactName);

      // ── SMS ──
      case Intent.sms:
        return await _handleSms(command, result.contactName);

      // ── Kamera (in-app signal) ──
      case Intent.camera:
        return '__CAMERA__'; // jarvis_screen.dart buni ushlab kamerani yoqadi

      // ── Telegram ──
      case Intent.telegram:
        return await _app('tg://', 'org.telegram.messenger', 'Telegram');

      // ── YouTube ──
      case Intent.youtube:
        if (result.query != null && result.query!.isNotEmpty) {
          await _web('https://youtube.com/results?search_query=${Uri.encodeComponent(result.query!)}');
          return 'YouTube da "${result.query}" qidirilmoqda!';
        }
        return await _app('vnd.youtube://', 'com.google.android.youtube', 'YouTube');

      // ── Musiqa ──
      case Intent.music:
        if (result.query != null && result.query!.isNotEmpty) {
          await _web('https://youtube.com/results?search_query=${Uri.encodeComponent(result.query! + " qo\'shiq")}');
          return '"${result.query}" qo\'shig\'i YouTube da qidirilmoqda!';
        }
        return await _app('spotify://', 'com.spotify.music', 'Spotify');

      // ── Instagram ──
      case Intent.instagram:
        return await _app('instagram://app', 'com.instagram.android', 'Instagram');

      // ── WhatsApp ──
      case Intent.whatsapp:
        return await _app('whatsapp://', 'com.whatsapp', 'WhatsApp');

      // ── TikTok ──
      case Intent.tiktok:
        return await _app('snssdk1233://', 'com.zhiliaoapp.musically', 'TikTok');

      // ── Xarita ──
      case Intent.maps:
        if (result.query != null && result.query!.isNotEmpty) {
          await _web('https://maps.google.com/?q=${Uri.encodeComponent(result.query!)}');
          return '"${result.query}" xaritada ko\'rsatilmoqda!';
        }
        return await _app('geo:0,0', 'com.google.android.apps.maps', 'Xarita');

      // ── Google qidiruv ──
      case Intent.google:
        if (result.query != null && result.query!.isNotEmpty) {
          await _web('https://google.com/search?q=${Uri.encodeComponent(result.query!)}');
          return '"${result.query}" Google da qidirilmoqda!';
        }
        await _web('https://google.com');
        return 'Google ochildi!';

      // ── Ob-havo ──
      case Intent.weather:
        final city = result.query ?? 'Toshkent';
        return await WeatherService.getWeather(city);

      // ── Vaqt ──
      case Intent.time:
        final t = DateTime.now();
        final h = t.hour.toString().padLeft(2, '0');
        final m = t.minute.toString().padLeft(2, '0');
        return 'Hozir soat $h:$m';

      // ── Sana ──
      case Intent.date:
        final d = DateTime.now();
        final months = ['Yanvar','Fevral','Mart','Aprel','May','Iyun',
                        'Iyul','Avgust','Sentabr','Oktabr','Noyabr','Dekabr'];
        final days = ['Yakshanba','Dushanba','Seshanba','Chorshanba','Payshanba','Juma','Shanba'];
        return '${days[d.weekday % 7]}, ${d.day} ${months[d.month-1]} ${d.year} yil';

      // ── Kalkulyator ──
      case Intent.calculator:
        await _app('android-app://com.google.android.calculator', 'com.google.android.calculator', 'Kalkulyator');
        return 'Kalkulyator ochildi!';

      // ── Yangiliklar ──
      case Intent.news:
        await _web('https://kun.uz');
        return 'Kun.uz yangiliklari ochildi!';

      // ── Sozlamalar ──
      case Intent.settings:
        await launchUrl(Uri.parse('app-settings:'), mode: LaunchMode.externalApplication);
        return 'Sozlamalar ochildi!';

      // ── Batareya ──
      case Intent.battery:
        return 'Batareya ma\'lumotini qurilmangizdan tekshiring. Men hozircha bu ma\'lumotga kira olmayman.';

      // ── Salomlashish ──
      case Intent.greeting:
        final hour = DateTime.now().hour;
        if (hour < 12) return 'Xayrli tong! Bugun sizga qanday yordam bera olaman? 😊';
        if (hour < 17) return 'Xayrli kun! Buyuring, xizmatingizdaman! 👋';
        return 'Xayrli oqshom! Nima kerak bo\'lsa ayting! 🌙';

      // ── Holini so'rash ──
      case Intent.wellbeing:
        final responses = [
          'Rahmat, juda yaxshi! Siz qalaysiz?',
          'Zo\'rman, har doim sizga xizmat qilishga tayyorman!',
          'Ajoyib! Sizning xizmatingizdaman!',
          'Yaxshi, zerikmayman chunki siz bilan birga ishlayman! 😄',
        ];
        responses.shuffle();
        return responses.first;

      // ── Rahmat ──
      case Intent.thanks:
        final responses = [
          'Xush kelib qoldi! Har doim xizmatingizdaman! 😊',
          'Arzimaydi! Yana yordam kerak bo\'lsa ayting!',
          'Marhamat! Siz bilan ishlash menga ham yoqadi! 🌟',
          'Bajonudil! Keyingi buyrug\'ingizni kuting! ✨',
        ];
        responses.shuffle();
        return responses.first;

      // ── Yordam ──
      case Intent.help:
        return '''Men quyidagilarni bajaraman:
📞 Qo\'ng\'iroq: "akamga qo\'ng\'iroq qil"
💬 SMS: "onaga xabar yubor"
📱 Ilovalar: Telegram, YouTube, Instagram...
🌤️ Ob-havo: "bugun havo qanday"
🎵 Musiqa: "biror qo\'shiq qo\'y"
📍 Xarita: "toshkentni xaritada ko\'rsat"
🔍 Qidiruv: "google dan topib ber"
⏰ Vaqt: "soat necha bo\'ldi"
📷 Kamera: "kamerani yoq"
...va boshqalar!''';

      // ── AI ga yuborish ──
      case Intent.ai:
      default:
        return null;
    }
  }

  // ── Qo'ng'iroq ────────────────────────────────────────────────────
  Future<String> _handleCall(String text, String? relationship) async {
    if (!await Permission.phone.isGranted) {
      await Permission.phone.request();
    }

    // Raqam bormi?
    final num = RegExp(r'[\+]?[0-9]{7,13}').firstMatch(text)?.group(0);
    if (num != null) {
      await launchUrl(Uri.parse('tel:$num'), mode: LaunchMode.externalApplication);
      return '$num ga qo\'ng\'iroq qilinmoqda!';
    }

    // Munosabat bo'yicha kontaktdan topish
    if (relationship != null) {
      await ContactService.loadContacts();
      return await ContactService.callByRelationship(relationship);
    }

    // Ism bo'yicha qidirish
    final name = _extractName(text, NlpService.callTriggers);
    if (name.isNotEmpty) {
      await ContactService.loadContacts();
      return await ContactService.callContact(name);
    }

    await launchUrl(Uri.parse('tel:'), mode: LaunchMode.externalApplication);
    return 'Kimga qo\'ng\'iroq qilishni ayting!';
  }

  // ── SMS ─────────────────────────────────────────────────────────
  Future<String> _handleSms(String text, String? relationship) async {
    final num = RegExp(r'[\+]?[0-9]{7,13}').firstMatch(text)?.group(0);
    if (num != null) {
      await launchUrl(Uri.parse('sms:$num'), mode: LaunchMode.externalApplication);
      return '$num ga SMS ochildi!';
    }

    if (relationship != null) {
      await ContactService.loadContacts();
      return await ContactService.smsByRelationship(relationship);
    }

    final name = _extractName(text, NlpService.smsTriggers);
    if (name.isNotEmpty) {
      await ContactService.loadContacts();
      return await ContactService.smsContact(name);
    }

    await launchUrl(Uri.parse('sms:'), mode: LaunchMode.externalApplication);
    return 'SMS ochildi!';
  }

  // ── Ilova ochish ────────────────────────────────────────────────
  Future<String> _app(String scheme, String pkg, String name) async {
    try {
      if (scheme.isNotEmpty) {
        final uri = Uri.parse(scheme);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return '$name ochildi!';
        }
      }
      final uri = Uri.parse('android-app://$pkg');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return '$name ochildi!';
      }
      await _web('https://play.google.com/store/apps/details?id=$pkg');
      return '$name topilmadi. Play Store ochildi!';
    } catch (_) {
      return '$name ochilmadi!';
    }
  }

  Future<void> _web(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  String _extractName(String text, List<String> triggers) {
    var n = text;
    for (final t in triggers) n = n.replaceAll(t, '');
    for (final w in ['ga', 'ni', 'qil', 'ber', 'yubor', 'jo\'nat', 'chaqir']) {
      n = n.replaceAll(RegExp('\\b$w\\b'), '');
    }
    return n.trim();
  }
}
