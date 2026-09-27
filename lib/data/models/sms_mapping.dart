import 'package:hive/hive.dart';

import 'sms_mapping_type.dart';
import 'sms_match_field.dart';

part 'sms_mapping.g.dart';

@HiveType(typeId: 17)
class SmsMapping extends HiveObject {
  @HiveField(0)
  String id;

  /// Text/keyword/pattern to search for.
  ///
  /// Examples:
  /// HDFC
  /// SBI
  /// SWIGGY
  /// ZOMATO
  /// AMAZON
  @HiveField(1)
  String matchValue;

  /// Where the match should be performed.
  ///
  /// sender -> SMS sender
  /// message -> SMS body
  @HiveField(2)
  SmsMatchField matchField;

  /// What this mapping should select.
  ///
  /// source -> Source
  /// category -> Category
  @HiveField(3)
  SmsMappingType mappingType;

  /// ID of the existing Source or Category.
  ///
  /// If mappingType == source:
  ///     this is Source.id
  ///
  /// If mappingType == category:
  ///     this is Category.id
  @HiveField(4)
  String targetId;

  /// Whether this mapping is currently active.
  @HiveField(5)
  bool isActive;

  /// Higher priority mappings are checked first.
  ///
  /// Example:
  /// HDFC BANK -> priority 10
  /// HDFC -> priority 5
  @HiveField(6)
  int priority;

  SmsMapping({
    required this.id,
    required this.matchValue,
    required this.matchField,
    required this.mappingType,
    required this.targetId,
    this.isActive = true,
    this.priority = 0,
  });
}