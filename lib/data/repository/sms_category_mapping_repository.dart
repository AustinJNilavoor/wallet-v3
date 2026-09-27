import 'package:wallet/core/sms_hive_boxes.dart';
import 'package:wallet/data/models/sms_category_mapping_hive.dart';

/// CRUD for keyword -> Category mappings.
class SmsCategoryMappingRepository {
  List<SmsCategoryMappingHive> getAll() {
    final list = SmsHiveBoxes.categoryMappings.values.toList();
    list.sort((a, b) => a.keyword.toLowerCase().compareTo(b.keyword.toLowerCase()));
    return list;
  }

  Future<void> save(SmsCategoryMappingHive mapping) async {
    await SmsHiveBoxes.categoryMappings.put(mapping.id, mapping);
  }

  Future<void> delete(String id) async {
    await SmsHiveBoxes.categoryMappings.delete(id);
  }

  Future<void> setEnabled(String id, bool enabled) async {
    final mapping = SmsHiveBoxes.categoryMappings.get(id);
    if (mapping == null) return;
    mapping.enabled = enabled;
    await mapping.save();
  }

  /// Finds the categoryId for [text] (typically an extracted
  /// merchant/description string), matching case-insensitively and
  /// preferring the *longest* matching keyword (so "SWIGGY INSTAMART"
  /// beats a generic "SWIGGY" rule if both exist).
  String? resolveCategoryId(String text) {
    final normalized = text.toLowerCase();

    final matches = SmsHiveBoxes.categoryMappings.values
        .where((m) => m.enabled)
        .where((m) => normalized.contains(m.keyword.toLowerCase()))
        .toList()
      ..sort((a, b) => b.keyword.length.compareTo(a.keyword.length));

    if (matches.isEmpty) return null;
    return matches.first.categoryId;
  }
}