import 'package:hive/hive.dart';

part 'sms_template_field.g.dart';

@HiveType(typeId: 5)
enum SmsFieldType {
  @HiveField(0)
  amount,

  @HiveField(1)
  date,

  @HiveField(2)
  merchant,

  @HiveField(3)
  account,

  @HiveField(4)
  reference,

  @HiveField(5)
  balance,

  @HiveField(6)
  description,

  @HiveField(7)
  transactionType,

  @HiveField(8)
  custom,
}

@HiveType(typeId: 6)
enum SmsExtractionType {
  @HiveField(0)
  regex,

  @HiveField(1)
  contains,

  @HiveField(2)
  before,

  @HiveField(3)
  after,

  @HiveField(4)
  between,
}

@HiveType(typeId: 14)
class SmsTemplateField extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String templateId;

  @HiveField(2)
  String name;

  @HiveField(3)
  SmsFieldType fieldType;

  @HiveField(4)
  SmsExtractionType extractionType;

  /// Regex or extraction expression.
  ///
  /// Example:
  /// Rs\.?\s*([\d,]+(?:\.\d{1,2})?)
  @HiveField(5)
  String pattern;

  /// Optional capture group number.
  ///
  /// Usually 1 when regex contains:
  /// (...).
  @HiveField(6)
  int captureGroup;

  /// Whether this field must be extracted successfully.
  @HiveField(7)
  bool required;

  /// Optional fallback value if extraction fails.
  @HiveField(8)
  String? defaultValue;

  /// For custom fields.
  @HiveField(9)
  String? customFieldName;

  /// Used to control field ordering in the UI.
  @HiveField(10)
  int order;

  SmsTemplateField({
    required this.id,
    required this.templateId,
    required this.name,
    required this.fieldType,
    required this.extractionType,
    required this.pattern,
    this.captureGroup = 1,
    this.required = false,
    this.defaultValue,
    this.customFieldName,
    this.order = 0,
  });

  SmsTemplateField copyWith({
    String? id,
    String? templateId,
    String? name,
    SmsFieldType? fieldType,
    SmsExtractionType? extractionType,
    String? pattern,
    int? captureGroup,
    bool? required,
    Object? defaultValue = _unset,
    Object? customFieldName = _unset,
    int? order,
  }) {
    return SmsTemplateField(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      fieldType: fieldType ?? this.fieldType,
      extractionType: extractionType ?? this.extractionType,
      pattern: pattern ?? this.pattern,
      captureGroup: captureGroup ?? this.captureGroup,
      required: required ?? this.required,
      defaultValue: identical(defaultValue, _unset)
          ? this.defaultValue
          : defaultValue as String?,
      customFieldName: identical(customFieldName, _unset)
          ? this.customFieldName
          : customFieldName as String?,
      order: order ?? this.order,
    );
  }
}

/// Sentinel used by [SmsTemplateField.copyWith] to distinguish "field
/// not passed" from "field explicitly set to null" for nullable
/// fields.
const Object _unset = Object();