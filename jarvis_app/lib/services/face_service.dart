import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FaceService {
  static FaceDetector? _detector;
  static List<CameraDescription>? _cameras;
  static bool _faceRegistered = false;

  // Boshlash
  static Future<void> init() async {
    _cameras = await availableCameras();
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true, // tabassum aniqlash
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    _faceRegistered = prefs.getBool('face_registered') ?? false;
  }

  // Old kamera
  static CameraDescription? get frontCamera {
    if (_cameras == null) return null;
    try {
      return _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
    } catch (_) {
      return _cameras!.isNotEmpty ? _cameras!.first : null;
    }
  }

  // Yuzni tahlil qilish
  static Future<FaceResult> analyzeFace(CameraImage image) async {
    if (_detector == null) return FaceResult.noFace;

    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation270deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final faces = await _detector!.processImage(inputImage);

      if (faces.isEmpty) return FaceResult.noFace;

      final face = faces.first;
      final smile = face.smilingProbability ?? 0;
      final leftEye = face.leftEyeOpenProbability ?? 1;
      final rightEye = face.rightEyeOpenProbability ?? 1;
      final eyesOpen = (leftEye + rightEye) / 2;

      // Xissiyotni aniqlash
      if (smile > 0.7) return FaceResult.happy;
      if (eyesOpen < 0.3) return FaceResult.tired;
      if (smile < 0.2) return FaceResult.neutral;
      return FaceResult.normal;
    } catch (e) {
      return FaceResult.noFace;
    }
  }

  // Yuzni ro'yxatdan o'tkazish
  static Future<void> registerFace() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('face_registered', true);
    _faceRegistered = true;
  }

  static bool get isFaceRegistered => _faceRegistered;

  // Salomlashuv matni
  static String getGreeting(FaceResult result, String name) {
    final hour = DateTime.now().hour;
    String timeGreeting = hour < 12
        ? 'Xayrli tong'
        : hour < 17
            ? 'Xayrli kun'
            : 'Xayrli oqshom';

    switch (result) {
      case FaceResult.happy:
        return '$timeGreeting, $name! Bugun kayfiyatingiz ajoyib ko\'rinadi! Nima qilaylik?';
      case FaceResult.tired:
        return '$timeGreeting, $name. Biroz charchagandek ko\'rinasiz. Dam olish kerakmi?';
      case FaceResult.neutral:
        return '$timeGreeting, $name. Men Jarvis, bugun ham yoningizdaman!';
      case FaceResult.normal:
        return '$timeGreeting, $name! Buyuring!';
      case FaceResult.noFace:
        return 'Assalomu alaykum! Men Jarvis. Buyuring!';
    }
  }

  static void dispose() {
    _detector?.close();
  }
}

enum FaceResult { happy, tired, neutral, normal, noFace }
