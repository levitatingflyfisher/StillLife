import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../features/import/domain/import_review_item.dart';
import 'amazon_import_service.dart';
import 'bank_statement_parser.dart';
import 'import_receipt_ocr_service.dart';

/// Handles files shared to Still Life from other Android apps.
///
/// Call [init] once after the app has started (after [runApp]).  The handler
/// subscribes to [ReceiveSharingIntent] streams and routes each incoming file
/// to the correct import screen via the provided [GoRouter]:
///
/// | File type           | Route         |
/// |---------------------|---------------|
/// | image/*             | importReview  (receipt OCR)       |
/// | text/csv, .csv ext  | bankColumns   (bank CSV mapping)  |
/// | text/plain, .txt    | importReview  (Amazon text)       |
/// | application/pdf     | importReview  (fallback: empty)   |
///
/// This class holds no state beyond the subscription; call [dispose] to
/// cancel the subscription.
class ShareIntentHandler {
  final GoRouter router;
  final ImportReceiptOcrService ocrService;
  final AmazonImportService amazonService;
  final BankStatementParser bankParser;

  StreamSubscription<List<SharedMediaFile>>? _sub;
  bool _busy = false;

  ShareIntentHandler({
    required this.router,
    required this.ocrService,
    required this.amazonService,
    required this.bankParser,
  });

  /// Subscribes to share intent streams.
  ///
  /// Must be called after [runApp] so the router's navigator key is attached.
  Future<void> init() async {
    // Files shared while the app is already running.
    _sub = ReceiveSharingIntent.instance.getMediaStream().listen(
      _handleFiles,
      onError: (_) {},
    );

    // Files shared that cold-launched the app.
    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((files) {
          if (files.isNotEmpty) {
            _handleFiles(files);
            ReceiveSharingIntent.instance.reset();
          }
        })
        .catchError((_) {});
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  Future<void> _handleFiles(List<SharedMediaFile> files) async {
    if (_busy) return;
    _busy = true;
    try {
      if (files.isEmpty) return;
      final file = files.first;
      final mime = file.mimeType?.toLowerCase() ?? '';
      final ext = file.path.split('.').last.toLowerCase();

      if (mime.startsWith('image/') ||
          ext == 'jpg' ||
          ext == 'jpeg' ||
          ext == 'png') {
        await _handleReceiptImage(file.path);
      } else if (mime == 'text/csv' || ext == 'csv') {
        await _handleCsv(file.path);
      } else if (mime == 'text/plain' || ext == 'txt') {
        await _handleAmazonText(file.path);
      }
      // application/pdf is acknowledged but no parser exists yet — silently ignored.
    } finally {
      _busy = false;
    }
  }

  Future<void> _handleReceiptImage(String path) async {
    try {
      final items = await ocrService.parseReceipt(File(path));
      if (items.isEmpty) return;
      final reviewItems = items
          .map((p) => ImportReviewItem(parsed: p))
          .toList();
      router.pushNamed('importReview', extra: reviewItems);
    } catch (_) {}
  }

  Future<void> _handleCsv(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final content = utf8.decode(bytes);
      final autoDetected = bankParser.detectColumns(content);
      router.pushNamed(
        'bankColumns',
        extra: {
          'csvContent': content,
          'autoDetected': autoDetected,
          'truncated': content.split('\n').length > 501,
        },
      );
    } catch (_) {}
  }

  Future<void> _handleAmazonText(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final content = utf8.decode(bytes);
      final parsed = amazonService.parseFromText(content);
      if (parsed.isEmpty) return;
      final reviewItems = parsed
          .map((p) => ImportReviewItem(parsed: p))
          .toList();
      router.pushNamed('importReview', extra: reviewItems);
    } catch (_) {}
  }
}
