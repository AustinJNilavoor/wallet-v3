import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:wallet/core/boxes.dart';
import 'package:wallet/data/models/sms_category_mapping.dart';
import 'package:wallet/presentation/screens/sms_mapping_editor_screen.dart';
import 'package:wallet/presentation/widgets/delete_dialog.dart';
import 'package:wallet/presentation/widgets/sms_mapping_table.dart';

/// Lets the user configure rules that automatically fill in the
/// category and/or source for a matched SMS, based on its content
/// (merchant, account, sender, etc).
class SmsMappingsScreen extends StatefulWidget {
  const SmsMappingsScreen({super.key});

  @override
  State<SmsMappingsScreen> createState() => _SmsMappingsScreenState();
}

class _SmsMappingsScreenState extends State<SmsMappingsScreen> {
  @override
  Widget build(BuildContext context) {
    final box = Boxes.getSmsCategoryMappings();

    return Scaffold(
      appBar: AppBar(title: const Text('SMS Mappings')),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<SmsCategoryMapping> box, _) {
          final mappings = box.values.toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SmsMappingTable(
              mappings: mappings,
              onAdd: _addMapping,
              onEdit: _editMapping,
              onDelete: _deleteMapping,
            ),
          );
        },
      ),
    );
  }

  Future<void> _addMapping() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SmsMappingEditorScreen()),
    );
  }

  Future<void> _editMapping(SmsCategoryMapping mapping) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SmsMappingEditorScreen(mapping: mapping),
      ),
    );
  }

  Future<void> _deleteMapping(SmsCategoryMapping mapping) async {
    final confirm = await DeleteDialog.show(
      context,
      title: 'Delete Mapping',
      message: 'Delete this mapping rule?',
    );

    if (confirm) {
      await Boxes.getSmsCategoryMappings().delete(mapping.id);
    }
  }
}
