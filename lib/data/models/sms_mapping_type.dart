import 'package:hive/hive.dart';

part 'sms_mapping_type.g.dart';

@HiveType(typeId: 6)
enum SmsMappingType {
  @HiveField(0)
  source,

  @HiveField(1)
  category,
}