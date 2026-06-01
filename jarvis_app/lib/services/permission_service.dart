import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<void> requestAll() async {
    await [
      Permission.microphone,
      Permission.camera,
      Permission.storage,
    ].request();
  }
}
