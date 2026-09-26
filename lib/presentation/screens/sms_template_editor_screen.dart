import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:wallet/data/models/sms_template.dart';
import 'package:wallet/data/models/sms_template_field.dart';
import 'package:wallet/data/repositories/sms_template_repository.dart';
import 'package:wallet/presentation/screens/sms_template_field_editor.dart';
import 'package:wallet/presentation/widgets/delete_dialog.dart';
import 'package:wallet/presentation/widgets/sms_template_field_editor.dart';

class SmsTemplateEditorScreen extends StatefulWidget {
  final SmsTemplate? template;

  const SmsTemplateEditorScreen({super.key, this.template});

  bool get isEditing => template != null;

  @override
  State<SmsTemplateEditorScreen> createState() =>
      _SmsTemplateEditorScreenState();
}

class _SmsTemplateEditorScreenState extends State<SmsTemplateEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = SmsTemplateRepository();

  final _nameController = TextEditingController();
  final _senderController = TextEditingController();
  final _keywordController = TextEditingController();
  final _sampleMessageController = TextEditingController();

  bool _enabled = true;
  int _priority = 0;

  final List<SmsTemplateField> _fields = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final template = widget.template;

    if (template != null) {
      _nameController.text = template.name;
      _senderController.text = template.senderPattern;
      _keywordController.text = template.keywords.join(', ');
      _sampleMessageController.text = template.sampleMessage ?? '';
      _enabled = template.enabled;
      _priority = template.priority;

      _fields.addAll(_repository.getFieldsForTemplate(template.id));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _senderController.dispose();
    _keywordController.dispose();
    _sampleMessageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit SMS Template' : 'New SMS Template'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Template Name',
                hintText: 'Example: HDFC Debit',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter template name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _senderController,
              decoration: const InputDecoration(
                labelText: 'Sender Pattern',
                hintText: 'Example: HDFCBK',
                helperText:
                    'Exact match, substring match or regex against the SMS sender ID',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _keywordController,
              decoration: const InputDecoration(
                labelText: 'Keywords',
                hintText: 'debit, credited, transaction',
                helperText: 'Separate multiple keywords with commas. '
                    'All keywords must appear in the SMS.',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _sampleMessageController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Sample SMS (optional)',
                helperText: 'Kept for reference while configuring fields',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<int>(
              value: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                helperText: 'Higher priority templates are checked first',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Normal')),
                DropdownMenuItem(value: 1, child: Text('High')),
                DropdownMenuItem(value: 2, child: Text('Very High')),
                DropdownMenuItem(value: 3, child: Text('Highest')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _priority = value);
                }
              },
            ),

            const SizedBox(height: 8),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enabled'),
              subtitle: const Text('Use this template while syncing SMS'),
              value: _enabled,
              onChanged: (value) {
                setState(() => _enabled = value);
              },
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Text(
                  'Fields',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addField,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Field'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (_fields.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: const Text(
                  'No fields configured.\n\n'
                  'Add fields such as amount, date, merchant, account and '
                  'reference.',
                  textAlign: TextAlign.center,
                ),
              ),

            ..._buildFields(),

            const SizedBox(height: 32),

            FilledButton(
              onPressed: _isSaving ? null : _saveTemplate,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.isEditing ? 'Save Changes' : 'Create Template'),
            ),

            if (widget.isEditing) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _deleteTemplate,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Delete Template',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFields() {
    return List.generate(_fields.length, (index) {
      final field = _fields[index];

      return SmsTemplateFieldTile(
        field: field,
        onEdit: () => _editField(field, index),
        onDelete: () {
          setState(() => _fields.removeAt(index));
        },
      );
    });
  }

  Future<void> _addField() async {
    final result = await Navigator.push<SmsTemplateField>(
      context,
      MaterialPageRoute(builder: (_) => const SmsTemplateFieldEditor()),
    );

    if (result != null) {
      setState(() => _fields.add(result));
    }
  }

  Future<void> _editField(SmsTemplateField field, int index) async {
    final result = await Navigator.push<SmsTemplateField>(
      context,
      MaterialPageRoute(
        builder: (_) => SmsTemplateFieldEditor(field: field),
      ),
    );

    if (result != null) {
      setState(() => _fields[index] = result);
    }
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final keywords = _keywordController.text
          .split(',')
          .map((k) => k.trim())
          .where((k) => k.isNotEmpty)
          .toList();

      final template =
          (widget.template ??
                  SmsTemplate(
                    id: const Uuid().v4(),
                    name: '',
                    senderPattern: '',
                  ))
              .copyWith(
                name: _nameController.text.trim(),
                senderPattern: _senderController.text.trim(),
                keywords: keywords,
                enabled: _enabled,
                priority: _priority,
                sampleMessage: _sampleMessageController.text.trim().isEmpty
                    ? null
                    : _sampleMessageController.text.trim(),
              );

      await _repository.saveTemplateWithFields(
        template: template,
        fields: _fields,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save template')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteTemplate() async {
    final template = widget.template;
    if (template == null) return;

    final confirm = await DeleteDialog.show(
      context,
      title: 'Delete Template',
      message:
          'Delete "${template.name}"? Its fields will be removed too. '
          'Already-imported transactions are not affected.',
    );

    if (!confirm) return;

    await _repository.deleteTemplate(template.id);

    if (!mounted) return;
    Navigator.pop(context, true);
  }
}
