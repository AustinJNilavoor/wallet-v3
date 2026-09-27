import 'package:wallet/core/sms_hive_boxes.dart';
import 'package:wallet/data/models/sms_pattern_builder.dart';
import 'package:wallet/data/models/sms_source_mapping_hive.dart';

/// CRUD for sender-pattern -> Source mappings.
class SmsSourceMappingRepository {
  List<SmsSourceMappingHive> getAll() {
    final list = SmsHiveBoxes.sourceMappings.values.toList();
    list.sort(
      (a, b) =>
          a.senderPattern.toLowerCase().compareTo(b.senderPattern.toLowerCase()),
    );
    return list;
  }

  Future<void> save(SmsSourceMappingHive mapping) async {
    await SmsHiveBoxes.sourceMappings.put(mapping.id, mapping);
  }

  Future<void> delete(String id) async {
    await SmsHiveBoxes.sourceMappings.delete(id);
  }

  Future<void> setEnabled(String id, bool enabled) async {
    final mapping = SmsHiveBoxes.sourceMappings.get(id);
    if (mapping == null) return;
    mapping.enabled = enabled;
    await mapping.save();
  }

  /// Finds the sourceId for a raw SMS [sender], normalizing it first
  /// (stripping the DLT operator prefix) before comparing.
  String? resolveSourceId(String sender) {
    final normalized = SmsPatternBuilder.defaultSenderPattern(
      sender,
    ).toLowerCase();

    final enabled = SmsHiveBoxes.sourceMappings.values.where(
      (m) => m.enabled,
    );

    for (final mapping in enabled) {
      if (mapping.senderPattern.toLowerCase() == normalized) {
        return mapping.sourceId;
      }
    }

    // Fall back to a looser "contains" match either direction, in
    // case the stored pattern is a partial fragment.
    for (final mapping in enabled) {
      final pattern = mapping.senderPattern.toLowerCase();
      if (normalized.contains(pattern) || pattern.contains(normalized)) {
        return mapping.sourceId;
      }
    }

    return null;
  }
}