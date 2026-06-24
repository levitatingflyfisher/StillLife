import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../services/database/database.dart';

/// Generates a PDF inventory report from the database.
class PdfReportGenerator {
  final AppDatabase _db;

  PdfReportGenerator(this._db);

  /// Generate a full inventory report as PDF bytes.
  ///
  /// If [propertyId] is provided, the report is scoped to that property.
  /// If [includePhotos] is true, item photos are embedded (not yet implemented).
  Future<Uint8List> generateReport({
    String? propertyId,
    bool includePhotos = true,
  }) async {
    // Fetch data
    final allProperties = await _db.select(_db.properties).get();
    final filteredProperties = propertyId != null
        ? allProperties.where((p) => p.id == propertyId).toList()
        : allProperties;

    final allRooms = await _db.select(_db.rooms).get();
    final allItems = await _db.select(_db.items).get();
    final allCategories = await _db.select(_db.categories).get();

    // Filter by property if needed
    final propertyIds = filteredProperties.map((p) => p.id).toSet();
    final rooms = propertyId != null
        ? allRooms.where((r) => propertyIds.contains(r.propertyId)).toList()
        : allRooms;
    final roomIds = rooms.map((r) => r.id).toSet();
    final items = propertyId != null
        ? allItems.where((i) => roomIds.contains(i.roomId)).toList()
        : allItems;

    // Build lookup maps
    final categoryMap = {for (final c in allCategories) c.id: c.name};
    final roomMap = {for (final r in rooms) r.id: r.name};

    // Calculate totals
    final totalCurrentValue = items.fold(
      0.0,
      (sum, i) => sum + (i.currentValue ?? 0),
    );
    final totalReplacementCost = items.fold(
      0.0,
      (sum, i) => sum + (i.replacementCost ?? 0),
    );
    final totalAcquisitionCost = items.fold(
      0.0,
      (sum, i) => sum + (i.purchasePrice ?? 0),
    );

    // Group items by room
    final itemsByRoom = <String, List<Item>>{};
    for (final item in items) {
      itemsByRoom.putIfAbsent(item.roomId, () => []).add(item);
    }

    // Group items by category for value breakdown
    final valueByCategory = <String, double>{};
    for (final item in items) {
      final catName = categoryMap[item.categoryId] ?? 'Uncategorized';
      valueByCategory[catName] =
          (valueByCategory[catName] ?? 0) + (item.currentValue ?? 0);
    }

    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMMM d, yyyy');
    final propertyName = filteredProperties.isNotEmpty
        ? filteredProperties.first.name
        : 'All Properties';

    // Build PDF
    final pdf = pw.Document(
      title: 'Home Inventory Report',
      author: 'Still Life',
    );

    // --- Cover Page ---
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'Home Inventory Report',
                style: pw.TextStyle(
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Text(propertyName, style: const pw.TextStyle(fontSize: 20)),
              pw.SizedBox(height: 12),
              pw.Text(
                'Generated: ${dateFormat.format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                'Total Value: ${currencyFormat.format(totalCurrentValue)}',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // --- Summary Page ---
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Summary',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            _buildSummaryTable(
              totalItems: items.length,
              totalCurrentValue: totalCurrentValue,
              totalReplacementCost: totalReplacementCost,
              totalAcquisitionCost: totalAcquisitionCost,
              currencyFormat: currencyFormat,
            ),
            pw.SizedBox(height: 32),
            pw.Text(
              'Value Breakdown by Category',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            _buildCategoryValueTable(valueByCategory, currencyFormat),
          ],
        ),
      ),
    );

    // --- Items by Room Pages ---
    for (final entry in itemsByRoom.entries) {
      final roomName = roomMap[entry.key] ?? 'Unknown Room';
      final roomItems = entry.value;
      final roomTotal = roomItems.fold(
        0.0,
        (sum, i) => sum + (i.currentValue ?? 0),
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,
          header: (context) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  roomName,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Subtotal: ${currencyFormat.format(roomTotal)}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          build: (context) => [
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellPadding: const pw.EdgeInsets.all(4),
              headers: [
                'Name',
                'Category',
                'Current Value',
                'Replacement Cost',
                'Condition',
              ],
              data: roomItems.map((item) {
                return [
                  item.name,
                  categoryMap[item.categoryId] ?? '-',
                  item.currentValue != null
                      ? currencyFormat.format(item.currentValue)
                      : '-',
                  item.replacementCost != null
                      ? currencyFormat.format(item.replacementCost)
                      : '-',
                  item.condition ?? '-',
                ];
              }).toList(),
            ),
          ],
        ),
      );
    }

    return pdf.save();
  }

  pw.Widget _buildSummaryTable({
    required int totalItems,
    required double totalCurrentValue,
    required double totalReplacementCost,
    required double totalAcquisitionCost,
    required NumberFormat currencyFormat,
  }) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellPadding: const pw.EdgeInsets.all(6),
      headers: ['Metric', 'Value'],
      data: [
        ['Total Items', totalItems.toString()],
        ['Total Current Value', currencyFormat.format(totalCurrentValue)],
        ['Total Replacement Cost', currencyFormat.format(totalReplacementCost)],
        ['Total Acquisition Cost', currencyFormat.format(totalAcquisitionCost)],
      ],
    );
  }

  pw.Widget _buildCategoryValueTable(
    Map<String, double> valueByCategory,
    NumberFormat currencyFormat,
  ) {
    final sorted = valueByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellPadding: const pw.EdgeInsets.all(4),
      headers: ['Category', 'Total Value'],
      data: sorted.map((e) => [e.key, currencyFormat.format(e.value)]).toList(),
    );
  }
}
