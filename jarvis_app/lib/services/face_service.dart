import 'dart:io';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FaceService {
  static FaceDetector? _detector;
  static List<CameraDescription>? _cameras;

  static Future<void> init() async {
    _cameras = await availableCameras();
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
  }

  static CameraDescription? get frontCamera {
    if (_cameras == null || _cameras!.isEmpty) return null;
    try {
      return _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
    } catch (_) {
      return _cameras!.first;
    }
  }

  // Rasm fayli orqali tahlil (oson va ishonchli)
  static Future<FaceResult> analyzeFile(String imagePath) async {
    if (_detector == null) return FaceResult.noFace;
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _detector!.processImage(inputImage);

      if (faces.isEmpty) return FaceResult.noFace;

      final face = faces.first;
      final smile = face.smilingProbability ?? 0;
      final leftEye = face.leftEyeOpenProbability ?? 1;
      final rightEye = face.rightEyeOpenProbability ?? 1;
      final eyesOpen = (leftEye + rightEye) / 2;

      if (smile > 0.7) return FaceResult.happy;
      if (eyesOpen < 0.3) return FaceResult.tired;
      if (smile < 0.2) return FaceResult.neutral;
      return FaceResult.normal;
    } catch (e) {
      return FaceResult.noFace;
    }
  }

  static String getGreeting(FaceResult result, String name) {
    final h = DateTime.now().hour;
    final t = h < 12 ? 'Xayrli tong' : h < 17 ? 'Xayrli kun' : 'Xayrli oqshom';
    switch (result) {
      case FaceResult.happy:
        return '$t, $name! Bugun kayfiyatingiz ajoyib! Nima qilaylik?';
      case FaceResult.tired:
        return '$t, $name. Biroz charchagandek ko\'rinasiz. Dam olish kerakmi?';
      case FaceResult.neutral:
        return '$t, $name! Men Jarvis, doim yoningizdaman!';
      case FaceResult.normal:
        return '$t, $name! Buyuring!';
      case FaceResult.noFace:
        return 'Assalomu alaykum! Men Jarvis. Buyuring!';
    }
  }

  static void dispose() => _detector?.close();
}

enum FaceResult { happy, tired, neutral, normal, noFace }
