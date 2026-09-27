import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:wallet/core/boxes.dart';
import 'package:wallet/core/category_icons.dart';
import 'package:wallet/data/models/category.dart';
import 'package:wallet/data/models/sms_category_mapping_hive.dart';
import 'package:wallet/data/repository/sms_category_mapping_repository.dart';
import 'package:wallet/presentation/widgets/delete_dialog.dart';

/// Add/edit a single keyword -> Category rule, e.g. "SWIGGY" -> Food.
class SmsCategoryMappingEditor extends StatefulWidget {
  final SmsCategoryMappingHive? mapping;

  const SmsCategoryMappingEditor({super.key, this.mapping});

  bool get isEditing => mapping != null;

  @override
  State<SmsCategoryMappingEditor> createState() =>
      _SmsCategoryMappingEditorState();
}

class _SmsCategoryMappingEditorState extends State<SmsCategoryMappingEditor> {
  final _formKey = GlobalKey<FormState>();
  final _repository = SmsCategoryMappingRepository();
  final _keywordController = TextEditingController();

  String? _categoryId;
  bool _enabled = true;

  @override
  void initState() {
    super.initState();

    final mapping = widget.mapping;
    if (mapping != null) {
      _keywordController.text = mapping.keyword;
      _categoryId = mapping.categoryId;
      _enabled = mapping.enabled;
    }
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Category Mapping' : 'New Category Mapping'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _keywordController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Keyword',
                hintText: 'e.g. SWIGGY',
                helperText:
                    'Matched case-insensitively against the merchant/description '
                    'extracted from an SMS.',
                helperMaxLines: 2,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a keyword';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            _buildCategoryDropdown(),

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

  Widget _buildCategoryDropdown() {
    final categories = Boxes.getCategories().values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final validValue = categories.any((c) => c.id == _categoryId) ? _categoryId : null;

    return DropdownButtonFormField<String>(
      value: validValue,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
      ),
      items: categories
          .map(
            (Category c) => DropdownMenuItem(
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
      validator: (value) => value == null ? 'Select a category' : null,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final mapping = widget.mapping?.copyWith(
          keyword: _keywordController.text.trim(),
          categoryId: _categoryId,
          enabled: _enabled,
        ) ??
        SmsCategoryMappingHive(
          id: const Uuid().v4(),
          keyword: _keywordController.text.trim(),
          categoryId: _categoryId!,
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
      message: 'Delete the mapping for "${mapping.keyword}"?',
    );

    if (!confirm) return;

    await _repository.delete(mapping.id);

    if (!mounted) return;
    Navigator.pop(context, true);
  }
}