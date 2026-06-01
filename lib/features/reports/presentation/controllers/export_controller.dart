import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
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

  /// Export as PDF and share the file.
  Future<String?> exportPdf({String? propertyId}) async {
    state = const AsyncLoading();
    try {
      final bytes = await pdfGenerator.generateReport(propertyId: propertyId);

      final dir = await Directory.systemTemp.createTemp('still_life_export');
      final fileName =
          'still_life_report_${DateTime.now().toIso8601String().split('T').first}.pdf';
      final file = File(p.join(dir.path, fileName));
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(file.path)]);

      state = const AsyncData(null);
      return file.path;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return null;
    }
  }

  /// Export as JSON and share the file.
  Future<String?> exportJson() async {
    state = const AsyncLoading();
    try {
      final jsonString = await jsonExport.exportToJson();

      final dir = await Directory.systemTemp.createTemp('still_life_export');
      final fileName =
          'still_life_${DateTime.now().toIso8601String().split('T').first}.json';
      final file = File(p.join(dir.path, fileName));
      await file.writeAsString(jsonString);

      await Share.shareXFiles([XFile(file.path)]);

      state = const AsyncData(null);
      return file.path;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return null;
    }
  }

  /// Export as CSV and share the file.
  Future<String?> exportCsv() async {
    state = const AsyncLoading();
    try {
      final csvString = await csvExport.exportItemsToCsv();

      final dir = await Directory.systemTemp.createTemp('still_life_export');
      final fileName =
          'still_life_items_${DateTime.now().toIso8601String().split('T').first}.csv';
      final file = File(p.join(dir.path, fileName));
      await file.writeAsString(csvString);

      await Share.shareXFiles([XFile(file.path)]);

      state = const AsyncData(null);
      return file.path;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return null;
    }
  }

  /// Import from a JSON file picked by the user.
  Future<Result<ImportSummary>?> importJson() async {
    state = const AsyncLoading();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        state = const AsyncData(null);
        return null;
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      final importResult = await importService.importFromJson(jsonString);
      state = const AsyncData(null);
      return importResult;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return null;
    }
  }
}
