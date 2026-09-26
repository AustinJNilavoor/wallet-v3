import 'package:flutter/material.dart';

import 'package:wallet/core/boxes.dart';
import 'package:wallet/data/models/sms_category_mapping.dart';
import 'package:wallet/data/models/sms_template.dart';

/// Renders the list of [SmsCategoryMapping] rules configured by the
/// user, each mapped to a real Category/Source name (not a hardcoded
/// placeholder).
class SmsMappingTable extends StatelessWidget {
  final List<SmsCategoryMapping> mappings;
  final VoidCallback onAdd;
  final ValueChanged<SmsCategoryMapping> onEdit;
  final ValueChanged<SmsCategoryMapping> onDelete;

  const SmsMappingTable({
    super.key,
    required this.mappings,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (mappings.isEmpty) {
      return _emptyState(context);
    }

    final sorted = [...mappings]
      ..sort((a, b) => b.priority.compareTo(a.priority));

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Mapping'),
          ),
        ),

        const SizedBox(height: 12),

        ...sorted.map((mapping) => _mappingCard(context, mapping)),
      ],
    );
  }

  Widget _mappingCard(BuildContext context, SmsCategoryMapping mapping) {
    final category = mapping.categoryId != null
        ? Boxes.getCategories().get(mapping.categoryId)
        : null;

    final source = mapping.sourceId != null
        ? Boxes.getSources().get(mapping.sourceId)
        : null;

    final destination = mapping.destinationSourceId != null
        ? Boxes.getSources().get(mapping.destinationSourceId)
        : null;

    final template = mapping.templateId != null
        ? Boxes.getSmsTemplates().get(mapping.templateId)
        : null;

    final resultParts = <String>[
      if (category != null) 'Category: ${category.name}',
      if (source != null) 'Source: ${source.name}',
      if (destination != null) 'To: ${destination.name}',
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        enabled: mapping.enabled,
        leading: const Icon(Icons.account_tree_outlined),
        title: Text(
          mapping.description?.isNotEmpty == true
              ? mapping.description!
              : '${_fieldLabel(mapping.field)} '
                    '${_operatorLabel(mapping.operator)} "${mapping.value}"',
        ),
        subtitle: Text(
          [
            if (template != null) 'Template: ${template.name}',
            if (resultParts.isNotEmpty) resultParts.join(' · '),
            if (!mapping.enabled) 'Disabled',
          ].join('\n'),
        ),
        isThreeLine:
            (template != null ? 1 : 0) + (resultParts.isNotEmpty ? 1 : 0) > 1,
        trailing: PopupMenuButton<String>(
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              onEdit(mapping);
            } else if (value == 'delete') {
              onDelete(mapping);
            }
          },
        ),
        onTap: () => onEdit(mapping),
      ),
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
        return 'equals';
      case SmsMappingOperator.contains:
        return 'contains';
      case SmsMappingOperator.startsWith:
        return 'starts with';
      case SmsMappingOperator.endsWith:
        return 'ends with';
      case SmsMappingOperator.regex:
        return 'matches';
    }
  }

  Widget _emptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          const Icon(Icons.account_tree_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('No mappings configured'),
          const SizedBox(height: 4),
          const Text(
            'Mappings automatically fill in the category and source '
            'for matched SMS based on their content.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Mapping'),
          ),
        ],
      ),
    );
  }
}
