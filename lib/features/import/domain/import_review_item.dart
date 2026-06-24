import 'parsed_import_item.dart';

/// Mutable wrapper around [ParsedImportItem] for the import review screen.
///
/// Ephemeral — never persisted. No Equatable, no copyWith.
class ImportReviewItem {
  ParsedImportItem parsed;
  String? roomId;
  bool hasRoomOverride;
  String? categoryId;
  bool accepted;

  ImportReviewItem({
    required this.parsed,
    this.roomId,
    this.hasRoomOverride = false,
    this.categoryId,
    this.accepted = true,
  });
}
