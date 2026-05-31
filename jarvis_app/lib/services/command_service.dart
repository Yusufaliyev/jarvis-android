import 'package:url_launcher/url_launcher.dart';

class CommandService {
  Future<String?> execute(String command) async {
    final cmd = command.toLowerCase();

    if (cmd.contains('telegram')) {
      await _open('https://t.me');
      return 'Telegram ochildi!';
    }
    if (cmd.contains('youtube')) {
      await _open('https://youtube.com');
      return 'YouTube ochildi!';
    }
    if (cmd.contains('instagram')) {
      await _open('https://instagram.com');
      return 'Instagram ochildi!';
    }
    if (cmd.contains('google') || cmd.contains('qidir')) {
      await _open('https://google.com');
      return 'Google ochildi!';
    }
    if (cmd.contains('qo\'ng\'iroq') || cmd.contains('call')) {
      await _open('tel:');
      return 'Qo\'ng\'iroq sahifasi ochildi!';
    }
    if (cmd.contains('sms') || cmd.contains('xabar')) {
      await _open('sms:');
      return 'SMS ochildi!';
    }
    if (cmd.contains('sozlamalar') || cmd.contains('settings')) {
      await _open('app-settings:');
      return 'Sozlamalar ochildi!';
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
