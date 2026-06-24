import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/notification_providers.dart';
import '../../domain/entities/loan.dart';
import '../controllers/loan_controller.dart';

/// Bottom-sheet form for recording a new loan or editing an existing one.
class AddLoanSheet extends ConsumerStatefulWidget {
  const AddLoanSheet({
    super.key,
    required this.itemId,
    required this.itemName,
    this.editingLoan,
  });

  final String itemId;
  final String itemName;

  /// When non-null, the form pre-fills with this loan's data and calls
  /// [LoanController.editLoan] on submit instead of [LoanController.lend].
  final Loan? editingLoan;

  @override
  ConsumerState<AddLoanSheet> createState() => _AddLoanSheetState();
}

class _AddLoanSheetState extends ConsumerState<AddLoanSheet> {
  final _formKey = GlobalKey<FormState>();
  final _borrowerController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _expectedReturnDate;
  static final _dateFmt = DateFormat.yMMMd();

  @override
  void initState() {
    super.initState();
    final loan = widget.editingLoan;
    if (loan != null) {
      _borrowerController.text = loan.borrowerName;
      _notesController.text = loan.notes ?? '';
      _expectedReturnDate = loan.expectedReturnDate;
    }
  }

  @override
  void dispose() {
    _borrowerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedReturnDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _expectedReturnDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final editing = widget.editingLoan;
    final loan = Loan(
      id: editing?.id ?? const Uuid().v4(),
      itemId: widget.itemId,
      itemName: widget.itemName,
      borrowerName: _borrowerController.text.trim(),
      expectedReturnDate: _expectedReturnDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      returnedAt: editing?.returnedAt,
      createdAt: editing?.createdAt ?? now,
      modifiedAt: now,
    );

    final notifier = ref.read(loanControllerProvider.notifier);
    if (editing != null) {
      await notifier.editLoan(loan);
    } else {
      await notifier.lend(loan);
      if (_expectedReturnDate != null) {
        await ref
            .read(notificationServiceProvider)
            .scheduleLoanReminder(
              loanId: loan.id,
              itemName: widget.itemName,
              dueDate: _expectedReturnDate!,
            );
      }
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingLoan != null;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing ? 'Edit Loan' : 'Lend "${widget.itemName}"',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _borrowerController,
              decoration: const InputDecoration(
                labelText: 'Borrower name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Borrower name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(
                _expectedReturnDate == null
                    ? 'No return date set'
                    : 'Due: ${_dateFmt.format(_expectedReturnDate!)}',
              ),
              trailing: _expectedReturnDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () =>
                          setState(() => _expectedReturnDate = null),
                    )
                  : null,
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submit,
              child: Text(isEditing ? 'Save' : 'Lend'),
            ),
          ],
        ),
      ),
    );
  }
}
