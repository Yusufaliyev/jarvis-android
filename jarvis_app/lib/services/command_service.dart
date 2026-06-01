import 'package:url_launcher/url_launcher.dart';

class CommandService {
  Future<String?> execute(String command) async {
    final cmd = command.toLowerCase();

    // Ilovalar
    if (cmd.contains('telegram')) { await _open('https://t.me'); return 'Telegram ochildi!'; }
    if (cmd.contains('youtube')) { await _open('https://youtube.com'); return 'YouTube ochildi!'; }
    if (cmd.contains('instagram')) { await _open('https://instagram.com'); return 'Instagram ochildi!'; }
    if (cmd.contains('facebook')) { await _open('https://facebook.com'); return 'Facebook ochildi!'; }
    if (cmd.contains('twitter') || cmd.contains('x.com')) { await _open('https://x.com'); return 'Twitter ochildi!'; }
    if (cmd.contains('tiktok')) { await _open('https://tiktok.com'); return 'TikTok ochildi!'; }
    if (cmd.contains('gmail') || cmd.contains('pochta')) { await _open('https://gmail.com'); return 'Gmail ochildi!'; }
    if (cmd.contains('spotify') || cmd.contains('musiqa')) { await _open('https://spotify.com'); return 'Spotify ochildi!'; }

    // Qidiruv
    if (cmd.contains('google') || cmd.contains('qidir')) {
      final q = cmd.replaceAll(RegExp(r'google|qidir|da|dan'), '').trim();
      await _open(q.isNotEmpty ? 'https://google.com/search?q=$q' : 'https://google.com');
      return q.isNotEmpty ? '"$q" qidirilmoqda!' : 'Google ochildi!';
    }

    // Xarita
    if (cmd.contains('xarita') || cmd.contains('maps') || cmd.contains('yo\'l')) {
      await _open('https://maps.google.com'); return 'Xarita ochildi!';
    }

    // Qo'ng'iroq
    if (cmd.contains('qo\'ng\'iroq') || cmd.contains('call') || cmd.contains('chaqir')) {
      await _open('tel:'); return 'Qo\'ng\'iroq qilish uchun raqam kiriting!';
    }

    // SMS
    if (cmd.contains('sms') || cmd.contains('xabar yubor') || cmd.contains('yoz')) {
      await _open('sms:'); return 'SMS yuborish sahifasi ochildi!';
    }

    // Sozlamalar
    if (cmd.contains('sozlama') || cmd.contains('settings')) {
      await _open('app-settings:'); return 'Sozlamalar ochildi!';
    }
    if (cmd.contains('wifi') || cmd.contains('internet')) {
      await _open('app-settings:'); return 'WiFi sozlamalariga o\'ting!';
    }
    if (cmd.contains('bluetooth')) {
      await _open('app-settings:'); return 'Bluetooth sozlamalariga o\'ting!';
    }

    // Kamera
    if (cmd.contains('kamera') || cmd.contains('rasm') || cmd.contains('selfie')) {
      await _open('https://camera'); return 'Kamera ochildi!';
    }

    // Yangiliklar
    if (cmd.contains('yangilik') || cmd.contains('xabar')) {
      await _open('https://kun.uz'); return 'Yangiliklar ochildi!';
    }

    return null;
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
