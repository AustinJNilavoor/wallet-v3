import 'package:wallet/core/sms_hive_boxes.dart';
import 'package:wallet/data/models/sms_template.dart';
import 'package:wallet/data/models/sms_template_hive.dart';

/// CRUD + domain<->Hive conversion for [SmsTemplate].
///
/// Callers (UI, parser) always work with the plain [SmsTemplate]
/// domain model; this repository is the only place that touches
/// [SmsTemplateHive] / the Hive box directly.
class SmsTemplateRepository {
  List<SmsTemplate> getAll() {
    return SmsHiveBoxes.templates.values.map((h) => h.toDomain()).toList();
  }

  List<SmsTemplate> getEnabled() {
    return getAll().where((t) => t.enabled).toList();
  }

  SmsTemplate? getById(String id) {
    return SmsHiveBoxes.templates.get(id)?.toDomain();
  }

  /// Finds the first enabled template whose sender pattern matches
  /// [sender].
  SmsTemplate? findMatchingTemplate(String sender) {
    for (final hive in SmsHiveBoxes.templates.values) {
      if (!hive.enabled) continue;
      if (hive.toDomain().matchesSender(sender)) {
        return hive.toDomain();
      }
    }
    return null;
  }

  Future<void> save(SmsTemplate template) async {
    final box = SmsHiveBoxes.templates;
    final existing = box.get(template.id);

    if (existing != null) {
      existing.updateFromDomain(template);
      await existing.save();
    } else {
      await box.put(template.id, SmsTemplateHive.fromDomain(template));
    }
  }

  Future<void> delete(String id) async {
    await SmsHiveBoxes.templates.delete(id);
  }

  Future<void> setEnabled(String id, bool enabled) async {
    final hive = SmsHiveBoxes.templates.get(id);
    if (hive == null) return;
    hive.enabled = enabled;
    await hive.save();
  }
}