import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:wallet/core/boxes.dart';
import 'package:wallet/core/category_icons.dart';
import 'package:wallet/core/source_icons.dart';
import 'package:wallet/data/models/category.dart';
import 'package:wallet/data/models/sms_category_mapping.dart';
import 'package:wallet/data/models/sms_template.dart';
import 'package:wallet/data/models/source.dart';
import 'package:wallet/presentation/widgets/delete_dialog.dart';

class SmsMappingEditorScreen extends StatefulWidget {
  final SmsCategoryMapping? mapping;

  const SmsMappingEditorScreen({super.key, this.mapping});

  bool get isEditing => mapping != null;

  @override
  State<SmsMappingEditorScreen> createState() =>
      _SmsMappingEditorScreenState();
}

class _SmsMappingEditorScreenState extends State<SmsMappingEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _templateId;
  SmsMappingField _field = SmsMappingField.merchant;
  SmsMappingOperator _operator = SmsMappingOperator.contains;

  bool _setsTransfer = false;
  String? _categoryId;
  String? _sourceId;
  String? _destinationSourceId;

  int _priority = 0;
  bool _enabled = true;

  @override
  void initState() {
    super.initState();

    final mapping = widget.mapping;

    if (mapping != null) {
      _valueController.text = mapping.value;
      _descriptionController.text = mapping.description ?? '';
      _templateId = mapping.templateId;
      _field = mapping.field;
      _operator = mapping.operator;
      _categoryId = mapping.categoryId;
      _sourceId = mapping.sourceId;
      _destinationSourceId = mapping.destinationSourceId;
      _setsTransfer = mapping.destinationSourceId != null;
      _priority = mapping.priority;
      _enabled = mapping.enabled;
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Mapping' : 'New Mapping'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Example: Swiggy orders \u2192 Food',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            _buildTemplateDropdown(),

            const SizedBox(height: 20),

            Text(
              'Match condition',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<SmsMappingField>(
                    value: _field,
                    decoration: const InputDecoration(
                      labelText: 'Field',
                      border: OutlineInputBorder(),
                    ),
                    items: SmsMappingField.values
                        .map(
                          (f) => DropdownMenuItem(
                            value: f,
                            child: Text(_fieldLabel(f)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _field = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<SmsMappingOperator>(
                    value: _operator,
                    decoration: const InputDecoration(
                      labelText: 'Operator',
                      border: OutlineInputBorder(),
                    ),
                    items: SmsMappingOperator.values
                        .map(
                          (o) => DropdownMenuItem(
                            value: o,
                            child: Text(_operatorLabel(o)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _operator = value);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _valueController,
              decoration: const InputDecoration(
                labelText: 'Value',
                hintText: 'Example: swiggy',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a value to match against';
                }
                if (_operator == SmsMappingOperator.regex) {
                  try {
                    RegExp(value);
                  } catch (_) {
                    return 'Invalid regular expression';
                  }
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            Text(
              'Result',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('This is a transfer'),
              subtitle: const Text(
                'Sets a source + destination instead of a category',
              ),
              value: _setsTransfer,
              onChanged: (value) {
                setState(() {
                  _setsTransfer = value;
                  if (!value) _destinationSourceId = null;
                });
              },
            ),

            const SizedBox(height: 8),

            _buildSourceDropdown(
              label: _setsTransfer
                  ? 'From Source (optional)'
                  : 'Source (optional)',
              value: _sourceId,
              onChanged: (value) => setState(() => _sourceId = value),
            ),

            if (_setsTransfer) ...[
              const SizedBox(height: 12),
              _buildSourceDropdown(
                label: 'To Source (optional)',
                value: _destinationSourceId,
                onChanged: (value) =>
                    setState(() => _destinationSourceId = value),
              ),
            ] else ...[
              const SizedBox(height: 12),
              _buildCategoryDropdown(),
            ],

            const SizedBox(height: 20),

            DropdownButtonFormField<int>(
              value: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                helperText: 'Higher priority rules are applied first',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Normal')),
                DropdownMenuItem(value: 1, child: Text('High')),
                DropdownMenuItem(value: 2, child: Text('Very High')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _priority = value);
              },
            ),

            const SizedBox(height: 8),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enabled'),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),

            const SizedBox(height: 24),

            FilledButton(
              onPressed: _save,
              child: Text(
                widget.isEditing ? 'Save Changes' : 'Create Mapping',
              ),
            ),

            if (widget.isEditing) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Delete Mapping',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateDropdown() {
    final templates = Boxes.getSmsTemplates().values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final validValue = templates.any((t) => t.id == _templateId)
        ? _templateId
        : null;

    return DropdownButtonFormField<String?>(
      value: validValue,
      decoration: const InputDecoration(
        labelText: 'Template',
        helperText: 'Leave as "Any template" to match every SMS',
        border: OutlineInputBorder(),
      ),
      isExpanded: true,
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Any template'),
        ),
        ...templates.map(
          (SmsTemplate t) =>
              DropdownMenuItem<String?>(value: t.id, child: Text(t.name)),
        ),
      ],
      onChanged: (value) => setState(() => _templateId = value),
    );
  }

  Widget _buildSourceDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final sources = Boxes.getSources().values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final validValue = sources.any((s) => s.id == value) ? value : null;

    return DropdownButtonFormField<String?>(
      value: validValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      isExpanded: true,
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('None')),
        ...sources.map(
          (Source s) => DropdownMenuItem<String?>(
            value: s.id,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(SourceIcons.icons[s.iconIndex], size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(s.name, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = Boxes.getCategories().values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final validValue = categories.any((c) => c.id == _categoryId)
        ? _categoryId
        : null;

    return DropdownButtonFormField<String?>(
      value: validValue,
      decoration: const InputDecoration(
        labelText: 'Category (optional)',
        border: OutlineInputBorder(),
      ),
      isExpanded: true,
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('None')),
        ...categories.map(
          (Category c) => DropdownMenuItem<String?>(
            value: c.id,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CategoryIcons.icons[c.iconIndex], size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(c.name, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
      ],
      onChanged: (value) => setState(() => _categoryId = value),
    );
  }

  String _fieldLabel(SmsMappingField field) {
    switch (field) {
      case SmsMappingField.account:
        return 'Account';
      case SmsMappingField.merchant:
        return 'Merchant';
      case SmsMappingField.reference:
        return 'Reference';
      case SmsMappingField.description:
        return 'Description';
      case SmsMappingField.sender:
        return 'Sender';
      case SmsMappingField.amount:
        return 'Amount';
      case SmsMappingField.custom:
        return 'Custom field';
    }
  }

  String _operatorLabel(SmsMappingOperator operator) {
    switch (operator) {
      case SmsMappingOperator.equals:
        return 'Equals';
      case SmsMappingOperator.contains:
        return 'Contains';
      case SmsMappingOperator.startsWith:
        return 'Starts with';
      case SmsMappingOperator.endsWith:
        return 'Ends with';
      case SmsMappingOperator.regex:
        return 'Regex';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final mapping =
        (widget.mapping ??
                SmsCategoryMapping(
                  id: const Uuid().v4(),
                  field: _field,
                  operator: _operator,
                  value: '',
                ))
            .copyWith(
              templateId: _templateId,
              field: _field,
              operator: _operator,
              value: _valueController.text.trim(),
              categoryId: _setsTransfer ? null : _categoryId,
              sourceId: _sourceId,
              destinationSourceId: _setsTransfer ? _destinationSourceId : null,
              priority: _priority,
              enabled: _enabled,
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
            );

    await Boxes.getSmsCategoryMappings().put(mapping.id, mapping);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final mapping = widget.mapping;
    if (mapping == null) return;

    final confirm = await DeleteDialog.show(
      context,
      title: 'Delete Mapping',
      message: 'Delete this mapping rule?',
    );

    if (!confirm) return;

    await Boxes.getSmsCategoryMappings().delete(mapping.id);

    if (!mounted) return;
    Navigator.pop(context, true);
  }
}
