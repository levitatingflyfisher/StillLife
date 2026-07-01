import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Runs MLKit text recognition over the image at [imagePath] and returns the
/// raw recognized text.
Future<String> runReceiptOcr(String imagePath) async {
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognized = await recognizer.processImage(inputImage);
    return recognized.text;
  } finally {
    recognizer.close();
  }
}
