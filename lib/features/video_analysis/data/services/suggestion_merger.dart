import 'package:still_life/services/ml/analysis_provider.dart';

/// One VLM finding tied to the frame it was spotted in — provenance the
/// review screen needs so each saved item can carry its source frame.
class FrameSuggestion {
  final int frameIndex;
  final AnalysisResult result;

  const FrameSuggestion({required this.frameIndex, required this.result});
}

/// Collapses per-frame VLM findings into one suggestion per real item.
///
/// A walkthrough sees the same couch in a dozen frames; the user should
/// review it once. Two findings are the same item when:
/// - their normalized names match (case-insensitive, whitespace collapsed), OR
/// - both carry the same brand AND model (case-insensitive).
///
/// The higher-confidence copy wins (its frame provenance included); ties
/// keep the first-seen copy. Output preserves first-seen order. Findings
/// with no usable name and no brand+model are passed through unmerged —
/// better a duplicate the user deletes than a silently swallowed item.
class SuggestionMerger {
  const SuggestionMerger();

  List<FrameSuggestion> merge(List<FrameSuggestion> raw) {
    final kept = <FrameSuggestion>[];

    for (final candidate in raw) {
      final matchIndex = kept.indexWhere((k) => _sameItem(k, candidate));
      if (matchIndex == -1) {
        kept.add(candidate);
      } else if (candidate.result.confidence >
          kept[matchIndex].result.confidence) {
        kept[matchIndex] = candidate;
      }
    }

    return kept;
  }

  static bool _sameItem(FrameSuggestion a, FrameSuggestion b) {
    final nameA = _normalize(a.result.itemName);
    final nameB = _normalize(b.result.itemName);
    if (nameA.isNotEmpty && nameA == nameB) return true;

    final brandA = _normalize(a.result.brand ?? '');
    final brandB = _normalize(b.result.brand ?? '');
    final modelA = _normalize(a.result.model ?? '');
    final modelB = _normalize(b.result.model ?? '');
    return brandA.isNotEmpty &&
        modelA.isNotEmpty &&
        brandA == brandB &&
        modelA == modelB;
  }

  static String _normalize(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
