import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/import/domain/parsed_import_item.dart';
import 'package:still_life/services/import/import_receipt_ocr_service.dart';
import 'package:still_life/services/ml/analysis_provider.dart';
import 'package:still_life/services/ml/ollama_provider.dart'
    show AnalysisException;
import 'package:still_life/services/ml/provider_manager.dart';

// Test subclass that bypasses hardware MLKit.
class _TestOcrService extends ImportReceiptOcrService {
  final String fakeOcrText;

  _TestOcrService({
    required this.fakeOcrText,
    super.providerManager,
    super.resolveProviderManager,
  });

  @override
  Future<String> extractOcrText(String imagePath) async => fakeOcrText;
}

class _ThrowingOcrService extends ImportReceiptOcrService {
  @override
  Future<String> extractOcrText(String imagePath) async =>
      throw UnsupportedError('Receipt OCR is not available on web.');
}

/// Fake text-capable tier: replies with a canned string, records the
/// prompt, or throws when [reply] is null.
class _FakeTextProvider extends AnalysisProvider {
  final String? reply;
  final bool available;
  String? lastPrompt;

  _FakeTextProvider({this.reply, this.available = true});

  @override
  String get name => 'Fake';

  @override
  AnalysisTier get tier => AnalysisTier.cloudApi;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<String> completeText(String prompt, {int maxTokens = 1000}) async {
    lastPrompt = prompt;
    if (reply == null) throw const AnalysisException('LLM down');
    return reply!;
  }

  @override
  Future<AnalysisResult> analyzeImage({
    required Uint8List imageBytes,
    Uint8List? contextFrame,
    String? existingLabel,
  }) => throw UnimplementedError();

  @override
  Future<List<AnalysisResult>> analyzeImageMulti(
    Uint8List imageBytes, {
    AnalysisContext? context,
  }) => throw UnimplementedError();

  @override
  Future<AnalysisResult> analyzeText(
    String prompt, {
    AnalysisContext? context,
  }) => throw UnimplementedError();
}

ProviderManager _manager(AnalysisProvider provider) =>
    ProviderManager(providers: [provider]);

const _groceryOcr = '''
KROGER
07/02/2026
Coffee Beans  \$12.99
Dish Soap     \$3.49
Total         \$16.48
''';

void main() {
  group('deterministic path (no AI configured)', () {
    test('extracts items, store, and date from OCR text via regex', () async {
      final service = _TestOcrService(fakeOcrText: _groceryOcr);
      final result = await service.parseReceipt('dummy.jpg');

      expect(result.engine, ReceiptParseEngine.deterministic);
      expect(result.storeName, 'KROGER');
      expect(result.purchaseDate, DateTime(2026, 7, 2));
      expect(result.totalAmount, 16.48);
      expect(result.ocrText, _groceryOcr);
      expect(
        result.items.any((i) => i.name.contains('Coffee') && i.price == 12.99),
        isTrue,
      );
      expect(
        result.items.any((i) => i.name.contains('Dish') && i.price == 3.49),
        isTrue,
      );
    });

    test('every item carries the receipt store/date metadata', () async {
      final service = _TestOcrService(fakeOcrText: _groceryOcr);
      final result = await service.parseReceipt('dummy.jpg');

      expect(result.items, isNotEmpty);
      for (final item in result.items) {
        expect(item.storeName, 'KROGER');
        expect(item.purchaseDate, DateTime(2026, 7, 2));
        expect(item.source, ImportSource.receipt);
      }
    });

    test('skips Total/Subtotal/Tax lines', () async {
      final service = _TestOcrService(
        fakeOcrText:
            'Coffee  \$5.00\nTotal   \$5.00\n'
            'Tax     \$0.40\nSubtotal \$5.00\n',
      );
      final result = await service.parseReceipt('dummy.jpg');
      expect(
        result.items.map((i) => i.name.toLowerCase()),
        everyElement(isNot(startsWith('total'))),
      );
      expect(
        result.items.map((i) => i.name.toLowerCase()),
        everyElement(isNot(startsWith('tax'))),
      );
      expect(
        result.items.map((i) => i.name.toLowerCase()),
        everyElement(isNot(startsWith('subtotal'))),
      );
    });

    test('returns empty items for empty OCR text', () async {
      final service = _TestOcrService(fakeOcrText: '');
      final result = await service.parseReceipt('dummy.jpg');
      expect(result.items, isEmpty);
    });

    test('returns empty items when no price lines found', () async {
      final service = _TestOcrService(
        fakeOcrText: 'STORE NAME\nThank you for shopping\n',
      );
      final result = await service.parseReceipt('dummy.jpg');
      expect(result.items, isEmpty);
    });

    test('swallows an OCR backend failure (web) as no text', () async {
      final service = _ThrowingOcrService();
      final result = await service.parseReceipt('dummy.jpg');
      expect(result.items, isEmpty);
      expect(result.engine, ReceiptParseEngine.deterministic);
    });

    test('extractOcrText is overridable (@visibleForTesting)', () async {
      final service = _TestOcrService(fakeOcrText: 'test text');
      expect(await service.extractOcrText('dummy.jpg'), 'test text');
    });
  });

  group('LLM structuring stage', () {
    test('sends the RAW OCR text to the best available tier', () async {
      final provider = _FakeTextProvider(
        reply:
            '{"storeName":"Kroger","items":[{"name":"Coffee Beans",'
            '"price":12.99,"brand":null,"model":null}]}',
      );
      final service = _TestOcrService(
        fakeOcrText: _groceryOcr,
        providerManager: _manager(provider),
      );
      await service.parseReceipt('dummy.jpg');

      expect(provider.lastPrompt, isNotNull);
      expect(
        provider.lastPrompt,
        contains('<receipt_text>'),
        reason: 'OCR text must ride inside the data-only tag boundary',
      );
      expect(
        provider.lastPrompt,
        contains('Coffee Beans  \$12.99'),
        reason: 'the raw OCR text must reach the model',
      );
      expect(provider.lastPrompt!.toLowerCase(), contains('json'));
    });

    test('LLM success yields structured items WITH brand/model and '
        'receipt metadata', () async {
      final provider = _FakeTextProvider(
        reply:
            '{"storeName":"Best Buy","purchaseDate":"2024-04-10",'
            '"totalAmount":861.82,"items":['
            '{"name":"55 inch TV","price":499.99,"brand":"Samsung",'
            '"model":"UN55TU7000"}]}',
      );
      final service = _TestOcrService(
        fakeOcrText: 'BEST BUY\nSAMSUNG UN55TU7000 55" TV 499.99',
        providerManager: _manager(provider),
      );
      final result = await service.parseReceipt('dummy.jpg');

      expect(result.engine, ReceiptParseEngine.llm);
      expect(result.engineLabel, contains('Cloud API'));
      expect(result.storeName, 'Best Buy');
      expect(result.purchaseDate, DateTime(2024, 4, 10));
      expect(result.totalAmount, 861.82);
      final item = result.items.single;
      expect(item.name, '55 inch TV');
      expect(item.brand, 'Samsung');
      expect(item.model, 'UN55TU7000');
      expect(item.price, 499.99);
      expect(item.storeName, 'Best Buy');
      expect(item.purchaseDate, DateTime(2024, 4, 10));
      expect(item.source, ImportSource.receipt);
    });

    test('malformed LLM output falls back to the deterministic result, '
        'byte-for-byte', () async {
      final withBrokenLlm = _TestOcrService(
        fakeOcrText: _groceryOcr,
        providerManager: _manager(_FakeTextProvider(reply: 'not json')),
      );
      final withoutAi = _TestOcrService(fakeOcrText: _groceryOcr);

      final fallback = await withBrokenLlm.parseReceipt('dummy.jpg');
      final deterministic = await withoutAi.parseReceipt('dummy.jpg');

      expect(fallback.engine, ReceiptParseEngine.deterministic);
      _expectSameResult(fallback, deterministic);
    });

    test('an LLM transport error falls back to the deterministic result, '
        'byte-for-byte', () async {
      final withDeadLlm = _TestOcrService(
        fakeOcrText: _groceryOcr,
        providerManager: _manager(_FakeTextProvider(reply: null)),
      );
      final withoutAi = _TestOcrService(fakeOcrText: _groceryOcr);

      final fallback = await withDeadLlm.parseReceipt('dummy.jpg');
      final deterministic = await withoutAi.parseReceipt('dummy.jpg');

      expect(fallback.engine, ReceiptParseEngine.deterministic);
      _expectSameResult(fallback, deterministic);
    });

    test('no available tier falls back to the deterministic result, '
        'byte-for-byte', () async {
      final withUnavailable = _TestOcrService(
        fakeOcrText: _groceryOcr,
        providerManager: _manager(
          _FakeTextProvider(reply: '{"x":1}', available: false),
        ),
      );
      final withoutAi = _TestOcrService(fakeOcrText: _groceryOcr);

      final fallback = await withUnavailable.parseReceipt('dummy.jpg');
      final deterministic = await withoutAi.parseReceipt('dummy.jpg');

      expect(fallback.engine, ReceiptParseEngine.deterministic);
      _expectSameResult(fallback, deterministic);
    });

    test('empty OCR text never bothers the LLM', () async {
      final provider = _FakeTextProvider(reply: '{"items":[{"name":"x"}]}');
      final service = _TestOcrService(
        fakeOcrText: '',
        providerManager: _manager(provider),
      );
      final result = await service.parseReceipt('dummy.jpg');
      expect(
        provider.lastPrompt,
        isNull,
        reason: 'nothing to structure — no tokens spent',
      );
      expect(result.items, isEmpty);
    });

    test('deterministic engine label says pattern, not AI', () async {
      final service = _TestOcrService(fakeOcrText: _groceryOcr);
      final result = await service.parseReceipt('dummy.jpg');
      expect(result.engineLabel.toLowerCase(), isNot(contains('ai')));
    });
  });
  group('live provider-manager resolution (share-intent path)', () {
    test('resolveProviderManager is consulted on EVERY parse, so a manager '
        'rebuilt after settings load is picked up', () async {
      // Cold start: settings still loading, no manager yet.
      ProviderManager? current;
      final service = _TestOcrService(
        fakeOcrText: _groceryOcr,
        resolveProviderManager: () => current,
      );

      final first = await service.parseReceipt('dummy.jpg');
      expect(
        first.engine,
        ReceiptParseEngine.deterministic,
        reason: 'no manager resolved yet — deterministic fallback',
      );

      // Settings loaded; the provider container rebuilt the manager.
      final provider = _FakeTextProvider(
        reply:
            '{"storeName":"KROGER","purchaseDate":"2026-07-02",'
            '"totalAmount":16.48,"items":[{"name":"Coffee Beans",'
            '"price":12.99}]}',
      );
      current = _manager(provider);

      final second = await service.parseReceipt('dummy.jpg');
      expect(
        second.engine,
        ReceiptParseEngine.llm,
        reason:
            'the handler must see the CURRENT manager, not a '
            'cold-start snapshot with an empty cloud key',
      );
    });
  });
}

/// Field-by-field equality of two parse results — the fallback contract is
/// that a failed LLM stage leaves NO trace on the output.
void _expectSameResult(ReceiptImportResult a, ReceiptImportResult b) {
  expect(a.storeName, b.storeName);
  expect(a.purchaseDate, b.purchaseDate);
  expect(a.totalAmount, b.totalAmount);
  expect(a.ocrText, b.ocrText);
  expect(a.engine, b.engine);
  expect(a.engineLabel, b.engineLabel);
  expect(a.items.length, b.items.length);
  for (var i = 0; i < a.items.length; i++) {
    expect(a.items[i].name, b.items[i].name);
    expect(a.items[i].price, b.items[i].price);
    expect(a.items[i].purchaseDate, b.items[i].purchaseDate);
    expect(a.items[i].storeName, b.items[i].storeName);
    expect(a.items[i].brand, b.items[i].brand);
    expect(a.items[i].model, b.items[i].model);
    expect(a.items[i].asin, b.items[i].asin);
    expect(a.items[i].categoryHint, b.items[i].categoryHint);
    expect(a.items[i].source, b.items[i].source);
  }
}
