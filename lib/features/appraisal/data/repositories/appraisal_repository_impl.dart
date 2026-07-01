import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../services/database/database.dart' as db_pkg;
import '../../domain/entities/appraisal.dart';
import '../../domain/entities/appraisal_source.dart';
import '../../domain/repositories/appraisal_repository.dart';

const _uuid = Uuid();

/// Drift-backed implementation of [AppraisalRepository].
class AppraisalRepositoryImpl implements AppraisalRepository {
  final db_pkg.AppDatabase _db;
  AppraisalRepositoryImpl(this._db);

  @override
  Stream<List<Appraisal>> watchForItem(String itemId) => _db.appraisalDao
      .watchForItem(itemId)
      .map((rows) => rows.map(_mapRow).toList(growable: false));

  @override
  Future<Appraisal?> getLatestByItemAndMode(
    String itemId,
    AppraisalMode mode,
  ) async {
    final row = await _db.appraisalDao.getLatestByItemAndMode(
      itemId,
      mode.wire,
    );
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<Appraisal?> getLatestByCacheKey(
    String itemModelKey,
    AppraisalMode mode,
    String countryCode,
  ) async {
    final row = await _db.appraisalDao.getLatestByCacheKey(
      itemModelKey,
      mode.wire,
      countryCode,
    );
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<Result<Appraisal>> save(Appraisal a) async {
    try {
      final id = a.id.isEmpty ? _uuid.v4() : a.id;
      // Money is integer cents by construction — the rounding law is now
      // structural, not a call the write path can forget.
      final companion = db_pkg.AppraisalsCompanion.insert(
        id: id,
        itemId: a.itemId,
        mode: a.mode.wire,
        valueCents: a.valueCents,
        itemModelKey: a.itemModelKey,
        queriedAt: a.queriedAt.millisecondsSinceEpoch,
        expiresAt: a.expiresAt.millisecondsSinceEpoch,
        currency: Value(a.currency),
        confidence: Value(a.confidence),
        sourceUrls: Value(_encodeSources(a.sources)),
        countryCode: Value(a.countryCode),
      );
      await _db.appraisalDao.insertAppraisal(companion);
      // The returned entity must match what was written, not the raw input.
      return Success(a.copyWith(id: id));
    } catch (e) {
      return Err(DatabaseFailure('Failed to save appraisal: $e'));
    }
  }

  @override
  Future<Result<void>> applyToItem(Appraisal a) async {
    try {
      final cents = a.valueCents;
      final isResale = a.mode == AppraisalMode.resale;

      // Sparse companion — only the targeted value column and modifiedAt
      // change; going through itemDao directly (not ItemRepository.updateItem)
      // keeps its automatic 'manual' price-history write out of this path.
      final updated = await _db.itemDao.updateItem(
        db_pkg.ItemsCompanion(
          id: Value(a.itemId),
          currentValueCents: isResale ? Value(cents) : const Value.absent(),
          replacementCostCents: isResale ? const Value.absent() : Value(cents),
          modifiedAt: Value(DateTime.now()),
        ),
      );
      if (!updated) {
        return Err(DatabaseFailure('Item ${a.itemId} not found'));
      }

      // currentValueCents changes leave a price-history trail so the chart shows
      // where the number came from.
      if (isResale) {
        await _db.priceHistoryDao.insertPriceEntry(
          db_pkg.PriceHistoryEntriesCompanion.insert(
            id: _uuid.v4(),
            itemId: a.itemId,
            priceCents: cents,
            source: 'llm_estimate',
            recordedAt: DateTime.now(),
          ),
        );
      }
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure('Failed to apply appraisal: $e'));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _db.appraisalDao.softDelete(id);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure('Failed to delete appraisal: $e'));
    }
  }

  // ── Mapping helpers ────────────────────────────────────────────────────────

  Appraisal _mapRow(db_pkg.Appraisal row) => Appraisal(
    id: row.id,
    itemId: row.itemId,
    mode: AppraisalMode.fromWire(row.mode),
    valueCents: row.valueCents,
    currency: row.currency,
    confidence: row.confidence,
    sources: _decodeSources(row.sourceUrls),
    itemModelKey: row.itemModelKey,
    countryCode: row.countryCode,
    queriedAt: DateTime.fromMillisecondsSinceEpoch(row.queriedAt),
    expiresAt: DateTime.fromMillisecondsSinceEpoch(row.expiresAt),
  );

  String _encodeSources(List<AppraisalSource> srcs) =>
      jsonEncode(srcs.map((s) => s.toJson()).toList());

  List<AppraisalSource> _decodeSources(String raw) {
    if (raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(AppraisalSource.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}
