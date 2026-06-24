import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:still_life/core/config/feature_flags.dart';
import 'package:still_life/core/providers/billing_providers.dart';
import 'package:still_life/features/import/domain/import_review_item.dart';
import 'package:still_life/features/import/domain/parsed_import_item.dart';
import 'package:still_life/services/import/bank_statement_parser.dart';
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

          const Divider(),

          // Security
          const _SectionHeader(title: 'Security'),
          const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('Database Encryption'),
            subtitle: Text(
              'End-to-end encryption — planned for a future update',
            ),
            enabled: false,
          ),

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
            subtitle: const Text('Export your inventory as JSON'),
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
            subtitle: Text('AGPL-3.0 (Community Edition)'),
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

      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .substring(0, 19);
      final file = File(p.join(dir.path, 'still_life_backup_$timestamp.json'));
      await file.writeAsString(jsonString);

      await Share.shareXFiles([
        XFile(file.path, mimeType: 'application/json'),
      ], subject: 'Still Life Backup');
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
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .substring(0, 19);
      final file = File(p.join(dir.path, 'still_life_items_$timestamp.csv'));
      await file.writeAsString(csv);
      await Share.shareXFiles([
        XFile(file.path, mimeType: 'text/csv'),
      ], subject: 'Still Life Inventory');
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
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final path = result.files.single.path;
      if (path == null) return;

      final jsonString = await File(path).readAsString();
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
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Receipt photo'),
              onTap: () {
                Navigator.of(context).pop();
                _handleReceiptImport(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: const Text('Amazon order export'),
              subtitle: const Text('CSV or email text'),
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

  Future<void> _handleReceiptImport(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: ImageSource.gallery);
      if (photo == null || !context.mounted) return;

      final ocrService = ref.read(receiptOcrServiceProvider);
      final items = await ocrService.parseReceipt(File(photo.path));
      if (items.isEmpty || !context.mounted) return;

      final reviewItems = items
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

  Future<void> _handleAmazonImport(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt', 'html'],
      );
      if (result == null || result.files.isEmpty || !context.mounted) return;

      final file = result.files.first;
      final path = file.path;
      if (path == null || !context.mounted) return;

      final bytes = await File(path).readAsBytes();
      final content = utf8.decode(bytes, allowMalformed: true);
      final amazonService = ref.read(amazonImportServiceProvider);

      final List<ParsedImportItem> parsed;
      if (file.extension?.toLowerCase() == 'csv') {
        parsed = amazonService.parseFromCsv(content);
      } else {
        parsed = amazonService.parseFromText(content);
      }

      if (parsed.isEmpty || !context.mounted) return;
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
      );
      if (result == null || result.files.isEmpty || !context.mounted) return;

      final path = result.files.first.path;
      if (path == null || !context.mounted) return;

      final bytes = await File(path).readAsBytes();
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
