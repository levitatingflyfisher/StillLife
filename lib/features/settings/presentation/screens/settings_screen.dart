import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';
import 'package:share_plus/share_plus.dart';

import 'package:still_life/core/config/feature_flags.dart';
import 'package:still_life/core/providers/billing_providers.dart';
import 'package:still_life/features/import/domain/import_review_args.dart';
import 'package:still_life/features/import/domain/import_review_item.dart';
import 'package:still_life/services/import/bank_statement_parser.dart';
import 'package:still_life/services/import/import_receipt_ocr_service.dart'
    show ReceiptImportResult;
import 'package:still_life/features/backup/presentation/photo_backup_tile.dart';
import '../../../../../core/providers/product_lookup_providers.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../controllers/theme_controller.dart';

/// Resolved at first read; package_info_plus loads platform metadata
/// asynchronously. Returns the formatted "Version X.Y.Z (build N)" string.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  final version = info.version.isEmpty ? '0.0.0' : info.version;
  return info.buildNumber.isEmpty
      ? 'Version $version'
      : 'Version $version (build ${info.buildNumber})';
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isExporting = false;
  bool _isExportingCsv = false;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Appearance
          const _SectionHeader(title: 'Appearance'),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Theme'),
            subtitle: Text(_themeModeLabel(themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context, ref, themeMode),
          ),

          const Divider(),

          // Inventory Management
          const _SectionHeader(title: 'Inventory'),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Categories'),
            subtitle: const Text('Manage item categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed('categoryManagement'),
          ),
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: const Text('Tags'),
            subtitle: const Text('Manage custom tags'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed('tagManagement'),
          ),

          // Encrypted backup: seed-phrase setup + .ohbk export/restore, plus
          // the photos-included .ohbkz container below. Replaces the old
          // disabled "Database Encryption" placeholder (SANCTUARY-BRIEF §4.W3).
          // Renders its own "Encrypted Backup" header + leading Divider.
          const BackupSettingsSection(),
          // The photos-included .ohbkz container (SANCTUARY-BRIEF §4.W3).
          const PhotoBackupTile(),

          const Divider(),

          // LLM Configuration
          const _SectionHeader(title: 'AI Analysis'),
          ListTile(
            leading: const Icon(Icons.psychology_outlined),
            title: const Text('AI Analysis'),
            subtitle: const Text('Configure LLM providers and API keys'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed('llmSettings'),
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('What should I insure?'),
            subtitle: const Text(
              'Top uncovered high-value items in your inventory',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed('insuranceGaps'),
          ),

          const Divider(),

          // Data Management
          const _SectionHeader(title: 'Data Management'),
          ListTile(
            leading: _isExporting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined),
            title: const Text('Export Data'),
            subtitle: const Text('Portable JSON — unencrypted (for an '
                'encrypted copy, use Encrypted Backup above)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _isExporting ? null : _handleExport,
          ),
          ListTile(
            leading: _isExportingCsv
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.table_chart_outlined),
            title: const Text('Export as CSV'),
            subtitle: const Text('Spreadsheet of all items'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _isExportingCsv ? null : _handleExportCsv,
          ),
          ListTile(
            leading: _isImporting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_upload_outlined),
            title: const Text('Import Data'),
            subtitle: const Text('Import from a Still Life backup'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _isImporting ? null : _handleImport,
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Import items'),
            subtitle: const Text('From receipt, Amazon, or bank statement'),
            onTap: () => _showImportOptions(context),
          ),

          const Divider(),

          // Household
          const _SectionHeader(title: 'Household'),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Profiles'),
            subtitle: const Text('Manage household members'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed('profiles'),
          ),

          const Divider(),

          // Pro & Billing (feature-flag gated — debug only until the
          // hosted-LLM proxy goes live).
          if (FeatureFlags.proBillingEnabled) ...[
            const _SectionHeader(title: 'Pro & Billing'),
            Consumer(
              builder: (context, ref, _) {
                final acc = ref.watch(accountProvider).valueOrNull;
                final label = acc == null
                    ? 'Upgrade to Pro'
                    : (acc.isActive ? 'Pro active' : 'Pro ${acc.status.name}');
                return ListTile(
                  leading: const Icon(Icons.star_outline),
                  title: Text(label),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.pushNamed('pro'),
                );
              },
            ),
            const Divider(),
          ],

          // Sync
          const _SectionHeader(title: 'Sync'),
          ListTile(
            leading: const Icon(Icons.sync_outlined),
            title: const Text('Sync & Backup'),
            subtitle: const Text('Sync with devices on your Wi-Fi'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed('sync'),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('WebDAV Backup'),
            subtitle: const Text('Back up to Nextcloud or any WebDAV server'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed('webdavSettings'),
          ),

          const Divider(),

          // About
          const _SectionHeader(title: 'About'),
          Consumer(
            builder: (context, ref, _) {
              final versionAsync = ref.watch(appVersionProvider);
              return ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Still Life'),
                subtitle: Text(versionAsync.valueOrNull ?? 'Version …'),
              );
            },
          ),
          const ListTile(
            leading: Icon(Icons.gavel_outlined),
            title: Text('License'),
            subtitle: Text('MIT'),
          ),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy'),
            subtitle: Text(
              'No telemetry. No ads. Your data stays on your device.',
            ),
          ),
          Consumer(
            builder: (context, ref, _) {
              final enabledAsync = ref.watch(productLookupEnabledProvider);
              final enabled = enabledAsync.valueOrNull ?? false;
              return SwitchListTile(
                secondary: const Icon(Icons.search_outlined),
                title: const Text('Online product lookup'),
                subtitle: const Text(
                  'Send barcodes to Open Food Facts / UPCitemdb to look up '
                  'product names. Results are cached locally; each barcode '
                  'is only fetched once.',
                ),
                value: enabled,
                onChanged: (v) => ref
                    .read(productLookupEnabledProvider.notifier)
                    .setEnabled(v),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    try {
      final exportService = ref.read(exportServiceProvider);
      final jsonString = await exportService.exportToJson();

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .substring(0, 19);
      // Share bytes directly (no temp file) — same path on Android and web.
      final name = 'still_life_backup_$timestamp.json';
      await Share.shareXFiles([
        XFile.fromData(
          Uint8List.fromList(utf8.encode(jsonString)),
          mimeType: 'application/json',
          name: name,
        ),
      ], subject: 'Still Life Backup', fileNameOverrides: [name]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleExportCsv() async {
    setState(() => _isExportingCsv = true);
    try {
      final csvService = ref.read(csvExportServiceProvider);
      final csv = await csvService.exportItemsToCsv();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .substring(0, 19);
      final name = 'still_life_items_$timestamp.csv';
      await Share.shareXFiles([
        XFile.fromData(
          Uint8List.fromList(utf8.encode(csv)),
          mimeType: 'text/csv',
          name: name,
        ),
      ], subject: 'Still Life Inventory', fileNameOverrides: [name]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('CSV export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExportingCsv = false);
    }
  }

  Future<void> _handleImport() async {
    setState(() => _isImporting = true);
    try {
      // withData: the picker hands back bytes, which is all the web has
      // (no paths there) and works identically on Android.
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      final bytes = result?.files.single.bytes;
      if (bytes == null) return;

      final jsonString = utf8.decode(bytes);
      final importService = ref.read(importServiceProvider);
      final importResult = await importService.importFromJson(jsonString);

      if (mounted) {
        importResult.when(
          success: (summary) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Imported ${summary.totalRecords} records successfully',
                ),
              ),
            );
          },
          failure: (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Import failed: ${failure.message}'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _showImportOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Receipt OCR is on-device MLKit — native-only, so the options
            // are honestly absent on web rather than silently failing.
            if (!kIsWeb) ...[
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Receipt camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _handleReceiptImport(context, source: ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('Receipt photo'),
                subtitle: const Text('From your gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _handleReceiptImport(context, source: ImageSource.gallery);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: const Text('Amazon order export'),
              subtitle: const Text('Order history CSV or email text'),
              trailing: IconButton(
                icon: const Icon(Icons.help_outline, size: 20),
                tooltip: 'How do I get this file?',
                onPressed: () => _showAmazonExportHelp(context),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _handleAmazonImport(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_outlined),
              title: const Text('Bank statement'),
              subtitle: const Text('CSV export'),
              onTap: () {
                Navigator.of(context).pop();
                _handleBankImport(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleReceiptImport(
    BuildContext context, {
    required ImageSource source,
  }) async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: source);
      if (photo == null || !context.mounted) return;

      final imageBytes = await photo.readAsBytes();
      if (!context.mounted) return;

      // OCR + LLM structuring can take many seconds; a blank screen
      // reads as a frozen app, so block behind a visible spinner.
      final ocrService = ref.read(receiptOcrServiceProvider);
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        ),
      );
      final ReceiptImportResult result;
      try {
        result = await ocrService.parseReceipt(photo.path);
      } finally {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }
      if (!context.mounted) return;
      if (result.items.isEmpty) {
        // Silence here made the feature look broken — say what happened.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No items found on the receipt — try a clearer, closer photo.',
            ),
          ),
        );
        return;
      }

      final reviewItems = result.items
          .map((p) => ImportReviewItem(parsed: p))
          .toList();
      context.pushNamed(
        'importReview',
        extra: ImportReviewArgs(
          items: reviewItems,
          receipt: ImportReviewReceipt(
            engineLabel: result.engineLabel,
            storeName: result.storeName,
            purchaseDate: result.purchaseDate,
            totalAmount: result.totalAmount,
            ocrText: result.ocrText,
            imageBytes: imageBytes,
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  /// Amazon retired self-serve order reports in 2023; the working path is
  /// the Privacy Central data request. Plain steps, no marketing.
  void _showAmazonExportHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How do I get this file?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amazon no longer offers order reports on its website. '
              'Request your data instead:',
            ),
            SizedBox(height: 12),
            Text('1. Amazon > Account > Privacy Central > Request My Data'),
            Text('2. Select "Your Orders" and submit'),
            Text('3. The export arrives as a ZIP, usually within hours'),
            Text('4. Import the Retail.OrderHistory CSV from that ZIP'),
            SizedBox(height: 12),
            Text(
              'On a computer, the azad browser extension or the '
              'amazon-orders command-line tool can also produce an order CSV.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAmazonImport(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt', 'html'],
        withData: true,
      );
      if (result == null || result.files.isEmpty || !context.mounted) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null || !context.mounted) return;

      final content = utf8.decode(bytes, allowMalformed: true);
      final amazonService = ref.read(amazonImportServiceProvider);

      // Format detection is header-driven — the file keeps working no
      // matter what the ZIP extractor named it.
      final parsed = amazonService.parse(content);

      if (!context.mounted) return;
      if (parsed.isEmpty) {
        // The help dialog just sold this flow; a silent dead-end on the
        // wrong CSV (e.g. Digital-Orders) reads as a broken feature.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No orders found in that file — import the '
              'Retail.OrderHistory CSV from your Amazon data request.',
            ),
          ),
        );
        return;
      }
      final reviewItems = parsed
          .map((p) => ImportReviewItem(parsed: p))
          .toList();
      context.pushNamed('importReview', extra: reviewItems);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  Future<void> _handleBankImport(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty || !context.mounted) return;

      final bytes = result.files.first.bytes;
      if (bytes == null || !context.mounted) return;

      final content = utf8.decode(bytes, allowMalformed: true);
      if (!context.mounted) return;

      final bankParser = BankStatementParser();
      final autoDetected = bankParser.detectColumns(content);

      context.pushNamed(
        'bankColumns',
        extra: {
          'csvContent': content,
          'autoDetected': autoDetected,
          'truncated': content.split('\n').length > 501,
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };
  }

  Future<void> _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) async {
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose Theme'),
        children: ThemeMode.values
            .map(
              (mode) => SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(mode),
                child: Row(
                  children: [
                    Icon(
                      mode == current
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: mode == current
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(_themeModeLabel(mode)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
    if (selected != null) {
      ref.read(themeModeProvider.notifier).setThemeMode(selected);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
