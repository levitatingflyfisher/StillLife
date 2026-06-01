import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/notification_providers.dart';
import '../../domain/entities/maintenance_log.dart';
import '../controllers/maintenance_controller.dart';

const _uuid = Uuid();

class MaintenanceAddScreen extends ConsumerStatefulWidget {
  final MaintenanceLog? existing;

  const MaintenanceAddScreen({super.key, this.existing});

  @override
  ConsumerState<MaintenanceAddScreen> createState() =>
      _MaintenanceAddScreenState();
}

class _MaintenanceAddScreenState extends ConsumerState<MaintenanceAddScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _servicedByCtrl;

  late DateTime _performedAt;
  DateTime? _nextDueAt;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descriptionCtrl = TextEditingController(text: e?.description ?? '');
    _costCtrl = TextEditingController(text: e?.cost?.toStringAsFixed(2) ?? '');
    _servicedByCtrl = TextEditingController(text: e?.servicedBy ?? '');
    _performedAt = e?.performedAt ?? DateTime.now();
    _nextDueAt = e?.nextDueAt;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _costCtrl.dispose();
    _servicedByCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPerformed() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _performedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _performedAt = picked);
  }

  Future<void> _pickNextDue() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDueAt ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _nextDueAt = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final log = MaintenanceLog(
      id: widget.existing?.id ?? _uuid.v4(),
      itemId: widget.existing?.itemId,
      propertyId: widget.existing?.propertyId,
      title: _titleCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      cost: double.tryParse(_costCtrl.text),
      performedAt: _performedAt,
      nextDueAt: _nextDueAt,
      servicedBy: _servicedByCtrl.text.trim().isEmpty
          ? null
          : _servicedByCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      modifiedAt: DateTime.now(),
    );

    final controller = ref.read(maintenanceControllerProvider.notifier);
    final ok = _isEdit ? await controller.edit(log) : await controller.add(log);

    if (ok) {
      // Schedule or cancel maintenance reminder.
      final ns = ref.read(notificationServiceProvider);
      if (_nextDueAt != null) {
        ns
            .scheduleMaintenanceReminder(
              logId: log.id,
              title: log.title,
              dueDate: _nextDueAt!,
            )
            .catchError((_) {});
      } else if (_isEdit) {
        ns.cancelMaintenanceReminder(log.id).catchError((_) {});
      }
    }

    if (ok && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Entry' : 'Log Maintenance')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: OhSpacing.insetMd,
          children: [
            // Title
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. AC filter replacement',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: OhSpacing.md),

            // Description
            TextFormField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
            ),
            const SizedBox(height: OhSpacing.md),

            // Performed date
            ListTile(
              title: const Text('Performed date'),
              subtitle: Text(fmt.format(_performedAt)),
              trailing: const Icon(Icons.calendar_today),
              shape: RoundedRectangleBorder(
                borderRadius: OhRadii.lg,
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              onTap: _pickPerformed,
            ),
            const SizedBox(height: OhSpacing.md),

            // Next due date
            ListTile(
              title: const Text('Schedule next maintenance (optional)'),
              subtitle: Text(
                _nextDueAt != null ? fmt.format(_nextDueAt!) : 'Not set',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_nextDueAt != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _nextDueAt = null),
                    ),
                  const Icon(Icons.calendar_today),
                ],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: OhRadii.lg,
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              onTap: _pickNextDue,
            ),
            const SizedBox(height: OhSpacing.md),

            // Cost
            TextFormField(
              controller: _costCtrl,
              decoration: const InputDecoration(
                labelText: 'Cost (optional)',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: OhSpacing.md),

            // Serviced by
            TextFormField(
              controller: _servicedByCtrl,
              decoration: const InputDecoration(
                labelText: 'Serviced by (optional)',
                hintText: 'e.g. ABC HVAC Services',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: OhSpacing.lg),

            FilledButton(
              onPressed: _save,
              child: Text(_isEdit ? 'Save Changes' : 'Log Maintenance'),
            ),
          ],
        ),
      ),
    );
  }
}
