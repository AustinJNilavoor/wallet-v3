import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:wallet/core/boxes.dart';
import 'package:wallet/core/category_icons.dart';
import 'package:wallet/core/source_icons.dart';
import 'package:wallet/data/models/category.dart';
import 'package:wallet/data/models/pending_transaction.dart';
import 'package:wallet/data/models/source.dart';
import 'package:wallet/data/models/transaction_type.dart';
import 'package:wallet/presentation/widgets/type_selector.dart';
import 'package:wallet/services/sms/pending_transaction_service.dart';

class PendingTransactionReviewSheet extends StatefulWidget {
  final PendingTransaction transaction;

  final Future<PendingApprovalResult> Function(PendingTransaction transaction)
  onApprove;

  final Future<void> Function(PendingTransaction transaction) onReject;

  const PendingTransactionReviewSheet({
    super.key,
    required this.transaction,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<PendingTransactionReviewSheet> createState() =>
      _PendingTransactionReviewSheetState();
}

class _PendingTransactionReviewSheetState
    extends State<PendingTransactionReviewSheet> {
  late TextEditingController amountController;
  late TextEditingController merchantController;
  late TextEditingController accountController;
  late TextEditingController descriptionController;

  late TransactionType _type;
  String? _categoryId;
  String? _sourceId;
  String? _destinationSourceId;

  bool _isSubmitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();

    final transaction = widget.transaction;

    amountController = TextEditingController(
      text: transaction.amount?.toString() ?? '',
    );

    merchantController = TextEditingController(
      text: transaction.merchant ?? '',
    );

    accountController = TextEditingController(
      text: transaction.accountNumber ?? '',
    );

    descriptionController = TextEditingController(
      text: transaction.description ?? '',
    );

    _type = _parseType(transaction.transactionType);
    _categoryId = transaction.categoryId;
    _sourceId = transaction.sourceId;
    _destinationSourceId = transaction.destinationSourceId;
  }

  TransactionType _parseType(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'income':
      case 'credit':
      case 'credited':
        return TransactionType.income;
      case 'transfer':
        return TransactionType.transfer;
      default:
        return TransactionType.expense;
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    merchantController.dispose();
    accountController.dispose();
    descriptionController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final isTransfer = _type == TransactionType.transfer;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Review Transaction',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              TypeSelector(
                selectedType: _type,
                onChanged: (type) {
                  setState(() {
                    _type = type;
                    if (type == TransactionType.transfer) {
                      _categoryId = null;
                    } else {
                      _destinationSourceId = null;
                    }
                  });
                },
              ),

              const SizedBox(height: 16),

              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              _buildSourceDropdown(
                label: isTransfer ? 'From Source' : 'Source',
                value: _sourceId,
                onChanged: (value) => setState(() => _sourceId = value),
              ),

              if (isTransfer) ...[
                const SizedBox(height: 12),
                _buildSourceDropdown(
                  label: 'To Source',
                  value: _destinationSourceId,
                  onChanged: (value) =>
                      setState(() => _destinationSourceId = value),
                ),
              ] else ...[
                const SizedBox(height: 12),
                _buildCategoryDropdown(),
              ],

              const SizedBox(height: 12),

              TextField(
                controller: merchantController,
                decoration: const InputDecoration(
                  labelText: 'Merchant',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: accountController,
                decoration: const InputDecoration(
                  labelText: 'Account',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description / Note',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              const _SectionTitle(title: 'SMS'),

              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Text(
                  transaction.rawMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),

              const SizedBox(height: 20),

              if (transaction.missingFields.isNotEmpty)
                _WarningBox(fields: transaction.missingFields),

              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).colorScheme.errorContainer,
                  ),
                  child: Text(
                    _errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              setState(() => _isSubmitting = true);

                              await widget.onReject(transaction);

                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                      child: const Text('Reject'),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _handleApprove,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return ValueListenableBuilder<Box<Source>>(
      valueListenable: Boxes.getSources().listenable(),
      builder: (context, box, _) {
        final sources = box.values.toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        final validValue = sources.any((s) => s.id == value) ? value : null;

        return DropdownButtonFormField<String>(
          value: validValue,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          isExpanded: true,
          items: sources
              .map(
                (s) => DropdownMenuItem(
                  value: s.id,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(SourceIcons.icons[s.iconIndex], size: 18),
                      const SizedBox(width: 8),
                      Flexible(child: Text(s.name, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        );
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return ValueListenableBuilder<Box<Category>>(
      valueListenable: Boxes.getCategories().listenable(),
      builder: (context, box, _) {
        final categories = box.values.toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        final validValue = categories.any((c) => c.id == _categoryId)
            ? _categoryId
            : null;

        return DropdownButtonFormField<String>(
          value: validValue,
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
          ),
          isExpanded: true,
          items: categories
              .map(
                (c) => DropdownMenuItem(
                  value: c.id,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CategoryIcons.icons[c.iconIndex], size: 18),
                      const SizedBox(width: 8),
                      Flexible(child: Text(c.name, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _categoryId = value),
        );
      },
    );
  }

  Future<void> _handleApprove() async {
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    _applyEditsToTransaction();

    final result = await widget.onApprove(widget.transaction);

    if (!mounted) return;

    if (result.success) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isSubmitting = false;
      _errorText = result.error ?? 'Could not approve this transaction.';
    });
  }

  void _applyEditsToTransaction() {
    final amount = double.tryParse(
      amountController.text.trim().replaceAll(',', ''),
    );

    widget.transaction
      ..amount = amount
      ..merchant = merchantController.text.trim()
      ..accountNumber = accountController.text.trim()
      ..description = descriptionController.text.trim()
      ..note = descriptionController.text.trim()
      ..transactionType = _type.name
      ..sourceId = _sourceId
      ..categoryId = _type == TransactionType.transfer ? null : _categoryId
      ..destinationSourceId = _type == TransactionType.transfer
          ? _destinationSourceId
          : null;
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _WarningBox extends StatelessWidget {
  final List<String> fields;

  const _WarningBox({required this.fields});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.errorContainer,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Could not parse: ${fields.join(', ')}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
