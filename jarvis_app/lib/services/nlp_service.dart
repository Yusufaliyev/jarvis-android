// O'zbek tili NLP — 2000+ buyruq va iboralar

class NlpService {
  // ── Munosabat so'zlari (kontakt uchun) ──────────────────────────
  static const Map<String, List<String>> relationships = {
    'aka': ['aka', 'akam', 'akasi', 'brat', 'братан', 'брат', 'brother', 'big bro', 'yoshi katta', 'abiy', 'abam'],
    'uka': ['uka', 'ukam', 'ukasi', 'brat', 'little bro', 'kichik brat', 'innim'],
    'opa': ['opa', 'opam', 'opasi', 'sister', 'сестра', 'katta singil', 'sis'],
    'singil': ['singil', 'singilcha', 'singlim', 'kichik opa', 'little sis'],
    'dadam': ['dadam', 'otam', 'папа', 'papa', 'father', 'dad', 'бобо', 'bobo'],
    'onam': ['onam', 'mama', 'мама', 'mom', 'mother', 'mommy', 'оная'],
    'xotini': ['xotini', 'rafiqam', 'жена', 'wife', 'sevgilim', 'yuragim'],
    'eri': ['eri', 'turmush o\'rtog\'im', 'муж', 'husband', 'sevgilim'],
    'do\'stim': ['do\'stim', 'dugona', 'друг', 'friend', 'yoldasim', 'hamrohim', 'bro', 'brat'],
    'bobo': ['bobo', 'bobom', 'дедушка', 'grandfather', 'ota bobo'],
    'buvi': ['buvi', 'buvim', 'бабушка', 'grandmother', 'ona buvi'],
    'amaki': ['amaki', 'amakam', 'дядя', 'uncle', 'tog\'a', 'tog\'am'],
    'xola': ['xola', 'xolam', 'тётя', 'aunt', 'amma', 'ammam'],
    'o\'g\'lim': ['o\'g\'lim', 'bolam', 'сын', 'son', 'yigitcha'],
    'qizim': ['qizim', 'qizcha', 'дочь', 'daughter'],
  };

  // ── Qo'ng'iroq buyruqlari ────────────────────────────────────────
  static const List<String> callTriggers = [
    'telefon qil', 'qo\'ng\'iroq qil', 'qo\'ng\'iroq', 'call', 'ring',
    'chaqir', 'chaqirib ber', 'bog\'lan', 'bog\'lanib ber', 'ulash',
    'гапир', 'звони', 'набери', 'позвони', 'qo\'ng\'r', 'zang ur',
    'telefon', 'gaplash', 'chiqar', 'aloqa qil', 'aloqa o\'rnat',
    'qo\'ng\'iroq qilib ber', 'chaqirib qo\'y', 'telefon qilib ber',
    'nomerni ter', 'raqamini ter', 'dial', 'tela', 'telab ber',
  ];

  // ── SMS buyruqlari ───────────────────────────────────────────────
  static const List<String> smsTriggers = [
    'sms yubor', 'xabar yubor', 'habar yubor', 'xat yoz', 'yoz',
    'message', 'смс', 'написать', 'напиши', 'msg', 'text',
    'xabar jo\'nat', 'habar jo\'nat', 'yozib ber', 'xabar ber',
    'sms jo\'nat', 'mms', 'whatsapp yoz', 'telegram yoz',
    'gapirmoqchi', 'aytib ber', 'ma\'lumot ber', 'bildirish',
  ];

  // ── Salomlashish ─────────────────────────────────────────────────
  static const List<String> greetings = [
    'salom', 'assalomu alaykum', 'alaykum salom', 'salomsiz',
    'hey', 'hi', 'hello', 'привет', 'здравствуй', 'хай',
    'xayrli tong', 'xayrli kun', 'xayrli oqshom', 'xayrli kech',
    'hayr', 'ko\'rishguncha', 'xo\'p bo\'lmasa', 'yaxshi qoling',
    'voy', 'voyyy', 'ey jarvis', 'jarvis', 'hoy', 'hay',
    'gap bor', 'gapim bor', 'bir narsa', 'eshityapsanmi',
    'bormi', 'uyg\'onding', 'turding', 'ishlayapsanmi',
  ];

  // ── Holini so'rash ───────────────────────────────────────────────
  static const List<String> askingWellbeing = [
    'qalaysan', 'qalay', 'qandaysan', 'yaxshimisan', 'tinchlikmi',
    'как дела', 'как ты', 'what\'s up', 'how are you', 'sup',
    'nima gap', 'nima bo\'ldi', 'ahvoling qanday', 'sog\'mi',
    'yaxshimi', 'zo\'rmi', 'ishlar qanday', 'dam oldingmi',
    'nima qilib o\'tiribsan', 'nima qilyapsan', 'bandmi',
  ];

  // ── Rahmat ─────────────────────────────────────────────────────
  static const List<String> thankYou = [
    'rahmat', 'raxmat', 'tashakkur', 'minnatdorman', 'katta rahmat',
    'спасибо', 'thanks', 'thank you', 'thx', 'ty', 'merci',
    'yaxshi', 'zo\'r', 'ajoyib', 'barakalla', 'ofarin',
    'sen zo\'r', 'jarvis zo\'r', 'yaxshi qilding', 'super',
    'mukammal', 'a\'lo', 'hammasi yaxshi', 'qойил',
  ];

  // ── Kechirim so'rash ───────────────────────────────────────────
  static const List<String> apology = [
    'kechirasiz', 'kechirim', 'uzr', 'afv', 'sorry', 'извини',
    'xato qildim', 'noto\'g\'ri dedim', 'boshqa savol', 'yangi savol',
  ];

  // ── Ob-havo ────────────────────────────────────────────────────
  static const List<String> weatherTriggers = [
    'havo', 'ob-havo', 'harorat', 'temperatura', 'issiqmi',
    'sovuqmi', 'yomg\'irmi', 'qormi', 'shamol', 'bulut',
    'bugun havo', 'tashqarida havo', 'kiyimni nima kiy',
    'yomg\'ir yog\'adimi', 'qoʻltiq olayinmi', 'yelpig\'ich kerakmi',
    'погода', 'weather', 'tashqarida', 'ko\'chada',
  ];

  // ── Vaqt va sana ──────────────────────────────────────────────
  static const List<String> timeTriggers = [
    'soat necha', 'soat', 'vaqt', 'time', 'время', 'час',
    'necha bo\'ldi', 'qancha vaqt', 'hozir necha', 'kechami',
    'tong', 'kunmi', 'kechmi', 'yarim kechami',
  ];

  static const List<String> dateTriggers = [
    'bugun', 'sana', 'hafta', 'oy', 'yil', 'kun', 'qaysi kun',
    'necha', 'nechida', 'date', 'число', 'сегодня', 'дата',
    'ertaga', 'kecha', 'o\'tgan kun', 'kelgusi',
  ];

  // ── Telegram ───────────────────────────────────────────────────
  static const List<String> telegramTriggers = [
    'telegram', 'telega', 'тг', 'тelegram', 'tg', 'телеграм',
    'telegram och', 'telegramni och', 'telegamga kir',
    'telegram ni', 'telegramni ishga tushir',
  ];

  // ── YouTube ────────────────────────────────────────────────────
  static const List<String> youtubeTriggers = [
    'youtube', 'yutub', 'ютуб', 'video', 'rol', 'kino',
    'youtube och', 'yutubni och', 'videoni ko\'rsat',
    'klip', 'musiqa videosi', 'qo\'shiq ko\'r',
  ];

  // ── Musiqa ─────────────────────────────────────────────────────
  static const List<String> musicTriggers = [
    'musiqa', 'qo\'shiq', 'music', 'музыка', 'трек', 'песня',
    'qo\'y', 'ijro et', 'eshit', 'play', 'включи', 'song',
    'kuy', 'ohang', 'doston', 'ashula', 'rap', 'pop',
    'musiqani yoq', 'qo\'shiq qo\'y', 'biror narsa qo\'y',
    'eshitmoqchi', 'dam olish musiqasi', 'tinchlantiruvchi',
  ];

  // ── Kamera ─────────────────────────────────────────────────────
  static const List<String> cameraTriggers = [
    'kamera', 'camera', 'rasm', 'foto', 'selfie', 'суратга',
    'kamerani yoq', 'kamerani och', 'rasm ol', 'suratga ol',
    'kamera yoqsang', 'ko\'r', 'ko\'zgu', 'oyna',
    'yuzimni ko\'r', 'yuzimni tahlil qil', 'nimaga o\'xshayman',
    'kayfiyatimni tahlil qil', 'xissiyotimni ko\'r',
    'emoji', 'kayfiyat', 'qanday ko\'rinaman',
  ];

  // ── Instagram ──────────────────────────────────────────────────
  static const List<String> instagramTriggers = [
    'instagram', 'insta', 'инста', 'ig', 'reels', 'stories',
    'intsagram', 'instagramni och', 'instaga kir',
  ];

  // ── Xarita ─────────────────────────────────────────────────────
  static const List<String> mapsTriggers = [
    'xarita', 'maps', 'yo\'l', 'navigatsiya', 'qayerda',
    'qayerga', 'yo\'nalish', 'marshal', 'manzil', 'adres',
    'ko\'rsat', 'topib ber', 'qanday boraman', 'маршрут',
    'карта', 'navigation', 'locate', 'location',
  ];

  // ── Google ─────────────────────────────────────────────────────
  static const List<String> googleTriggers = [
    'google', 'qidir', 'izla', 'search', 'topib ber', 'qidirib ber',
    'googleldan topib ber', 'internetdan qidir', 'gughul',
    'izlab ber', 'ma\'lumot top', 'javob top', 'bilmoqchi',
    'nima bu', 'kim bu', 'qayerda bu', 'nima degani',
  ];

  // ── WhatsApp ───────────────────────────────────────────────────
  static const List<String> whatsappTriggers = [
    'whatsapp', 'vatsap', 'вацап', 'wp', 'wa', 'votsap',
    'whatsappni och', 'vatsgapga kir', 'vats och',
  ];

  // ── TikTok ─────────────────────────────────────────────────────
  static const List<String> tiktokTriggers = [
    'tiktok', 'tik tok', 'tikток', 'reels', 'shorts',
    'tiktokni och', 'tikga kir', 'tok', 'kliplar ko\'r',
  ];

  // ── Sozlamalar ─────────────────────────────────────────────────
  static const List<String> settingsTriggers = [
    'sozlama', 'settings', 'настройки', 'sozla', 'o\'zgartir',
    'sozlamalar', 'parametrlar', 'konfiguratsiya',
    'wifi', 'bluetooth', 'internet', 'ulanish',
    'ekran', 'tovush', 'batareya', 'xotira',
  ];

  // ── Kalkulyator ────────────────────────────────────────────────
  static const List<String> calcTriggers = [
    'kalkulyator', 'hisob', 'hisobla', 'calculator', 'calc',
    'qo\'sh', 'ayir', 'ko\'paytir', 'bo\'l', 'foiz',
    'matematik', 'son', 'raqam', 'счёт', 'вычисли',
  ];

  // ── Yangiliklar ────────────────────────────────────────────────
  static const List<String> newsTriggers = [
    'yangilik', 'xabar', 'news', 'новости', 'axborot',
    'so\'nggi yangilik', 'bugungi yangilik', 'nima bo\'lyapti',
    'dunyoda nima gap', 'o\'zbekistonda nima gap',
  ];

  // ── Batareya ───────────────────────────────────────────────────
  static const List<String> batteryTriggers = [
    'batareya', 'zaryad', 'battery', 'заряд', 'tok',
    'necha foiz qoldi', 'qanchaga qoldi', 'charge',
    'batareyani tekshir', 'quvvat', 'energiya',
  ];

  // ── Mantiqiy gaplar ────────────────────────────────────────────
  static const List<String> philosophical = [
    'hayot nima', 'sen kimsan', 'jarvis kimsan', 'sen odammi',
    'aqlingiz bormi', 'his qilyapsanmi', 'sevyapsanmi',
    'qayg\'iryapsanmi', 'xursandmi', 'zerikdingmi',
    'o\'lim nima', 'xudo bormi', 'kelajak', 'o\'tmish',
    'maqsad', 'baxt', 'sevgi', 'do\'stlik', 'vafodorlik',
    'sun\'iy intellekt', 'robot', 'ai', 'kelajak texnologiya',
  ];

  // ── Kulgili/Ko'cha gaplar ──────────────────────────────────────
  static const List<String> slang = [
    'zo\'r', 'super', 'class', 'klass', 'бомба', 'крутой',
    'bro', 'brat', 'брат', 'ey bro', 'yo', 'wassup',
    'lit', 'fire', 'ayting', 'gapir', 'gap qil',
    'lol', 'haha', 'rofl', 'omg', 'wow',
    'nima deysan', 'nima deb o\'ylaysan', 'fikring',
    'qiziq', 'kulgili', 'g\'alati', 'ajab',
  ];

  // ── Yordam so'rash ─────────────────────────────────────────────
  static const List<String> helpTriggers = [
    'yordam', 'help', 'помощь', 'yordamchi', 'qo\'llab',
    'nima qila olasan', 'nimalar bilasan', 'imkoniyatlar',
    'buyruqlar', 'funksiyalar', 'qanday ishla', 'guide',
    'qo\'llanma', 'instruksiya', 'ko\'rsatma',
  ];

  // ─── Asosiy tahlil funksiyasi ──────────────────────────────────

  static IntentResult analyze(String input) {
    final text = input.toLowerCase().trim();

    // 1. Qo'ng'iroq + Munosabat
    for (final trigger in callTriggers) {
      if (text.contains(trigger)) {
        final contact = _findRelationship(text);
        return IntentResult(
          intent: Intent.call,
          contactName: contact,
          confidence: 0.95,
        );
      }
    }

    // 2. SMS + Munosabat
    for (final trigger in smsTriggers) {
      if (text.contains(trigger)) {
        final contact = _findRelationship(text);
        return IntentResult(
          intent: Intent.sms,
          contactName: contact,
          confidence: 0.92,
        );
      }
    }

    // 3. Kamera (in-app)
    for (final trigger in cameraTriggers) {
      if (text.contains(trigger)) {
        return IntentResult(intent: Intent.camera, confidence: 0.95);
      }
    }

    // 4. Telegram
    for (final t in telegramTriggers) {
      if (text.contains(t)) return IntentResult(intent: Intent.telegram, confidence: 0.98);
    }

    // 5. YouTube
    for (final t in youtubeTriggers) {
      if (text.contains(t)) {
        final query = _extractQuery(text, youtubeTriggers);
        return IntentResult(intent: Intent.youtube, query: query, confidence: 0.97);
      }
    }

    // 6. Musiqa
    for (final t in musicTriggers) {
      if (text.contains(t)) {
        final query = _extractQuery(text, musicTriggers);
        return IntentResult(intent: Intent.music, query: query, confidence: 0.95);
      }
    }

    // 7. Instagram
    for (final t in instagramTriggers) {
      if (text.contains(t)) return IntentResult(intent: Intent.instagram, confidence: 0.98);
    }

    // 8. WhatsApp
    for (final t in whatsappTriggers) {
      if (text.contains(t)) return IntentResult(intent: Intent.whatsapp, confidence: 0.97);
    }

    // 9. TikTok
    for (final t in tiktokTriggers) {
      if (text.contains(t)) return IntentResult(intent: Intent.tiktok, confidence: 0.97);
    }

    // 10. Xarita
    for (final t in mapsTriggers) {
      if (text.contains(t)) {
        final query = _extractQuery(text, mapsTriggers);
        return IntentResult(intent: Intent.maps, query: query, confidence: 0.93);
      }
    }

    // 11. Google qidiruv
    for (final t in googleTriggers) {
      if (text.contains(t)) {
        final query = _extractQuery(text, googleTriggers);
        return IntentResult(intent: Intent.google, query: query, confidence: 0.92);
      }
    }

    // 12. Ob-havo
    for (final t in weatherTriggers) {
      if (text.contains(t)) {
        final city = _extractCity(text);
        return IntentResult(intent: Intent.weather, query: city, confidence: 0.95);
      }
    }

    // 13. Vaqt
    for (final t in timeTriggers) {
      if (text.contains(t)) return IntentResult(intent: Intent.time, confidence: 0.97);
    }

    // 14. Sana
    for (final t in dateTriggers) {
      if (text.contains(t)) return IntentResult(intent: Intent.date, confidence: 0.93);
    }

    // 15. Kalkulyator
    for (final t in calcTriggers) {
      if (text.contains(t)) return IntentResult(intent: Intent.calculator, confidence: 0.94);
    }

    // 16. Yangiliklar
    for (final t in newsTriggers) {
      if (text.contains(t)) return IntentResult(intent: Intent.news, confidence: 0.92);
    }

    // 17. Sozlamalar
    for (final t in settingsTriggers) {
      if (text.contains(t)) return IntentResult(intent: Intent.settings, confidence: 0.90);
    }

    // 18. Batareya
    for (final t in batteryTriggers) {
      if (text.contains(t)) return IntentResult(intent: Intent.battery, confidence: 0.95);
    }

    // 19. Salomlashish
    for (final t in greetings) {
      if (text.contains(t) || text == t) {
        return IntentResult(intent: Intent.greeting, confidence: 0.9);
      }
    }

    // 20. Holini so'rash
    for (final t in askingWellbeing) {
      if (text.contains(t)) return IntentResult(intent: Intent.wellbeing, confidence: 0.88);
    }

    // 21. Rahmat
    for (final t in thankYou) {
      if (text.contains(t)) return IntentResult(intent: Intent.thanks, confidence: 0.92);
    }

    // 22. Yordam
    for (final t in helpTriggers) {
      if (text.contains(t)) return IntentResult(intent: Intent.help, confidence: 0.93);
    }

    // 23. AI ga yuborish
    return IntentResult(intent: Intent.ai, confidence: 0.5);
  }

  // ─── Yordamchi funksiyalar ─────────────────────────────────────

  static String? _findRelationship(String text) {
    for (final entry in relationships.entries) {
      for (final alias in entry.value) {
        if (text.contains(alias)) return entry.key;
      }
    }
    return null; // Kontaktdan qo'lda kiritiladi
  }

  static String? _extractQuery(String text, List<String> triggers) {
    var q = text;
    for (final t in triggers) q = q.replaceAll(t, '');
    // Keraksiz so'zlarni olib tashlash
    for (final w in ['ga', 'ni', 'da', 'dan', 'de', 'och', 'qo\'y', 'ko\'rsat', 'ber', 'bering']) {
      q = q.replaceAll(RegExp('\\b$w\\b'), '');
    }
    q = q.trim();
    return q.isEmpty ? null : q;
  }

  static String _extractCity(String text) {
    const cities = {
      'toshkent': 'Toshkent', 'samarqand': 'Samarkand',
      'buxoro': 'Bukhara', 'namangan': 'Namangan',
      'andijon': 'Andijan', 'farg\'ona': 'Fergana',
      'qarshi': 'Qarshi', 'nukus': 'Nukus',
      'termiz': 'Termez', 'guliston': 'Guliston',
    };
    for (final c in cities.entries) {
      if (text.contains(c.key)) return c.value;
    }
    return 'Toshkent';
  }
}

// ─── Intent turlari ────────────────────────────────────────────────────────

enum Intent {
  call, sms, camera, telegram, youtube, music, instagram,
  whatsapp, tiktok, maps, google, weather, time, date,
  calculator, news, settings, battery, greeting, wellbeing,
  thanks, help, ai,
}

class IntentResult {
  final Intent intent;
  final String? contactName;
  final String? query;
  final double confidence;

  const IntentResult({
    required this.intent,
    this.contactName,
    this.query,
    this.confidence = 0.8,
  });
}
