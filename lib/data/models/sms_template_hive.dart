import 'package:hive/hive.dart';

import 'package:wallet/data/models/sms_field_mapping_hive.dart';
import 'package:wallet/data/models/sms_template.dart';

/// Hive persistence model for [SmsTemplate].
///
/// Kept as a dedicated model (rather than persisting the JSON-oriented
/// [SmsTemplate] domain class directly) so the storage format doesn't
/// have to change shape every time the UI-facing domain model does,
/// and vice versa.
///
/// TypeId: 51.
class SmsTemplateHive extends HiveObject {
  String id;
  String name;
  String senderPattern;
  String sampleMessage;
  bool enabled;
  DateTime createdAt;
  List<SmsFieldMappingHive> fieldMappings;

  SmsTemplateHive({
    required this.id,
    required this.name,
    required this.senderPattern,
    required this.sampleMessage,
    required this.fieldMappings,
    this.enabled = true,
    required this.createdAt,
  });

  factory SmsTemplateHive.fromDomain(SmsTemplate template) {
    return SmsTemplateHive(
      id: template.id,
      name: template.name,
      senderPattern: template.senderPattern,
      sampleMessage: template.sampleMessage,
      enabled: template.enabled,
      createdAt: template.createdAt,
      fieldMappings: template.fieldMappings
          .map(SmsFieldMappingHive.fromDomain)
          .toList(),
    );
  }

  SmsTemplate toDomain() {
    return SmsTemplate(
      id: id,
      name: name,
      senderPattern: senderPattern,
      sampleMessage: sampleMessage,
      enabled: enabled,
      createdAt: createdAt,
      fieldMappings: fieldMappings.map((f) => f.toDomain()).toList(),
    );
  }

  /// Applies every field from [template] onto this existing Hive
  /// object in place (used when updating an existing template so its
  /// Hive key/identity is preserved).
  void updateFromDomain(SmsTemplate template) {
    name = template.name;
    senderPattern = template.senderPattern;
    sampleMessage = template.sampleMessage;
    enabled = template.enabled;
    fieldMappings = template.fieldMappings
        .map(SmsFieldMappingHive.fromDomain)
        .toList();
  }
}

class SmsTemplateHiveAdapter extends TypeAdapter<SmsTemplateHive> {
  @override
  final int typeId = 51;

  @override
  SmsTemplateHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return SmsTemplateHive(
      id: fields[0] as String,
      name: fields[1] as String,
      senderPattern: fields[2] as String,
      sampleMessage: fields[3] as String,
      enabled: fields[4] as bool,
      createdAt: fields[5] as DateTime,
      fieldMappings: (fields[6] as List).cast<SmsFieldMappingHive>(),
    );
  }

  @override
  void write(BinaryWriter writer, SmsTemplateHive obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.senderPattern)
      ..writeByte(3)
      ..write(obj.sampleMessage)
      ..writeByte(4)
      ..write(obj.enabled)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.fieldMappings);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmsTemplateHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}