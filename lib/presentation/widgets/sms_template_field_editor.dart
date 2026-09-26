import 'package:flutter/material.dart';

import 'package:wallet/data/models/sms_template_field.dart';

/// Compact summary row for one [SmsTemplateField], used inside the
/// SMS template editor's field list.
///
/// This intentionally only *displays* the field - editing happens in
/// `SmsTemplateFieldEditor` (presentation/screens), which is pushed
/// from the edit button.
class SmsTemplateFieldTile extends StatelessWidget {
  final SmsTemplateField field;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SmsTemplateFieldTile({
    super.key,
    required this.field,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(_iconFor(field.fieldType)),
        ),
        title: Text(field.name.isEmpty ? _labelFor(field.fieldType) : field.name),
        subtitle: Text(
          '${_labelFor(field.fieldType)} · ${_extractionLabel(field.extractionType)}'
          '${field.required ? ' · required' : ''}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(SmsFieldType type) {
    switch (type) {
      case SmsFieldType.amount:
        return Icons.currency_rupee;
      case SmsFieldType.date:
        return Icons.calendar_today;
      case SmsFieldType.merchant:
        return Icons.storefront;
      case SmsFieldType.account:
        return Icons.account_balance;
      case SmsFieldType.reference:
        return Icons.confirmation_number_outlined;
      case SmsFieldType.balance:
        return Icons.account_balance_wallet_outlined;
      case SmsFieldType.description:
        return Icons.notes;
      case SmsFieldType.transactionType:
        return Icons.compare_arrows;
      case SmsFieldType.custom:
        return Icons.data_object;
    }
  }

  String _labelFor(SmsFieldType type) {
    switch (type) {
      case SmsFieldType.amount:
        return 'Amount';
      case SmsFieldType.date:
        return 'Date';
      case SmsFieldType.merchant:
        return 'Merchant';
      case SmsFieldType.account:
        return 'Account';
      case SmsFieldType.reference:
        return 'Reference';
      case SmsFieldType.balance:
        return 'Balance';
      case SmsFieldType.description:
        return 'Description';
      case SmsFieldType.transactionType:
        return 'Transaction Type';
      case SmsFieldType.custom:
        return 'Custom';
    }
  }

  String _extractionLabel(SmsExtractionType type) {
    switch (type) {
      case SmsExtractionType.regex:
        return 'Regex';
      case SmsExtractionType.contains:
        return 'Contains';
      case SmsExtractionType.before:
        return 'Before';
      case SmsExtractionType.after:
        return 'After';
      case SmsExtractionType.between:
        return 'Between';
    }
  }
}
