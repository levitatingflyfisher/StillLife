import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../features/import/domain/parsed_import_item.dart';
import '../ml/analysis_provider.dart' show AnalysisCapability;
import '../ml/provider_manager.dart';
import 'receipt_ocr_backend/receipt_ocr_backend.dart' as ocr_backend;
import 'receipt_parser.dart';
import 'receipt_structuring_parser.dart';

/// Which engine produced a [ReceiptImportResult] — surfaced in the review
/// UI so the user can tell an AI-structured parse from pattern matching.
enum ReceiptParseEngine { llm, deterministic }

/// Everything a receipt parse yields: the items for review plus the
/// receipt-level metadata (store, date, total, raw OCR text) that the
/// review screen persists as one Receipts row.
class ReceiptImportResult {
  final List<ParsedImportItem> items;
  final String? storeName;
  final DateTime? purchaseDate;
  final double? totalAmount;
  final String ocrText;
  final ReceiptParseEngine engine;

  /// Human-readable engine name, e.g. `AI-structured (Cloud API)` or
  /// `Pattern-matched`.
  final String engineLabel;

  const ReceiptImportResult({
    required this.items,
    this.storeName,
    this.purchaseDate,
    this.totalAmount,
    required this.ocrText,
    required this.engine,
    required this.engineLabel,
  });
}

/// Three-stage receipt OCR pipeline:
/// 1. MLKit text recognition (`extractOcrText`) — overridable in tests, and
///    unavailable on web where it simply yields no text
/// 2. LLM structuring via [ProviderManager]: the raw OCR text goes to the
///    best available tier, which returns store/date/total plus line items
///    with brand/model when printed
/// 3. Deterministic fallback: any LLM failure (or no AI configured) yields
///    exactly the consolidated [ReceiptParser]'s result
class ImportReceiptOcrService {
  final ProviderManager? Function() _resolveProviderManager;

  /// Pass a fixed [providerManager] (the Riverpod-watched path, which
  /// rebuilds the whole service on config changes) or a
  /// [resolveProviderManager] callback for long-lived holders like the
  /// share-intent handler: it is consulted on EVERY parse, so a manager
  /// rebuilt after the async settings providers load (cloud key, Ollama
  /// host, tier priority) is picked up instead of a cold-start snapshot
  /// with an empty cloud key being kept forever.
  ImportReceiptOcrService({
    ProviderManager? providerManager,
    ProviderManager? Function()? resolveProviderManager,
  }) : _resolveProviderManager =
           resolveProviderManager ?? (() => providerManager);

  /// The manager the next parse will use — resolved live.
  ProviderManager? get providerManager => _resolveProviderManager();

  /// Extracts raw OCR text from the image at [imagePath] using the platform
  /// OCR backend (MLKit on Android/iOS; throws UnsupportedError on web).
  ///
  /// Override in tests via a subclass to bypass hardware dependency.
  @visibleForTesting
  Future<String> extractOcrText(String imagePath) =>
      ocr_backend.runReceiptOcr(imagePath);

  /// Parses the receipt image at [imagePath]. Returns a result with empty
  /// items when OCR is unavailable (e.g. on web) or finds nothing.
  Future<ReceiptImportResult> parseReceipt(String imagePath) async {
    // Stage 1: OCR
    String ocrText;
    try {
      ocrText = await extractOcrText(imagePath);
    } catch (_) {
      ocrText = '';
    }

    // Stage 2: LLM structuring. Failure of any kind falls through to the
    // deterministic stage — the LLM may only ever add, never break.
    if (ocrText.trim().isNotEmpty && providerManager != null) {
      final llmResult = await _tryLlmStructuring(ocrText);
      if (llmResult != null) return llmResult;
    }

    // Stage 3: deterministic extraction
    final parsed = const ReceiptParser().parse(ocrText);
    return ReceiptImportResult(
      items: [
        for (final line in parsed.lineItems)
          ParsedImportItem(
            name: line.name,
            price: line.price,
            purchaseDate: parsed.purchaseDate,
            storeName: parsed.storeName,
            source: ImportSource.receipt,
          ),
      ],
      storeName: parsed.storeName,
      purchaseDate: parsed.purchaseDate,
      totalAmount: parsed.totalAmount,
      ocrText: ocrText,
      engine: ReceiptParseEngine.deterministic,
      engineLabel: 'Pattern-matched',
    );
  }

  /// Sends the raw OCR text to the best available tier for structuring.
  /// Returns `null` on ANY failure — no tier available, transport error,
  /// or unparseable model output — so the caller falls back.
  Future<ReceiptImportResult?> _tryLlmStructuring(String ocrText) async {
    try {
      final manager = providerManager;
      if (manager == null) return null;
      final provider = await manager.getBestAvailable(
        AnalysisCapability.text,
      );
      if (provider == null) return null;

      final raw = await provider.completeText(
        buildReceiptStructuringPrompt(ocrText),
        maxTokens: 2000,
      );
      final structured = parseReceiptStructuringResponse(raw);
      if (structured == null) return null;

      return ReceiptImportResult(
        items: [
          for (final item in structured.items)
            ParsedImportItem(
              name: item.name,
              price: item.price,
              purchaseDate: structured.purchaseDate,
              storeName: structured.storeName,
              brand: item.brand,
              model: item.model,
              source: ImportSource.receipt,
            ),
        ],
        storeName: structured.storeName,
        purchaseDate: structured.purchaseDate,
        totalAmount: structured.totalAmount,
        ocrText: ocrText,
        engine: ReceiptParseEngine.llm,
        engineLabel: 'AI-structured (${provider.tier.label})',
      );
    } catch (_) {
      return null;
    }
  }
}
