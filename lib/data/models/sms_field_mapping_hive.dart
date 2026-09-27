import 'package:hive/hive.dart';

import 'package:wallet/data/models/sms_template.dart';

/// Hive-persistable mirror of [SmsFieldMapping].
///
/// This is a *value* object embedded inside [SmsTemplateHive]'s
/// `fieldMappings` list - it is never stored in its own box, so it
/// doesn't extend `HiveObject`. It only needs a registered
/// [TypeAdapter] so Hive knows how to (de)serialize it when it shows
/// up nested inside a template.
///
/// TypeId: 50 (see sms_hive_boxes.dart for the full typeId map - bump
/// this if it collides with something already registered in your
/// project).
class SmsFieldMappingHive {
  final String fieldKey; // SmsFieldKey.name
  final String mode; // SmsFieldMappingMode.name
  final String? prefixAnchor;
  final String? suffixAnchor;
  final String? pattern;
  final int captureGroup;
  final String? sampleValue;
  final String? defaultValue;

  const SmsFieldMappingHive({
    required this.fieldKey,
    required this.mode,
    this.prefixAnchor,
    this.suffixAnchor,
    this.pattern,
    this.captureGroup = 1,
    this.sampleValue,
    this.defaultValue,
  });

  factory SmsFieldMappingHive.fromDomain(SmsFieldMapping mapping) {
    return SmsFieldMappingHive(
      fieldKey: mapping.fieldKey.name,
      mode: mapping.mode.name,
      prefixAnchor: mapping.prefixAnchor,
      suffixAnchor: mapping.suffixAnchor,
      pattern: mapping.pattern,
      captureGroup: mapping.captureGroup,
      sampleValue: mapping.sampleValue,
      defaultValue: mapping.defaultValue,
    );
  }

  SmsFieldMapping toDomain() {
    return SmsFieldMapping(
      fieldKey: SmsFieldKey.values.byName(fieldKey),
      mode: SmsFieldMappingMode.values.byName(mode),
      prefixAnchor: prefixAnchor,
      suffixAnchor: suffixAnchor,
      pattern: pattern,
      captureGroup: captureGroup,
      sampleValue: sampleValue,
      defaultValue: defaultValue,
    );
  }
}

class SmsFieldMappingHiveAdapter extends TypeAdapter<SmsFieldMappingHive> {
  @override
  final int typeId = 50;

  @override
  SmsFieldMappingHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return SmsFieldMappingHive(
      fieldKey: fields[0] as String,
      mode: fields[1] as String,
      prefixAnchor: fields[2] as String?,
      suffixAnchor: fields[3] as String?,
      pattern: fields[4] as String?,
      captureGroup: fields[5] as int? ?? 1,
      sampleValue: fields[6] as String?,
      defaultValue: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SmsFieldMappingHive obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.fieldKey)
      ..writeByte(1)
      ..write(obj.mode)
      ..writeByte(2)
      ..write(obj.prefixAnchor)
      ..writeByte(3)
      ..write(obj.suffixAnchor)
      ..writeByte(4)
      ..write(obj.pattern)
      ..writeByte(5)
      ..write(obj.captureGroup)
      ..writeByte(6)
      ..write(obj.sampleValue)
      ..writeByte(7)
      ..write(obj.defaultValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmsFieldMappingHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}