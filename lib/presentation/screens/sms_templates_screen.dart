import 'package:flutter/material.dart';

import 'package:wallet/data/models/sms_template.dart';
import 'package:wallet/data/repositories/sms_template_repository.dart';
import 'package:wallet/presentation/screens/sms_template_editor_screen.dart';
import 'package:wallet/presentation/widgets/delete_dialog.dart';

class SmsTemplatesScreen extends StatefulWidget {
  const SmsTemplatesScreen({super.key});

  @override
  State<SmsTemplatesScreen> createState() => _SmsTemplatesScreenState();
}

class _SmsTemplatesScreenState extends State<SmsTemplatesScreen> {
  final _repository = SmsTemplateRepository();

  @override
  Widget build(BuildContext context) {
    final templates = _repository.getAllTemplates();

    return Scaffold(
      appBar: AppBar(title: const Text('SMS Templates')),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTemplate,
        child: const Icon(Icons.add),
      ),
      body: templates.isEmpty
          ? _emptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                return _templateCard(templates[index]);
              },
            ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sms_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'No SMS Templates',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a template to tell the app how to read bank SMS '
              'messages.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _createTemplate,
              icon: const Icon(Icons.add),
              label: const Text('Create Template'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _templateCard(SmsTemplate template) {
    final fieldCount = _repository.fieldCountForTemplate(template.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: template.enabled
              ? null
              : Theme.of(context).disabledColor.withValues(alpha: 0.2),
          child: const Icon(Icons.account_balance),
        ),
        title: Text(template.name),
        subtitle: Text(
          '${template.senderPattern.isEmpty ? 'Any sender' : template.senderPattern} '
          '· $fieldCount field${fieldCount == 1 ? '' : 's'}'
          '${template.enabled ? '' : ' · disabled'}',
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
                await _editTemplate(template);
                break;
              case 'toggle':
                await _repository.setEnabled(template.id, !template.enabled);
                if (mounted) setState(() {});
                break;
              case 'delete':
                await _deleteTemplate(template);
                break;
            }
          },
        ),
        onTap: () => _editTemplate(template),
      ),
    );
  }

  Future<void> _createTemplate() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SmsTemplateEditorScreen()),
    );

    if (mounted) setState(() {});
  }

  Future<void> _editTemplate(SmsTemplate template) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SmsTemplateEditorScreen(template: template),
      ),
    );

    if (mounted) setState(() {});
  }

  Future<void> _deleteTemplate(SmsTemplate template) async {
    final confirm = await DeleteDialog.show(
      context,
      title: 'Delete Template',
      message: 'Delete "${template.name}" and its fields?',
    );

    if (!confirm) return;

    await _repository.deleteTemplate(template.id);
    if (mounted) setState(() {});
  }
}
