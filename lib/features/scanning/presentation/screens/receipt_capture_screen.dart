import 'dart:io';
import 'package:openhearth_design/openhearth_design.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/receipt_parser.dart';

enum _CaptureState { initial, processing, results }

class ReceiptCaptureScreen extends ConsumerStatefulWidget {
  const ReceiptCaptureScreen({super.key});

  @override
  ConsumerState<ReceiptCaptureScreen> createState() =>
      _ReceiptCaptureScreenState();
}

class _ReceiptCaptureScreenState extends ConsumerState<ReceiptCaptureScreen> {
  _CaptureState _state = _CaptureState.initial;
  File? _capturedImage;

  String? _storeName;
  String? _date;
  String? _total;
  List<ReceiptLineItem> _lineItems = [];

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _captureReceipt() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null || !mounted) return;

    setState(() {
      _state = _CaptureState.processing;
      _capturedImage = File(photo.path);
    });

    try {
      final result = await _runOcr(photo.path);
      if (!mounted) return;
      setState(() {
        _state = _CaptureState.results;
        _storeName = result.storeName ?? 'Not detected';
        _date = result.date ?? 'Not detected';
        _total = result.total ?? 'Not detected';
        _lineItems = List<ReceiptLineItem>.from(result.lineItems);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = _CaptureState.results;
        _storeName = 'Not detected';
        _date = 'Not detected';
        _total = 'Not detected';
        _lineItems = [];
      });
    }
  }

  Future<_OcrResult> _runOcr(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized = await recognizer.processImage(inputImage);
      final parsed = _parseReceiptText(recognized.text);
      return _OcrResult(
        storeName: parsed.storeName,
        date: parsed.date,
        total: parsed.total,
        lineItems: parsed.lineItems
            .map((e) => _LineItem(name: e.name, price: e.price))
            .toList(),
      );
    } finally {
      recognizer.close();
    }
  }

  ReceiptParseResult _parseReceiptText(String text) =>
      const ReceiptParser().parse(text);

  void _retake() {
    setState(() {
      _state = _CaptureState.initial;
      _capturedImage = null;
      _storeName = null;
      _date = null;
      _total = null;
      _lineItems = <ReceiptLineItem>[];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Capture Receipt'), centerTitle: true),
      body: switch (_state) {
        _CaptureState.initial => _buildInitialState(theme, colorScheme),
        _CaptureState.processing => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: OhSpacing.md),
              Text('Processing receipt...'),
            ],
          ),
        ),
        _CaptureState.results => _buildResultsState(theme, colorScheme),
      },
    );
  }

  Widget _buildInitialState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: OhSpacing.lg),
          Text(
            'Take a photo of your receipt',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: OhSpacing.sm),
          Text(
            'We\'ll extract store, date, and item details',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _captureReceipt,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Capture Receipt'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsState(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: OhSpacing.insetMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Captured image preview
          if (_capturedImage != null)
            ClipRRect(
              borderRadius: OhRadii.lg,
              child: Image.file(
                _capturedImage!,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: OhSpacing.md),

          // Parsed results
          Card(
            child: Padding(
              padding: OhSpacing.insetMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Receipt Details', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _DetailRow(label: 'Store', value: _storeName ?? ''),
                  _DetailRow(label: 'Date', value: _date ?? ''),
                  _DetailRow(label: 'Total', value: _total ?? ''),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Line items
          Card(
            child: Padding(
              padding: OhSpacing.insetMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Line Items', style: theme.textTheme.titleMedium),
                  const SizedBox(height: OhSpacing.sm),
                  if (_lineItems.isEmpty)
                    Text(
                      'No items detected',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    ...List.generate(_lineItems.length, (index) {
                      final lineItem = _lineItems[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text(
                            '${index + 1}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        title: Text(lineItem.name),
                        subtitle: lineItem.price.isNotEmpty
                            ? Text(
                                lineItem.price,
                                style: theme.textTheme.bodySmall,
                              )
                            : null,
                        trailing: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Link to item — coming soon'),
                              ),
                            );
                          },
                          child: const Text('Link to Item'),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: OhSpacing.md),

          OutlinedButton.icon(
            onPressed: _retake,
            icon: const Icon(Icons.refresh),
            label: const Text('Retake'),
          ),
        ],
      ),
    );
  }
}

class _OcrResult {
  final String? storeName;
  final String? date;
  final String? total;
  final List<_LineItem> lineItems;

  const _OcrResult({
    this.storeName,
    this.date,
    this.total,
    required this.lineItems,
  });
}

class _LineItem {
  final String name;
  final String price;

  const _LineItem({required this.name, required this.price});
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: OhSpacing.sm),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
