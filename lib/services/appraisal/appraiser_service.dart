import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../core/errors/failures.dart';
import '../../core/errors/result.dart';
import '../../features/appraisal/domain/entities/appraisal.dart';
import '../../features/appraisal/domain/entities/appraisal_source.dart';
import '../../features/appraisal/domain/repositories/appraisal_repository.dart';
import '../../features/inventory/domain/entities/item.dart';
import 'appraiser_prompt.dart';

/// Thin abstraction over "send a Messages API body and get JSON back".
/// Implemented by [MessagesTransportAdapter] (Task 7) in production; tests
/// use an in-memory fake.
abstract class MessagesTransport {
  Future<Result<Map<String, dynamic>>> send(Map<String, dynamic> body);
}

/// Orchestrates: cache lookup → LLM call → parse → persist.
class AppraiserService {
  final AppraisalRepository _repo;
  final MessagesTransport _transport;
  final Uuid _uuid;
  final String Function() _countryCode;
  final DateTime Function() _now;

  AppraiserService({
    required AppraisalRepository repo,
    required MessagesTransport transport,
    required String Function() countryCode,
    Uuid? uuid,
    DateTime Function()? now,
  }) : _repo = repo,
       _transport = transport,
       _countryCode = countryCode,
       _uuid = uuid ?? const Uuid(),
       _now = now ?? DateTime.now;

  Future<Result<Appraisal>> appraise(
    Item item,
    AppraisalMode mode, {
    bool forceRefresh = false,
  }) async {
    final country = _countryCode();
    final key = AppraiserPrompt.itemModelKey(item);

    if (!forceRefresh) {
      final cached = await _repo.getLatestByCacheKey(key, mode, country);
      if (cached != null && cached.isFresh) {
        if (cached.itemId == item.id) return Success(cached);
        // Cross-item cache reuse: clone for our item, but compute a fresh
        // expiresAt so a long-lived cache entry doesn't get inherited
        // arbitrarily close to its own expiry.
        final ttl = mode == AppraisalMode.replaceNew
            ? const Duration(days: 7)
            : const Duration(days: 30);
        final now = _now();
        final cloned = Appraisal(
          id: _uuid.v4(),
          itemId: item.id,
          mode: mode,
          value: cached.value,
          currency: cached.currency,
          confidence: cached.confidence,
          sources: cached.sources,
          itemModelKey: key,
          countryCode: country,
          queriedAt: now,
          expiresAt: now.add(ttl),
        );
        return _repo.save(cloned);
      }
    }

    final body = AppraiserPrompt.buildRequest(
      item: item,
      mode: mode,
      countryCode: country,
    );
    final res = await _transport.send(body);
    return res.when(
      success: (payload) async {
        final parsed = _parseResponse(payload);
        if (parsed == null) {
          return const Err<Appraisal>(
            ValidationFailure('Could not parse appraiser response'),
          );
        }
        final ttl = mode == AppraisalMode.replaceNew
            ? const Duration(days: 7)
            : const Duration(days: 30);
        final now = _now();
        final appraisal = Appraisal(
          id: _uuid.v4(),
          itemId: item.id,
          mode: mode,
          value: parsed['value'] as double,
          currency: parsed['currency'] as String,
          confidence: parsed['confidence'] as double,
          sources: (parsed['sources'] as List).cast<AppraisalSource>(),
          itemModelKey: key,
          countryCode: country,
          queriedAt: now,
          expiresAt: now.add(ttl),
        );
        return _repo.save(appraisal);
      },
      failure: (f) => Err<Appraisal>(f),
    );
  }

  /// Parses an Anthropic Messages response `content` array into our JSON shape.
  Map<String, dynamic>? _parseResponse(Map<String, dynamic> payload) {
    final content = payload['content'] as List?;
    if (content == null) return null;
    Map<String, dynamic>? textBlock;
    for (final block in content) {
      if (block is Map<String, dynamic> && block['type'] == 'text') {
        textBlock = block;
        break;
      }
    }
    if (textBlock == null) return null;
    final raw = (textBlock['text'] as String?)?.trim();
    if (raw == null || raw.isEmpty) return null;
    // Extract the first JSON object we can find, tolerating stray prose.
    final match = RegExp(r'\{[\s\S]*\}').firstMatch(raw);
    final payloadText = match?.group(0) ?? raw;
    try {
      final j = jsonDecode(payloadText) as Map<String, dynamic>;
      final srcsRaw = j['sources'] as List? ?? const [];
      // Filter out sources with empty url after parsing — a malformed LLM
      // response that omits the url field shouldn't propagate citation-less
      // entries through the UI.
      final srcs = srcsRaw
          .whereType<Map<String, dynamic>>()
          .map(AppraisalSource.fromJson)
          .where((s) => s.url.isNotEmpty)
          .toList(growable: false);
      return {
        'value': (j['value'] as num?)?.toDouble() ?? 0.0,
        'currency': j['currency'] as String? ?? 'USD',
        'confidence': (j['confidence'] as num?)?.toDouble() ?? 0.0,
        'sources': srcs,
      };
    } catch (_) {
      return null;
    }
  }
}
