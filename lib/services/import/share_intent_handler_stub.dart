import 'package:go_router/go_router.dart';

import 'amazon_import_service.dart';
import 'bank_statement_parser.dart';
import 'import_receipt_ocr_service.dart';

/// Web stub: browsers have no share-target intent stream, so this handler
/// does nothing. Kept API-compatible with the Android implementation.
class ShareIntentHandler {
  final GoRouter router;
  final ImportReceiptOcrService ocrService;
  final AmazonImportService amazonService;
  final BankStatementParser bankParser;

  ShareIntentHandler({
    required this.router,
    required this.ocrService,
    required this.amazonService,
    required this.bankParser,
  });

  Future<void> init() async {}

  void dispose() {}
}
