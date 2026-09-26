import 'package:hive/hive.dart';

part 'sms_template.g.dart';

@HiveType(typeId: 7)
class SmsTemplate extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  /// Sender/address pattern.
  ///
  /// Example:
  /// HDFCBK
  /// AXISBK
  /// SBIINB
  ///
  /// This can also be a regex in future.
  @HiveField(2)
  String senderPattern;

  /// Optional keywords that should appear in the SMS.
  ///
  /// Example:
  /// ["debited", "withdrawn"]
  @HiveField(3)
  List<String> keywords;

  /// Whether this template participates in parsing.
  @HiveField(4)
  bool enabled;

  /// Higher priority templates are checked first.
  @HiveField(5)
  int priority;

  /// Optional sample SMS used while configuring/testing
  /// the template.
  @HiveField(6)
  String? sampleMessage;

  /// IDs of SmsTemplateField objects belonging to this template.
  ///
  /// We store IDs rather than nested Hive objects so that
  /// fields can be independently edited.
  @HiveField(7)
  List<String> fieldIds;

  /// Optional notes for the user.
  @HiveField(8)
  String? description;

  /// Date this template was created.
  @HiveField(9)
  DateTime createdAt;

  /// Date this template was last modified.
  @HiveField(10)
  DateTime updatedAt;

  SmsTemplate({
    required this.id,
    required this.name,
    required this.senderPattern,
    this.keywords = const [],
    this.enabled = true,
    this.priority = 0,
    this.sampleMessage,
    this.fieldIds = const [],
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  SmsTemplate copyWith({
    String? id,
    String? name,
    String? senderPattern,
    List<String>? keywords,
    bool? enabled,
    int? priority,
    Object? sampleMessage = _unset,
    List<String>? fieldIds,
    Object? description = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SmsTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      senderPattern: senderPattern ?? this.senderPattern,
      keywords: keywords ?? List<String>.from(this.keywords),
      enabled: enabled ?? this.enabled,
      priority: priority ?? this.priority,
      sampleMessage: identical(sampleMessage, _unset)
          ? this.sampleMessage
          : sampleMessage as String?,
      fieldIds: fieldIds ?? List<String>.from(this.fieldIds),
      description: identical(description, _unset)
          ? this.description
          : description as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// Sentinel used by [SmsTemplate.copyWith] to distinguish "field not
/// passed" from "field explicitly set to null" for nullable fields.
const Object _unset = Object();