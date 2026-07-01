/// MLKit does not exist in the browser; receipt OCR is native-only.
Future<String> runReceiptOcr(String imagePath) async =>
    throw UnsupportedError('Receipt OCR is not available on web.');
