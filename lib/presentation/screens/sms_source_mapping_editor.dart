import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:wallet/core/boxes.dart';
import 'package:wallet/core/source_icons.dart';
import 'package:wallet/data/models/sms_source_mapping_hive.dart';
import 'package:wallet/data/models/source.dart';
import 'package:wallet/data/repository/sms_source_mapping_repository.dart';
import 'package:wallet/presentation/widgets/delete_dialog.dart';

/// Add/edit a single sender-pattern -> Source rule, e.g.
/// "HDFCBK" -> HDFC Bank.
class SmsSourceMappingEditor extends StatefulWidget {
  final SmsSourceMappingHive? mapping;

  const SmsSourceMappingEditor({super.key, this.mapping});

  bool get isEditing => mapping != null;

  @override
  State<SmsSourceMappingEditor> createState() =>
      _SmsSourceMappingEditorState();
}

class _SmsSourceMappingEditorState extends State<SmsSourceMappingEditor> {
  final _formKey = GlobalKey<FormState>();
  final _repository = SmsSourceMappingRepository();
  final _senderController = TextEditingController();

  String? _sourceId;
  bool _enabled = true;

  @override
  void initState() {
    super.initState();

    final mapping = widget.mapping;
    if (mapping != null) {
      _senderController.text = mapping.senderPattern;
      _sourceId = mapping.sourceId;
      _enabled = mapping.enabled;
    }
  }

  @override
  void dispose() {
    _senderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Source Mapping' : 'New Source Mapping'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _senderController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Sender Pattern',
                hintText: 'e.g. HDFCBK',
                helperText:
                    'Compared against the normalized sender id (the DLT '
                    'operator prefix, like "AX-"/"AD-", is stripped '
                    'automatically before matching).',
                helperMaxLines: 3,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a sender pattern';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            _buildSourceDropdown(),

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
              child: Text(widget.isEditing ? 'Save Changes' : 'Create Mapping'),
            ),

            if (widget.isEditing) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Delete Mapping', style: TextStyle(color: Colors.red)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSourceDropdown() {
    final sources = Boxes.getSources().values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final validValue = sources.any((s) => s.id == _sourceId) ? _sourceId : null;

    return DropdownButtonFormField<String>(
      value: validValue,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Source',
        border: OutlineInputBorder(),
      ),
      items: sources
          .map(
            (Source s) => DropdownMenuItem(
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
      onChanged: (value) => setState(() => _sourceId = value),
      validator: (value) => value == null ? 'Select a source' : null,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final mapping = widget.mapping?.copyWith(
          senderPattern: _senderController.text.trim(),
          sourceId: _sourceId,
          enabled: _enabled,
        ) ??
        SmsSourceMappingHive(
          id: const Uuid().v4(),
          senderPattern: _senderController.text.trim(),
          sourceId: _sourceId!,
          enabled: _enabled,
        );

    await _repository.save(mapping);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final mapping = widget.mapping;
    if (mapping == null) return;

    final confirm = await DeleteDialog.show(
      context,
      title: 'Delete Mapping',
      message: 'Delete the mapping for "${mapping.senderPattern}"?',
    );

    if (!confirm) return;

    await _repository.delete(mapping.id);

    if (!mounted) return;
    Navigator.pop(context, true);
  }
}