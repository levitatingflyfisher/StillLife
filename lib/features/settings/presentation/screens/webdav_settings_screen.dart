import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../services/backup/webdav_backup_service.dart';

final _webDavServiceProvider = Provider<WebDavBackupService>((ref) {
  return WebDavBackupService();
});

class WebDavSettingsScreen extends ConsumerStatefulWidget {
  const WebDavSettingsScreen({super.key});

  @override
  ConsumerState<WebDavSettingsScreen> createState() =>
      _WebDavSettingsScreenState();
}

class _WebDavSettingsScreenState extends ConsumerState<WebDavSettingsScreen> {
  final _urlCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final cfg = await ref.read(_webDavServiceProvider).loadConfig();
    if (cfg != null && mounted) {
      setState(() {
        _urlCtrl.text = cfg.url;
        _userCtrl.text = cfg.username ?? '';
        _passCtrl.text = cfg.password ?? '';
      });
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('https://')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'WebDAV URL must start with https:// — Basic Auth over HTTP '
              'would leak your credentials.',
            ),
          ),
        );
      }
      return;
    }
    await ref
        .read(_webDavServiceProvider)
        .saveConfig(
          WebDavConfig(
            url: url,
            username: _userCtrl.text.trim().isEmpty
                ? null
                : _userCtrl.text.trim(),
            password: _passCtrl.text.isEmpty ? null : _passCtrl.text,
          ),
        );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('WebDAV settings saved')));
    }
  }

  Future<void> _backup() async {
    setState(() => _isBusy = true);
    try {
      final jsonStr = await ref.read(exportServiceProvider).exportToJson();
      final result = await ref.read(_webDavServiceProvider).backup(jsonStr);
      if (mounted) {
        result.when(
          success: (_) => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup uploaded successfully')),
          ),
          failure: (f) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Backup failed: ${f.message}')),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _restore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from WebDAV'),
        content: const Text(
          'This will merge the remote backup into your local database. '
          'Existing items will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);
    try {
      final fetchResult = await ref.read(_webDavServiceProvider).restore();
      final jsonStr = fetchResult.when(
        success: (data) => data,
        failure: (f) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Restore failed: ${f.message}')),
            );
          }
          return null;
        },
      );
      if (jsonStr == null) return;
      final result = await ref
          .read(importServiceProvider)
          .importFromJson(jsonStr);
      if (mounted) {
        result.when(
          success: (s) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Restored ${s.totalRecords} records')),
          ),
          failure: (f) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Restore failed: ${f.message}')),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebDAV Backup')),
      body: ListView(
        padding: OhSpacing.insetMd,
        children: [
          const Text(
            'Point Still Life at a WebDAV server (Nextcloud, Synology, etc.) '
            'to back up and restore your inventory.',
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _urlCtrl,
            decoration: const InputDecoration(
              labelText: 'WebDAV URL',
              hintText:
                  'https://cloud.example.com/remote.php/dav/files/alice/backup.json',
              helperText: 'Must start with https://',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _userCtrl,
            decoration: const InputDecoration(
              labelText: 'Username (optional)',
              border: OutlineInputBorder(),
            ),
            autocorrect: false,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscurePass,
            decoration: InputDecoration(
              labelText: 'Password / App token (optional)',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePass ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isBusy ? null : _save,
            child: const Text('Save Settings'),
          ),
          const SizedBox(height: OhSpacing.lg),
          const Divider(),
          const SizedBox(height: OhSpacing.md),
          if (_isBusy)
            const Center(child: CircularProgressIndicator())
          else ...[
            OutlinedButton.icon(
              onPressed: _backup,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Back Up Now'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _restore,
              icon: const Icon(Icons.cloud_download_outlined),
              label: const Text('Restore from WebDAV'),
            ),
          ],
        ],
      ),
    );
  }
}
