// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sms_mapping_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SmsMappingTypeAdapter extends TypeAdapter<SmsMappingType> {
  @override
  final int typeId = 6;

  @override
  SmsMappingType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SmsMappingType.source;
      case 1:
        return SmsMappingType.category;
      default:
        return SmsMappingType.source;
    }
  }

  @override
  void write(BinaryWriter writer, SmsMappingType obj) {
    switch (obj) {
      case SmsMappingType.source:
        writer.writeByte(0);
        break;
      case SmsMappingType.category:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmsMappingTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
