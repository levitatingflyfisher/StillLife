import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../services/export/csv_export_service.dart';
import '../../../../services/export/import_service.dart';
import '../../../../services/export/json_export_service.dart';
import '../../data/services/pdf_report_generator.dart';

final exportControllerProvider =
    StateNotifierProvider<ExportController, AsyncValue<void>>((ref) {
      final db = ref.watch(databaseProvider);
      return ExportController(
        jsonExport: JsonExportService(db),
        csvExport: CsvExportService(db),
        importService: ImportService(db),
        pdfGenerator: PdfReportGenerator(db),
      );
    });

class ExportController extends StateNotifier<AsyncValue<void>> {
  final JsonExportService jsonExport;
  final CsvExportService csvExport;
  final ImportService importService;
  final PdfReportGenerator pdfGenerator;

  ExportController({
    required this.jsonExport,
    required this.csvExport,
    required this.importService,
    required this.pdfGenerator,
  }) : super(const AsyncData(null));

  static String _dateStamp() =>
      DateTime.now().toIso8601String().split('T').first;

  /// Shares [bytes] directly — no temp file, so the identical path works on
  /// Android and web (same XFile.fromData pattern as the shopping-list
  /// export). Returns the shared file name, or null on failure.
  Future<String?> _shareBytes(
    Uint8List bytes,
    String name,
    String mimeType,
  ) async {
    await Share.shareXFiles([
      XFile.fromData(bytes, mimeType: mimeType, name: name),
    ], fileNameOverrides: [name]);
    return name;
  }

  /// Export as PDF and share it.
  Future<String?> exportPdf({String? propertyId}) async {
    state = const AsyncLoading();
    try {
      final bytes = await pdfGenerator.generateReport(propertyId: propertyId);
      final name = 'still_life_report_${_dateStamp()}.pdf';
      await _shareBytes(bytes, name, 'application/pdf');
      state = const AsyncData(null);
      return name;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return null;
    }
  }

  /// Export as JSON and share it.
  Future<String?> exportJson() async {
    state = const AsyncLoading();
    try {
      final jsonString = await jsonExport.exportToJson();
      final name = 'still_life_${_dateStamp()}.json';
      await _shareBytes(
        Uint8List.fromList(utf8.encode(jsonString)),
        name,
        'application/json',
      );
      state = const AsyncData(null);
      return name;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return null;
    }
  }

  /// Export as CSV and share it.
  Future<String?> exportCsv() async {
    state = const AsyncLoading();
    try {
      final csvString = await csvExport.exportItemsToCsv();
      final name = 'still_life_items_${_dateStamp()}.csv';
      await _shareBytes(
        Uint8List.fromList(utf8.encode(csvString)),
        name,
        'text/csv',
      );
      state = const AsyncData(null);
      return name;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return null;
    }
  }

  /// Import from a JSON file picked by the user.
  Future<Result<ImportSummary>?> importJson() async {
    state = const AsyncLoading();
    try {
      // withData: the picker hands back the file's bytes, which is the only
      // thing available on the web (there is no path) and works everywhere.
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      final bytes = result?.files.single.bytes;
      if (bytes == null) {
        state = const AsyncData(null);
        return null;
      }

      final jsonString = utf8.decode(bytes);
      final importResult = await importService.importFromJson(jsonString);
      state = const AsyncData(null);
      return importResult;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return null;
    }
  }
}
