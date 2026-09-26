import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:wallet/data/models/sms_template_field.dart';

/// Add/edit screen for a single [SmsTemplateField].
///
/// This screen does not touch Hive directly - it simply builds and
/// returns a [SmsTemplateField] via `Navigator.pop`. Persistence is
/// handled by `SmsTemplateEditorScreen`, which owns the full list of
/// fields for the template being edited.
class SmsTemplateFieldEditor extends StatefulWidget {
  final SmsTemplateField? field;

  const SmsTemplateFieldEditor({super.key, this.field});

  @override
  State<SmsTemplateFieldEditor> createState() =>
      _SmsTemplateFieldEditorState();
}

class _SmsTemplateFieldEditorState extends State<SmsTemplateFieldEditor> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _patternController = TextEditingController();
  final _captureGroupController = TextEditingController(text: '1');
  final _defaultValueController = TextEditingController();
  final _customFieldNameController = TextEditingController();

  SmsFieldType _fieldType = SmsFieldType.amount;
  SmsExtractionType _extractionType = SmsExtractionType.regex;
  bool _required = false;

  bool get isEditing => widget.field != null;

  @override
  void initState() {
    super.initState();

    final field = widget.field;

    if (field != null) {
      _nameController.text = field.name;
      _patternController.text = field.pattern;
      _captureGroupController.text = field.captureGroup.toString();
      _defaultValueController.text = field.defaultValue ?? '';
      _customFieldNameController.text = field.customFieldName ?? '';
      _fieldType = field.fieldType;
      _extractionType = field.extractionType;
      _required = field.required;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _patternController.dispose();
    _captureGroupController.dispose();
    _defaultValueController.dispose();
    _customFieldNameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit SMS Field' : 'Add SMS Field'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Field Name',
                hintText: 'Example: amount',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter field name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<SmsFieldType>(
              value: _fieldType,
              decoration: const InputDecoration(
                labelText: 'Field Type',
                border: OutlineInputBorder(),
              ),
              items: SmsFieldType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(_fieldTypeLabel(type)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _fieldType = value);
                }
              },
            ),

            if (_fieldType == SmsFieldType.custom) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _customFieldNameController,
                decoration: const InputDecoration(
                  labelText: 'Custom Field Key',
                  hintText: 'Example: upiId',
                  helperText:
                      'Key used to store this value in the transaction\'s '
                      'custom fields map. Defaults to the field name.',
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            const SizedBox(height: 16),

            DropdownButtonFormField<SmsExtractionType>(
              value: _extractionType,
              decoration: const InputDecoration(
                labelText: 'Extraction Method',
                border: OutlineInputBorder(),
              ),
              items: SmsExtractionType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(_extractionLabel(type)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _extractionType = value);
                }
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _patternController,
              maxLines: _extractionType == SmsExtractionType.between ? 2 : 4,
              decoration: InputDecoration(
                labelText: _extractionType == SmsExtractionType.regex
                    ? 'Regular Expression'
                    : 'Extraction Pattern',
                hintText: _patternHint(),
                helperText: _patternHelperText(),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter extraction pattern';
                }

                if (_extractionType == SmsExtractionType.regex) {
                  try {
                    RegExp(value);
                  } catch (_) {
                    return 'Invalid regular expression';
                  }
                }

                if (_extractionType == SmsExtractionType.between &&
                    !value.contains('|||')) {
                  return 'Use START|||END format';
                }

                return null;
              },
            ),

            if (_extractionType == SmsExtractionType.regex) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _captureGroupController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Capture Group',
                  helperText:
                      'Usually 1 when the pattern has one (...) group',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  return int.tryParse(value.trim()) == null
                      ? 'Enter a whole number'
                      : null;
                },
              ),
            ],

            const SizedBox(height: 16),

            TextFormField(
              controller: _defaultValueController,
              decoration: const InputDecoration(
                labelText: 'Default Value (optional)',
                helperText: 'Used when extraction fails',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 8),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Required field'),
              subtitle: const Text(
                'Parsing fails if this field cannot be extracted',
              ),
              value: _required,
              onChanged: (value) {
                setState(() => _required = value);
              },
            ),

            const SizedBox(height: 24),

            FilledButton(
              onPressed: _save,
              child: const Text('Save Field'),
            ),
          ],
        ),
      ),
    );
  }

  String _fieldTypeLabel(SmsFieldType type) {
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
        return 'Regular Expression';
      case SmsExtractionType.contains:
        return 'Contains';
      case SmsExtractionType.before:
        return 'Text Before';
      case SmsExtractionType.after:
        return 'Text After';
      case SmsExtractionType.between:
        return 'Text Between';
    }
  }

  String _patternHint() {
    switch (_extractionType) {
      case SmsExtractionType.regex:
        return r'Example: Rs\.?\s*([\d,]+(?:\.\d{2})?)';
      case SmsExtractionType.contains:
        return 'Example: credited';
      case SmsExtractionType.after:
        return 'Example: INR';
      case SmsExtractionType.before:
        return 'Example: from';
      case SmsExtractionType.between:
        return 'Example: A/c |||on';
    }
  }

  String _patternHelperText() {
    if (_extractionType == SmsExtractionType.between) {
      return 'This pattern is applied to the SMS text. Separate the start '
          'and end markers with |||.';
    }
    return 'This pattern is applied to the SMS text';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final captureGroup =
        int.tryParse(_captureGroupController.text.trim()) ?? 1;

    final field = (widget.field ??
            SmsTemplateField(
              id: const Uuid().v4(),
              templateId: '',
              name: '',
              fieldType: _fieldType,
              extractionType: _extractionType,
              pattern: '',
            ))
        .copyWith(
      name: _nameController.text.trim(),
      fieldType: _fieldType,
      extractionType: _extractionType,
      pattern: _patternController.text.trim(),
      captureGroup: captureGroup,
      required: _required,
      defaultValue: _defaultValueController.text.trim().isEmpty
          ? null
          : _defaultValueController.text.trim(),
      customFieldName: _customFieldNameController.text.trim().isEmpty
          ? null
          : _customFieldNameController.text.trim(),
    );

    Navigator.pop(context, field);
  }
}
