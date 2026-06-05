import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'nlp_service.dart';

class ContactService {
  static List<Contact> _contacts = [];
  static bool _loaded = false;

  static Future<bool> loadContacts() async {
    if (_loaded && _contacts.isNotEmpty) return true;
    if (!await Permission.contacts.isGranted) {
      final r = await Permission.contacts.request();
      if (!r.isGranted) return false;
    }
    try {
      _contacts = await FlutterContacts.getContacts(withProperties: true);
      _loaded = true;
      return true;
    } catch (_) { return false; }
  }

  // Munosabat bo'yicha qidirish (aka, opa, onam...)
  static Contact? _findByRelationship(String relationship) {
    final aliases = NlpService.relationships[relationship] ?? [];
    for (final contact in _contacts) {
      final name = contact.displayName.toLowerCase();
      for (final alias in aliases) {
        if (name.contains(alias)) return contact;
      }
      // Kontakt eslatmasida ham qidirish
      for (final note in contact.notes) {
        if (aliases.any((a) => note.note.toLowerCase().contains(a))) {
          return contact;
        }
      }
    }
    return null;
  }

  // Ism bo'yicha qidirish
  static Contact? findContact(String name) {
    if (!_loaded || _contacts.isEmpty) return null;
    final q = name.toLowerCase().trim();
    if (q.isEmpty) return null;

    // To'liq moslik
    for (final c in _contacts) {
      if (c.displayName.toLowerCase() == q) return c;
    }
    // Qisman moslik
    for (final c in _contacts) {
      if (c.displayName.toLowerCase().contains(q)) return c;
    }
    // So'zma-so'z moslik
    for (final c in _contacts) {
      final parts = c.displayName.toLowerCase().split(' ');
      if (parts.any((p) => p.startsWith(q) || q.startsWith(p))) return c;
    }
    return null;
  }

  // Munosabat orqali qo'ng'iroq
  static Future<String> callByRelationship(String relationship) async {
    final contact = _findByRelationship(relationship);
    if (contact == null) {
      final relName = NlpService.relationships[relationship]?.first ?? relationship;
      return 'Kontaktlarda "$relName" topilmadi. Kontaktingizga qo\'shing!';
    }
    return _call(contact);
  }

  // Ism orqali qo'ng'iroq
  static Future<String> callContact(String name) async {
    final contact = findContact(name);
    if (contact == null) return '"$name" kontaktlarda topilmadi!';
    return _call(contact);
  }

  static Future<String> _call(Contact contact) async {
    if (contact.phones.isEmpty) return '${contact.displayName} ning raqami yo\'q!';
    final phone = contact.phones.first.number.replaceAll(' ', '');
    await launchUrl(Uri.parse('tel:$phone'), mode: LaunchMode.externalApplication);
    return '${contact.displayName} ga qo\'ng\'iroq qilinmoqda! 📞';
  }

  // Munosabat orqali SMS
  static Future<String> smsByRelationship(String relationship) async {
    final contact = _findByRelationship(relationship);
    if (contact == null) {
      final relName = NlpService.relationships[relationship]?.first ?? relationship;
      return '"$relName" kontaktlarda topilmadi!';
    }
    return _sms(contact);
  }

  // Ism orqali SMS
  static Future<String> smsContact(String name, {String? text}) async {
    final contact = findContact(name);
    if (contact == null) return '"$name" kontaktlarda topilmadi!';
    return _sms(contact, text: text);
  }

  static Future<String> _sms(Contact contact, {String? text}) async {
    if (contact.phones.isEmpty) return '${contact.displayName} ning raqami yo\'q!';
    final phone = contact.phones.first.number.replaceAll(' ', '');
    final body = text != null ? '?body=${Uri.encodeComponent(text)}' : '';
    await launchUrl(Uri.parse('sms:$phone$body'), mode: LaunchMode.externalApplication);
    return '${contact.displayName} ga SMS ochildi! 💬';
  }

  static int get count => _contacts.length;
}
