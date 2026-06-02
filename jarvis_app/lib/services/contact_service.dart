import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactService {
  static List<Contact> _contacts = [];
  static bool _loaded = false;

  // Kontaktlarni yuklash
  static Future<bool> loadContacts() async {
    if (!await Permission.contacts.isGranted) {
      final r = await Permission.contacts.request();
      if (!r.isGranted) return false;
    }
    try {
      _contacts = await FlutterContacts.getContacts(withProperties: true);
      _loaded = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  // Kontaktni ismdan qidirish
  static Contact? findContact(String name) {
    if (!_loaded || _contacts.isEmpty) return null;
    final q = name.toLowerCase().trim();

    // To'liq ism moslik
    for (final c in _contacts) {
      if (c.displayName.toLowerCase().contains(q)) return c;
    }

    // Ism qismlari
    for (final c in _contacts) {
      final parts = c.displayName.toLowerCase().split(' ');
      if (parts.any((p) => p.contains(q))) return c;
    }

    return null;
  }

  // Kontaktga qo'ng'iroq
  static Future<String> callContact(String name) async {
    if (!_loaded) await loadContacts();
    final contact = findContact(name);

    if (contact == null) {
      return '$name kontaktlarda topilmadi!';
    }

    if (contact.phones.isEmpty) {
      return '${contact.displayName} ning raqami yo\'q!';
    }

    final phone = contact.phones.first.number.replaceAll(' ', '');
    final uri = Uri.parse('tel:$phone');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return '${contact.displayName} ga qo\'ng\'iroq qilinmoqda!';
    }
    return 'Qo\'ng\'iroq qilib bo\'lmadi!';
  }

  // Kontaktga SMS
  static Future<String> smsContact(String name, {String? text}) async {
    if (!_loaded) await loadContacts();
    final contact = findContact(name);

    if (contact == null) return '$name kontaktlarda topilmadi!';
    if (contact.phones.isEmpty) return '${contact.displayName} ning raqami yo\'q!';

    final phone = contact.phones.first.number.replaceAll(' ', '');
    final body = text != null ? Uri.encodeComponent(text) : '';
    final uri = Uri.parse('sms:$phone?body=$body');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return '${contact.displayName} ga SMS ochildi!';
    }
    return 'SMS yuborib bo\'lmadi!';
  }

  // Kontaktlar ro'yxatini qaytarish
  static List<String> getNames({int limit = 5}) {
    if (!_loaded) return [];
    return _contacts.take(limit).map((c) => c.displayName).toList();
  }

  // Umumiy kontaktlar soni
  static int get count => _contacts.length;
}
