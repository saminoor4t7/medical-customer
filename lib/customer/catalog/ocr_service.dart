import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device Latin text recognition for medicine labels and prescriptions.
class MedicineOcrService {
  Future<String> recognizeFile(String path) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(path),
      );
      return result.text.trim();
    } finally {
      await recognizer.close();
    }
  }
}
