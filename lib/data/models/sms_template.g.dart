// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sms_template.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SmsTemplateAdapter extends TypeAdapter<SmsTemplate> {
  @override
  final int typeId = 7;

  @override
  SmsTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SmsTemplate(
      id: fields[0] as String,
      name: fields[1] as String,
      senderPattern: fields[2] as String,
      keywords: (fields[3] as List).cast<String>(),
      enabled: fields[4] as bool,
      priority: fields[5] as int,
      sampleMessage: fields[6] as String?,
      fieldIds: (fields[7] as List).cast<String>(),
      description: fields[8] as String?,
      createdAt: fields[9] as DateTime?,
      updatedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SmsTemplate obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.senderPattern)
      ..writeByte(3)
      ..write(obj.keywords)
      ..writeByte(4)
      ..write(obj.enabled)
      ..writeByte(5)
      ..write(obj.priority)
      ..writeByte(6)
      ..write(obj.sampleMessage)
      ..writeByte(7)
      ..write(obj.fieldIds)
      ..writeByte(8)
      ..write(obj.description)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmsTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
