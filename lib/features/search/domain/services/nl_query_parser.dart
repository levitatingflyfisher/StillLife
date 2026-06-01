import '../../../inventory/domain/entities/category.dart';
import '../../../inventory/domain/repositories/item_repository.dart';
import '../../../locations/domain/entities/room.dart';
import '../../../locations/domain/entities/storage_container.dart';

/// The result of parsing a natural-language query string.
class ParseResult {
  final ItemQuery query;
  final bool hasStructuredFilters;
  final String residualText;
  final bool isWhereIs;
  final bool needsLlmFallback;

  const ParseResult({
    required this.query,
    required this.hasStructuredFilters,
    required this.residualText,
    required this.isWhereIs,
    required this.needsLlmFallback,
  });
}

/// Pure-Dart, synchronous, regex-based natural-language → [ItemQuery] parser.
///
/// Receives current room/category/container lists at construction time so it
/// can do name-matching without any async DB calls.
class NlQueryParser {
  final List<Room> rooms;
  final List<Category> categories;
  final List<StorageContainer> containers;

  const NlQueryParser({
    required this.rooms,
    required this.categories,
    required this.containers,
  });

  // ---------------------------------------------------------------------------
  // Compiled patterns (static, built once)
  // ---------------------------------------------------------------------------

  static final _whereIsRe = RegExp(
    r"^(where\s+is|find\s+my|where'?s)\s+(?:my|the|a|an)?\s*",
    caseSensitive: false,
  );

  static final _overRe = RegExp(
    r'\b(?:over|more\s+than|above)\s+\$?(\d+(?:\.\d+)?)\b',
    caseSensitive: false,
  );

  static final _underRe = RegExp(
    r'\b(?:under|less\s+than|below)\s+\$?(\d+(?:\.\d+)?)\b',
    caseSensitive: false,
  );

  static final _expensiveRe = RegExp(
    r'\b(expensive|valuable)\b',
    caseSensitive: false,
  );

  static final _cheapRe = RegExp(
    r'\b(cheap|inexpensive)\b',
    caseSensitive: false,
  );

  static final _recentRe = RegExp(
    r'\b(recent|recently|last\s+month)\b',
    caseSensitive: false,
  );

  static final _thisYearRe = RegExp(r'\bthis\s+year\b', caseSensitive: false);

  static final _withPhotoRe = RegExp(
    r'\b(with\s+photo|has\s+photo)\b',
    caseSensitive: false,
  );

  static final _withReceiptRe = RegExp(
    r'\b(with\s+receipt|has\s+receipt)\b',
    caseSensitive: false,
  );

  static final _withBarcodeRe = RegExp(
    r'\b(with\s+barcode|has\s+barcode)\b',
    caseSensitive: false,
  );

  static final _mostValuableRe = RegExp(
    r'\b(most\s+valuable|by\s+value)\b',
    caseSensitive: false,
  );

  static final _newestRe = RegExp(
    r'\b(newest|recently\s+added)\b',
    caseSensitive: false,
  );

  /// Common stop words that add no search meaning and should be stripped from
  /// the residual text passed to the search text field / LLM.
  static final _stopWords = RegExp(
    r'\b(the|my|a|an|some|all|items?|stuff|things?|in|with|has|have|that|are|is|added|purchases?)\b',
    caseSensitive: false,
  );

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  ParseResult parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const ParseResult(
        query: ItemQuery(),
        hasStructuredFilters: false,
        residualText: '',
        isWhereIs: false,
        needsLlmFallback: false,
      );
    }

    var text = trimmed;

    // ---- where-is prefix ----
    final isWhereIs = _whereIsRe.hasMatch(text);
    if (isWhereIs) {
      text = text.replaceFirst(_whereIsRe, '');
    }

    String? roomId;
    String? categoryId;
    String? containerId;
    double? minValue;
    double? maxValue;
    DateTime? addedAfter;
    bool? hasPhoto;
    bool? hasReceipt;
    bool? hasBarcode;
    var sortBy = ItemSortField.name;
    var ascending = true;

    // ---- sort keywords ----
    if (_mostValuableRe.hasMatch(text)) {
      sortBy = ItemSortField.currentValue;
      ascending = false;
      text = text.replaceAll(_mostValuableRe, '');
    } else if (_newestRe.hasMatch(text)) {
      sortBy = ItemSortField.createdAt;
      ascending = false;
      text = text.replaceAll(_newestRe, '');
    }

    // ---- price range ----
    final overMatch = _overRe.firstMatch(text);
    if (overMatch != null) {
      minValue = double.tryParse(overMatch.group(1)!);
      text = text.replaceAll(_overRe, '');
    }
    final underMatch = _underRe.firstMatch(text);
    if (underMatch != null) {
      maxValue = double.tryParse(underMatch.group(1)!);
      text = text.replaceAll(_underRe, '');
    }
    if (_expensiveRe.hasMatch(text)) {
      minValue ??= 500.0;
      text = text.replaceAll(_expensiveRe, '');
    }
    if (_cheapRe.hasMatch(text)) {
      maxValue ??= 100.0;
      text = text.replaceAll(_cheapRe, '');
    }

    // ---- date keywords ----
    if (_recentRe.hasMatch(text)) {
      addedAfter = DateTime.now().subtract(const Duration(days: 30));
      text = text.replaceAll(_recentRe, '');
    } else if (_thisYearRe.hasMatch(text)) {
      final now = DateTime.now();
      addedAfter = DateTime(now.year);
      text = text.replaceAll(_thisYearRe, '');
    }

    // ---- presence flags ----
    if (_withPhotoRe.hasMatch(text)) {
      hasPhoto = true;
      text = text.replaceAll(_withPhotoRe, '');
    }
    if (_withReceiptRe.hasMatch(text)) {
      hasReceipt = true;
      text = text.replaceAll(_withReceiptRe, '');
    }
    if (_withBarcodeRe.hasMatch(text)) {
      hasBarcode = true;
      text = text.replaceAll(_withBarcodeRe, '');
    }

    // ---- room name matching ----
    // Work on a version of text that has "in the/in my/in" prepositions stripped
    // so we can match bare room names (e.g. "garage" from "in the garage").
    final strippedForRoom = text
        .replaceAll(
          RegExp(r'\b(in\s+the|in\s+my|in)\s+', caseSensitive: false),
          ' ',
        )
        .toLowerCase();

    for (final room in rooms) {
      final nameLower = room.name.toLowerCase();
      final roomPattern = RegExp(
        r'\b' + RegExp.escape(nameLower) + r'\b',
        caseSensitive: false,
      );
      if (roomPattern.hasMatch(strippedForRoom)) {
        roomId = room.id;
        // Remove "in [the/my] <RoomName>" or plain "<RoomName>" from text.
        text = text.replaceAll(
          RegExp(
            r'\b(in\s+the\s+|in\s+my\s+|in\s+)?' + RegExp.escape(room.name),
            caseSensitive: false,
          ),
          ' ',
        );
        break;
      }
    }

    // ---- category name matching ----
    for (final cat in categories) {
      final catPattern = RegExp(
        r'\b' + RegExp.escape(cat.name) + r'\b',
        caseSensitive: false,
      );
      if (catPattern.hasMatch(text)) {
        categoryId = cat.id;
        text = text.replaceAll(
          RegExp(RegExp.escape(cat.name), caseSensitive: false),
          ' ',
        );
        break;
      }
    }

    // ---- container name matching ----
    for (final cont in containers) {
      final contPattern = RegExp(
        r'\b' + RegExp.escape(cont.name) + r'\b',
        caseSensitive: false,
      );
      if (contPattern.hasMatch(text)) {
        containerId = cont.id;
        text = text.replaceAll(
          RegExp(RegExp.escape(cont.name), caseSensitive: false),
          ' ',
        );
        break;
      }
    }

    // ---- clean residual ----
    final residual = text
        .replaceAll(_stopWords, ' ')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();

    // ---- assemble flags ----
    final hasStructured =
        roomId != null ||
        categoryId != null ||
        containerId != null ||
        minValue != null ||
        maxValue != null ||
        addedAfter != null ||
        hasPhoto != null ||
        hasReceipt != null ||
        hasBarcode != null ||
        sortBy != ItemSortField.name;

    // Suggest LLM fallback only when there is leftover text with no structured
    // filters that could provide context (more than 3 chars to avoid single
    // words that are simply stop words or abbreviations).
    final needsLlmFallback = !hasStructured && residual.length > 3;

    return ParseResult(
      query: ItemQuery(
        searchText: residual.isEmpty ? null : residual,
        roomId: roomId,
        categoryId: categoryId,
        containerId: containerId,
        minValue: minValue,
        maxValue: maxValue,
        addedAfter: addedAfter,
        hasPhoto: hasPhoto,
        hasReceipt: hasReceipt,
        hasBarcode: hasBarcode,
        sortBy: sortBy,
        ascending: ascending,
      ),
      hasStructuredFilters: hasStructured,
      residualText: residual,
      isWhereIs: isWhereIs,
      needsLlmFallback: needsLlmFallback,
    );
  }
}
