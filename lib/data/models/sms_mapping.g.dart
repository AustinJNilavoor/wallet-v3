// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sms_mapping.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SmsMappingAdapter extends TypeAdapter<SmsMapping> {
  @override
  final int typeId = 17;

  @override
  SmsMapping read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SmsMapping(
      id: fields[0] as String,
      matchValue: fields[1] as String,
      matchField: fields[2] as SmsMatchField,
      mappingType: fields[3] as SmsMappingType,
      targetId: fields[4] as String,
      isActive: fields[5] as bool,
      priority: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SmsMapping obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.matchValue)
      ..writeByte(2)
      ..write(obj.matchField)
      ..writeByte(3)
      ..write(obj.mappingType)
      ..writeByte(4)
      ..write(obj.targetId)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.priority);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmsMappingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
