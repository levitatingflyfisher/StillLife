import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/policy.dart';
import '../controllers/policy_controller.dart';
import '../../../locations/presentation/controllers/location_controller.dart';

const _uuid = Uuid();

class PolicyAddEditScreen extends ConsumerStatefulWidget {
  /// null = add mode, non-null = edit mode.
  final Policy? existing;

  const PolicyAddEditScreen({super.key, this.existing});

  @override
  ConsumerState<PolicyAddEditScreen> createState() =>
      _PolicyAddEditScreenState();
}

class _PolicyAddEditScreenState extends ConsumerState<PolicyAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _providerCtrl;
  late final TextEditingController _policyNumberCtrl;
  late final TextEditingController _coverageCtrl;
  late final TextEditingController _deductibleCtrl;
  late final TextEditingController _premiumCtrl;

  String? _selectedPropertyId;
  DateTime? _expiryDate;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _providerCtrl = TextEditingController(text: e?.provider ?? '');
    _policyNumberCtrl = TextEditingController(text: e?.policyNumber ?? '');
    _coverageCtrl = TextEditingController(
      text: e?.coverageAmount?.toStringAsFixed(2) ?? '',
    );
    _deductibleCtrl = TextEditingController(
      text: e?.deductible?.toStringAsFixed(2) ?? '',
    );
    _premiumCtrl = TextEditingController(
      text: e?.premium?.toStringAsFixed(2) ?? '',
    );
    _selectedPropertyId = e?.propertyId;
    _expiryDate = e?.expiryDate;
  }

  @override
  void dispose() {
    _providerCtrl.dispose();
    _policyNumberCtrl.dispose();
    _coverageCtrl.dispose();
    _deductibleCtrl.dispose();
    _premiumCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPropertyId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a property')));
      return;
    }

    final policy = Policy(
      id: widget.existing?.id ?? _uuid.v4(),
      propertyId: _selectedPropertyId!,
      provider: _providerCtrl.text.trim(),
      policyNumber: _policyNumberCtrl.text.trim().isEmpty
          ? null
          : _policyNumberCtrl.text.trim(),
      coverageAmount: double.tryParse(_coverageCtrl.text),
      deductible: double.tryParse(_deductibleCtrl.text),
      premium: double.tryParse(_premiumCtrl.text),
      expiryDate: _expiryDate,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    final controller = ref.read(policyControllerProvider.notifier);
    final ok = _isEdit
        ? await controller.edit(policy)
        : await controller.add(policy);

    if (ok && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(propertiesProvider);
    final fmt = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Policy' : 'Add Policy')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: OhSpacing.insetMd,
          children: [
            // Provider
            TextFormField(
              controller: _providerCtrl,
              decoration: const InputDecoration(
                labelText: 'Insurance provider',
                hintText: 'e.g. State Farm, Allstate',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Provider is required' : null,
            ),
            const SizedBox(height: OhSpacing.md),

            // Policy number
            TextFormField(
              controller: _policyNumberCtrl,
              decoration: const InputDecoration(
                labelText: 'Policy number (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: OhSpacing.md),

            // Coverage
            TextFormField(
              controller: _coverageCtrl,
              decoration: const InputDecoration(
                labelText: 'Coverage limit (optional)',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: OhSpacing.md),

            // Deductible + Premium row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _deductibleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Deductible',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _premiumCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Annual premium',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: OhSpacing.md),

            // Property dropdown
            propertiesAsync.when(
              data: (properties) => DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Property',
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedPropertyId,
                items: properties
                    .map(
                      (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedPropertyId = v),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('Failed to load properties'),
            ),
            const SizedBox(height: OhSpacing.md),

            // Expiry date
            ListTile(
              title: const Text('Expiry date (optional)'),
              subtitle: Text(
                _expiryDate != null ? fmt.format(_expiryDate!) : 'Not set',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_expiryDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _expiryDate = null),
                    ),
                  const Icon(Icons.calendar_today),
                ],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: OhRadii.lg,
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              onTap: _pickExpiry,
            ),
            const SizedBox(height: OhSpacing.lg),

            FilledButton(
              onPressed: _save,
              child: Text(_isEdit ? 'Save Changes' : 'Add Policy'),
            ),
          ],
        ),
      ),
    );
  }
}
