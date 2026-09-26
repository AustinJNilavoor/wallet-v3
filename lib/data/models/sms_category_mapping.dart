import 'package:hive/hive.dart';

part 'sms_category_mapping.g.dart';

@HiveType(typeId: 8)
enum SmsMappingField {
  @HiveField(0)
  account,

  @HiveField(1)
  merchant,

  @HiveField(2)
  reference,

  @HiveField(3)
  description,

  @HiveField(4)
  sender,

  @HiveField(5)
  amount,

  @HiveField(6)
  custom,
}

@HiveType(typeId: 9)
enum SmsMappingOperator {
  @HiveField(0)
  equals,

  @HiveField(1)
  contains,

  @HiveField(2)
  startsWith,

  @HiveField(3)
  endsWith,

  @HiveField(4)
  regex,
}

@HiveType(typeId: 10)
class SmsCategoryMapping extends HiveObject {
  @HiveField(0)
  String id;

  /// Optional template restriction.
  ///
  /// null means this rule can apply to any template.
  @HiveField(1)
  String? templateId;

  @HiveField(2)
  SmsMappingField field;

  @HiveField(3)
  SmsMappingOperator operator;

  @HiveField(4)
  String value;

  /// Category ID from the existing categories box.
  @HiveField(5)
  String? categoryId;

  /// Source ID from the existing sources box.
  @HiveField(6)
  String? sourceId;

  /// Optional destination source for transfers.
  @HiveField(7)
  String? destinationSourceId;

  /// 0 = lowest priority.
  @HiveField(8)
  int priority;

  @HiveField(9)
  bool enabled;

  @HiveField(10)
  String? description;

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  DateTime updatedAt;

  SmsCategoryMapping({
    required this.id,
    this.templateId,
    required this.field,
    required this.operator,
    required this.value,
    this.categoryId,
    this.sourceId,
    this.destinationSourceId,
    this.priority = 0,
    this.enabled = true,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  SmsCategoryMapping copyWith({
    String? id,
    Object? templateId = _unset,
    SmsMappingField? field,
    SmsMappingOperator? operator,
    String? value,
    Object? categoryId = _unset,
    Object? sourceId = _unset,
    Object? destinationSourceId = _unset,
    int? priority,
    bool? enabled,
    Object? description = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SmsCategoryMapping(
      id: id ?? this.id,
      templateId: identical(templateId, _unset)
          ? this.templateId
          : templateId as String?,
      field: field ?? this.field,
      operator: operator ?? this.operator,
      value: value ?? this.value,
      categoryId: identical(categoryId, _unset)
          ? this.categoryId
          : categoryId as String?,
      sourceId: identical(sourceId, _unset)
          ? this.sourceId
          : sourceId as String?,
      destinationSourceId: identical(destinationSourceId, _unset)
          ? this.destinationSourceId
          : destinationSourceId as String?,
      priority: priority ?? this.priority,
      enabled: enabled ?? this.enabled,
      description: identical(description, _unset)
          ? this.description
          : description as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// Sentinel used by [SmsCategoryMapping.copyWith] to distinguish
/// "field not passed" from "field explicitly set to null" for
/// nullable fields.
const Object _unset = Object();