import 'package:hive/hive.dart';

import 'package:wallet/core/boxes.dart';
import 'package:wallet/data/models/sms_template.dart';
import 'package:wallet/data/models/sms_template_field.dart';

/// Thin data-access layer around the `sms_templates` and
/// `sms_template_fields` Hive boxes.
///
/// A [SmsTemplate] and its [SmsTemplateField]s are stored in two
/// separate boxes (fields reference their template via [SmsTemplateField.templateId]
/// rather than being nested Hive objects), so every write/delete that
/// touches a template also needs to keep its fields in sync. This
/// repository is the single place that does that bookkeeping.
class SmsTemplateRepository {
  SmsTemplateRepository({
    Box<SmsTemplate>? templateBox,
    Box<SmsTemplateField>? fieldBox,
  }) : _templateBox = templateBox ?? Boxes.getSmsTemplates(),
       _fieldBox = fieldBox ?? Boxes.getSmsTemplateFields();

  final Box<SmsTemplate> _templateBox;
  final Box<SmsTemplateField> _fieldBox;

  List<SmsTemplate> getAllTemplates() {
    final templates = _templateBox.values.toList();
    templates.sort((a, b) => b.priority.compareTo(a.priority));
    return templates;
  }

  SmsTemplate? getTemplate(String id) => _templateBox.get(id);

  List<SmsTemplateField> getFieldsForTemplate(String templateId) {
    final fields = _fieldBox.values
        .where((field) => field.templateId == templateId)
        .toList();

    fields.sort((a, b) => a.order.compareTo(b.order));
    return fields;
  }

  int fieldCountForTemplate(String templateId) {
    return _fieldBox.values.where((f) => f.templateId == templateId).length;
  }

  /// Persists [template] together with the fields currently
  /// associated with it, replacing any previously stored fields for
  /// that template that are no longer present in [fields].
  Future<void> saveTemplateWithFields({
    required SmsTemplate template,
    required List<SmsTemplateField> fields,
  }) async {
    // Remove fields that used to belong to this template but were
    // deleted in the editor.
    final existingIds = _fieldBox.values
        .where((f) => f.templateId == template.id)
        .map((f) => f.id)
        .toSet();

    final keptIds = fields.map((f) => f.id).toSet();

    final removedIds = existingIds.difference(keptIds);

    for (final id in removedIds) {
      await _fieldBox.delete(id);
    }

    // Persist current fields with an up-to-date order.
    for (var i = 0; i < fields.length; i++) {
      final field = fields[i].copyWith(
        templateId: template.id,
        order: i,
      );
      await _fieldBox.put(field.id, field);
    }

    final updatedTemplate = template.copyWith(
      fieldIds: fields.map((f) => f.id).toList(),
      updatedAt: DateTime.now(),
    );

    await _templateBox.put(updatedTemplate.id, updatedTemplate);
  }

  Future<void> deleteTemplate(String id) async {
    final fieldIds = _fieldBox.values
        .where((f) => f.templateId == id)
        .map((f) => f.id)
        .toList();

    for (final fieldId in fieldIds) {
      await _fieldBox.delete(fieldId);
    }

    await _templateBox.delete(id);
  }

  Future<void> setEnabled(String id, bool enabled) async {
    final template = _templateBox.get(id);
    if (template == null) return;

    template.enabled = enabled;
    template.updatedAt = DateTime.now();
    await template.save();
  }
}
