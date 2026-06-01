import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class CommandService {
  Future<String?> execute(String command) async {
    final cmd = command.toLowerCase().trim();

    // ═══ ILOVALAR ═══
    if (cmd.contains('telegram')) {
      await _open('tg://'); return 'Telegram ochildi!';
    }
    if (cmd.contains('youtube')) {
      await _open('vnd.youtube://'); return 'YouTube ochildi!';
    }
    if (cmd.contains('instagram')) {
      await _open('instagram://app'); return 'Instagram ochildi!';
    }
    if (cmd.contains('facebook')) {
      await _open('fb://'); return 'Facebook ochildi!';
    }
    if (cmd.contains('tiktok')) {
      await _open('snssdk1233://'); return 'TikTok ochildi!';
    }
    if (cmd.contains('spotify') || cmd.contains('musiqa')) {
      await _open('spotify://'); return 'Spotify ochildi!';
    }
    if (cmd.contains('gmail') || cmd.contains('pochta')) {
      await _open('googlegmail://'); return 'Gmail ochildi!';
    }
    if (cmd.contains('whatsapp')) {
      await _open('whatsapp://'); return 'WhatsApp ochildi!';
    }
    if (cmd.contains('maps') || cmd.contains('xarita') || cmd.contains('navigatsiya')) {
      await _open('google.navigation://'); return 'Xarita ochildi!';
    }

    // ═══ QIDIRUV ═══
    if (cmd.contains('qidir') || cmd.contains('google')) {
      final q = cmd
        .replaceAll('google', '').replaceAll('qidir', '')
        .replaceAll('da', '').replaceAll('dan', '').trim();
      final url = q.isNotEmpty
        ? 'https://www.google.com/search?q=${Uri.encodeComponent(q)}'
        : 'https://www.google.com';
      await _openWeb(url);
      return q.isNotEmpty ? '"$q" qidirilmoqda!' : 'Google ochildi!';
    }
    if (cmd.contains('youtube') && cmd.contains('qidir')) {
      final q = cmd.replaceAll('youtube', '').replaceAll('qidir', '').trim();
      await _openWeb('https://youtube.com/results?search_query=${Uri.encodeComponent(q)}');
      return 'YouTube\'da "$q" qidirilmoqda!';
    }

    // ═══ QO'NG'IROQ ═══
    if (cmd.contains('qo\'ng\'iroq') || cmd.contains('chaqir') || cmd.contains('call')) {
      bool ok = await Permission.phone.isGranted;
      if (!ok) {
        await Permission.phone.request();
        return 'Qo\'ng\'iroq ruxsati berildi. Kimga qo\'ng\'iroq qilaylik?';
      }
      // Raqam ajratib olish
      final num = RegExp(r'[\+]?[0-9]{9,13}').firstMatch(cmd)?.group(0);
      if (num != null) {
        await _open('tel:$num');
        return '$num ga qo\'ng\'iroq qilinmoqda!';
      }
      await _open('tel:');
      return 'Kimga qo\'ng\'iroq qilishni ayting!';
    }

    // ═══ SMS ═══
    if (cmd.contains('sms') || cmd.contains('xabar yubor')) {
      final num = RegExp(r'[\+]?[0-9]{9,13}').firstMatch(cmd)?.group(0);
      if (num != null) {
        await _open('sms:$num');
        return '$num ga SMS yuborilmoqda!';
      }
      await _open('sms:');
      return 'SMS yuborish sahifasi ochildi!';
    }

    // ═══ KAMERA ═══
    if (cmd.contains('kamera') || cmd.contains('rasm ol') || cmd.contains('selfie')) {
      await _openWeb('camera');
      return 'Kamera ochildi!';
    }

    // ═══ SOZLAMALAR ═══
    if (cmd.contains('sozlama') || cmd.contains('settings')) {
      await _open('app-settings:'); return 'Sozlamalar ochildi!';
    }
    if (cmd.contains('wifi')) {
      await _open('android-app://com.android.settings/.wifi.WifiSettings');
      return 'WiFi sozlamalari ochildi!';
    }
    if (cmd.contains('bluetooth')) {
      await _open('android-app://com.android.settings/.BluetoothSettings');
      return 'Bluetooth sozlamalari ochildi!';
    }

    // ═══ YANGILIKLAR ═══
    if (cmd.contains('yangilik') || cmd.contains('xabar')) {
      await _openWeb('https://kun.uz'); return 'Yangiliklar ochildi!';
    }

    // ═══ HISOB ═══
    if (cmd.contains('kalkulyator') || cmd.contains('hisob')) {
      await _open('android-app://com.google.android.calculator');
      return 'Kalkulyator ochildi!';
    }

    // AI ga yuborish
    return null;
  }

  Future<void> _open(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Agar ilova yo'q bo'lsa — Play Store
        await _openWeb('https://play.google.com/store/search?q=${url.split('://')[0]}');
      }
    } catch (_) {}
  }

  Future<void> _openWeb(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
