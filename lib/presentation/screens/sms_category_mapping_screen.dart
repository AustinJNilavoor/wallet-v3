import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:wallet/core/boxes.dart';
import 'package:wallet/core/category_icons.dart';
import 'package:wallet/core/sms_hive_boxes.dart';
import 'package:wallet/data/models/sms_category_mapping_hive.dart';
import 'package:wallet/data/repository/sms_category_mapping_repository.dart';
import 'package:wallet/presentation/screens/sms_category_mapping_editor.dart';
import 'package:wallet/presentation/widgets/delete_dialog.dart';

/// Lists every keyword -> Category rule (e.g. "SWIGGY -> Food").
class SmsCategoryMappingsScreen extends StatefulWidget {
  const SmsCategoryMappingsScreen({super.key});

  @override
  State<SmsCategoryMappingsScreen> createState() =>
      _SmsCategoryMappingsScreenState();
}

class _SmsCategoryMappingsScreenState extends State<SmsCategoryMappingsScreen> {
  final _repository = SmsCategoryMappingRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Category Mappings')),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: ValueListenableBuilder<Box<SmsCategoryMappingHive>>(
        valueListenable: SmsHiveBoxes.categoryMappings.listenable(),
        builder: (context, box, _) {
          final mappings = _repository.getAll();

          if (mappings.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: mappings.length,
            itemBuilder: (context, index) => _buildTile(mappings[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No category mappings yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'e.g. map "SWIGGY" to your Food category so imported SMS '
              'auto-fill the right category.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: const Text('Add Mapping'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(SmsCategoryMappingHive mapping) {
    final category = Boxes.getCategories().get(mapping.categoryId);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        enabled: mapping.enabled,
        leading: CircleAvatar(
          child: Icon(
            category != null ? CategoryIcons.icons[category.iconIndex] : Icons.help_outline,
          ),
        ),
        title: Text(mapping.keyword),
        subtitle: Text(
          '${category?.name ?? 'Unknown category'}${mapping.enabled ? '' : ' · disabled'}',
        ),
        trailing: PopupMenuButton<String>(
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'toggle', child: Text('Enable/Disable')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                await _edit(mapping);
                break;
              case 'toggle':
                await _repository.setEnabled(mapping.id, !mapping.enabled);
                break;
              case 'delete':
                await _delete(mapping);
                break;
            }
          },
        ),
        onTap: () => _edit(mapping),
      ),
    );
  }

  Future<void> _add() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SmsCategoryMappingEditor()),
    );
  }

  Future<void> _edit(SmsCategoryMappingHive mapping) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SmsCategoryMappingEditor(mapping: mapping),
      ),
    );
  }

  Future<void> _delete(SmsCategoryMappingHive mapping) async {
    final confirm = await DeleteDialog.show(
      context,
      title: 'Delete Mapping',
      message: 'Delete the mapping for "${mapping.keyword}"?',
    );

    if (confirm) {
      await _repository.delete(mapping.id);
    }
  }
}