import 'package:csv/csv.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:still_life/features/import/domain/import_review_item.dart';
import 'package:still_life/services/import/bank_statement_parser.dart';

/// Screen for mapping CSV columns (date, description, amount) before import.
///
/// Shows detected column headers and lets the user assign each CSV column
/// to the date, description, and amount fields. Auto-detection pre-selects
/// columns when possible.
class BankColumnMapScreen extends StatefulWidget {
  final String csvContent;
  final BankColumnMap autoDetected;
  final bool truncated;

  const BankColumnMapScreen({
    super.key,
    required this.csvContent,
    required this.autoDetected,
    required this.truncated,
  });

  @override
  State<BankColumnMapScreen> createState() => _BankColumnMapScreenState();
}

class _BankColumnMapScreenState extends State<BankColumnMapScreen> {
  final _parser = BankStatementParser();

  late List<String> _headers;
  int? _dateCol;
  int? _descriptionCol;
  int? _amountCol;

  @override
  void initState() {
    super.initState();
    _headers = _extractHeaders();
    _dateCol = widget.autoDetected.dateCol;
    _descriptionCol = widget.autoDetected.descriptionCol;
    _amountCol = widget.autoDetected.amountCol;
  }

  List<String> _extractHeaders() {
    final rows = const CsvToListConverter(eol: '\n').convert(widget.csvContent);
    if (rows.isEmpty) return [];
    return rows.first.map((h) => h.toString().trim()).toList();
  }

  bool get _canContinue =>
      _dateCol != null && _descriptionCol != null && _amountCol != null;

  void _onContinue() {
    if (!_canContinue) return;

    final map = BankColumnMap(
      dateCol: _dateCol,
      descriptionCol: _descriptionCol,
      amountCol: _amountCol,
    );

    if (widget.truncated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only the first 500 rows will be imported.'),
        ),
      );
    }

    final result = _parser.parse(widget.csvContent, map);
    final items = result.items.map((p) => ImportReviewItem(parsed: p)).toList();

    context.pushNamed('importReview', extra: items);
  }

  Widget _buildColumnDropdown({
    required String label,
    required int? selectedIndex,
    required void Function(int?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: OhSpacing.xs),
          DropdownButtonFormField<int>(
            initialValue: selectedIndex,
            hint: const Text('Select column'),
            items: [
              for (int i = 0; i < _headers.length; i++)
                DropdownMenuItem(
                  value: i,
                  child: Text(
                    _headers[i].isEmpty ? 'Column ${i + 1}' : _headers[i],
                  ),
                ),
            ],
            onChanged: onChanged,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map CSV Columns')),
      body: Padding(
        padding: OhSpacing.insetMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Assign each CSV column to the correct field:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: OhSpacing.md),
            _buildColumnDropdown(
              label: 'Date column',
              selectedIndex: _dateCol,
              onChanged: (v) => setState(() => _dateCol = v),
            ),
            _buildColumnDropdown(
              label: 'Description column',
              selectedIndex: _descriptionCol,
              onChanged: (v) => setState(() => _descriptionCol = v),
            ),
            _buildColumnDropdown(
              label: 'Amount column',
              selectedIndex: _amountCol,
              onChanged: (v) => setState(() => _amountCol = v),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _canContinue ? _onContinue : null,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
