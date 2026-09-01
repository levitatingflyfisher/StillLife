import 'package:flutter/material.dart';

import '../../services/export/import_service.dart';

/// Asks before an explicit JSON import applies records that carry no edit
/// time. Such a file (from before rows were stamped) is still importable, but
/// its records replace the device's copies of the same records wholesale,
/// even where the device's are newer. Returns true when there is nothing to
/// warn about or the user chose to import anyway.
Future<bool> confirmOldFileImport(
  BuildContext context,
  String jsonString,
) async {
  final n = ImportService.countUnstampedRows(jsonString);
  if (n == 0) return true;
  final records =
      n == 1 ? '1 record in this file has' : '$n records in this file have';
  final those = n == 1 ? 'that record' : 'those records';
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('This file is from an older Still Life'),
      content: Text(
        '$records no edit time. Importing replaces your '
        'copies of $those with the file’s versions, even where yours '
        'are newer.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Import anyway'),
        ),
      ],
    ),
  );
  return ok == true;
}
