import 'package:hive_flutter/hive_flutter.dart';

import 'package:wallet/data/models/sms_category_mapping_hive.dart';
import 'package:wallet/data/models/sms_field_mapping_hive.dart';
import 'package:wallet/data/models/sms_source_mapping_hive.dart';
import 'package:wallet/data/models/sms_template_hive.dart';

/// Registers adapters and opens boxes for every SMS-related Hive
/// model.
///
/// Call `await SmsHiveBoxes.init();` once in `main()`, after
/// `Hive.initFlutter()` and alongside whatever adapter registration
/// your core models (Category/Source/Transaction/...) already do,
/// and before `runApp(...)`.
///
/// TypeId map used here - check these don't collide with anything
/// else already registered in your project, and bump them if they do:
/// - 50: SmsFieldMappingHive (embedded value object)
/// - 51: SmsTemplateHive
/// - 52: SmsCategoryMappingHive
/// - 53: SmsSourceMappingHive
class SmsHiveBoxes {
  SmsHiveBoxes._();

  static const String templatesBoxName = 'sms_templates_v2';
  static const String categoryMappingsBoxName = 'sms_category_mappings';
  static const String sourceMappingsBoxName = 'sms_source_mappings';

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    if (!Hive.isAdapterRegistered(50)) {
      Hive.registerAdapter(SmsFieldMappingHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(51)) {
      Hive.registerAdapter(SmsTemplateHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(52)) {
      Hive.registerAdapter(SmsCategoryMappingHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(53)) {
      Hive.registerAdapter(SmsSourceMappingHiveAdapter());
    }

    await Hive.openBox<SmsTemplateHive>(templatesBoxName);
    await Hive.openBox<SmsCategoryMappingHive>(categoryMappingsBoxName);
    await Hive.openBox<SmsSourceMappingHive>(sourceMappingsBoxName);

    _initialized = true;
  }

  static Box<SmsTemplateHive> get templates =>
      Hive.box<SmsTemplateHive>(templatesBoxName);

  static Box<SmsCategoryMappingHive> get categoryMappings =>
      Hive.box<SmsCategoryMappingHive>(categoryMappingsBoxName);

  static Box<SmsSourceMappingHive> get sourceMappings =>
      Hive.box<SmsSourceMappingHive>(sourceMappingsBoxName);
}