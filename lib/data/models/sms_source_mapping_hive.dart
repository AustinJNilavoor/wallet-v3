import 'package:hive/hive.dart';

/// Sender pattern -> Source translation rule.
///
/// `sourceId` references an existing Source record in your Sources
/// box. `senderPattern` is meant to be compared against the
/// *normalized* sender id (see
/// `SmsPatternBuilder.defaultSenderPattern`), e.g. "HDFCBK", "SBIBANK",
/// "ICICIB" - not the raw operator-prefixed sender.
///
/// TypeId: 53.
class SmsSourceMappingHive extends HiveObject {
  String id;
  String senderPattern;
  String sourceId;
  bool enabled;

  SmsSourceMappingHive({
    required this.id,
    required this.senderPattern,
    required this.sourceId,
    this.enabled = true,
  });

  SmsSourceMappingHive copyWith({
    String? senderPattern,
    String? sourceId,
    bool? enabled,
  }) {
    return SmsSourceMappingHive(
      id: id,
      senderPattern: senderPattern ?? this.senderPattern,
      sourceId: sourceId ?? this.sourceId,
      enabled: enabled ?? this.enabled,
    );
  }
}

class SmsSourceMappingHiveAdapter extends TypeAdapter<SmsSourceMappingHive> {
  @override
  final int typeId = 53;

  @override
  SmsSourceMappingHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return SmsSourceMappingHive(
      id: fields[0] as String,
      senderPattern: fields[1] as String,
      sourceId: fields[2] as String,
      enabled: fields[3] as bool? ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, SmsSourceMappingHive obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.senderPattern)
      ..writeByte(2)
      ..write(obj.sourceId)
      ..writeByte(3)
      ..write(obj.enabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmsSourceMappingHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}