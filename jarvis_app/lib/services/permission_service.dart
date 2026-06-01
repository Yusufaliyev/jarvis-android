import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<void> requestAll() async {
    await [
      Permission.microphone,
      Permission.camera,
      Permission.location,
      Permission.phone,
      Permission.sms,
      Permission.contacts,
      Permission.storage,
      Permission.notification,
    ].request();
  }

  static Future<bool> hasMicrophone() async =>
      await Permission.microphone.isGranted;

  static Future<bool> hasCamera() async =>
      await Permission.camera.isGranted;

  static Future<bool> hasLocation() async =>
      await Permission.location.isGranted;

  static Future<bool> hasPhone() async =>
      await Permission.phone.isGranted;

  static Future<bool> hasSms() async =>
      await Permission.sms.isGranted;

  static Future<bool> hasContacts() async =>
      await Permission.contacts.isGranted;
}
