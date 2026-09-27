// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sms_match_field.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SmsMatchFieldAdapter extends TypeAdapter<SmsMatchField> {
  @override
  final int typeId = 7;

  @override
  SmsMatchField read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SmsMatchField.sender;
      case 1:
        return SmsMatchField.message;
      default:
        return SmsMatchField.sender;
    }
  }

  @override
  void write(BinaryWriter writer, SmsMatchField obj) {
    switch (obj) {
      case SmsMatchField.sender:
        writer.writeByte(0);
        break;
      case SmsMatchField.message:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmsMatchFieldAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
