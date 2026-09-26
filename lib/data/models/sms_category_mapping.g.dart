// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sms_category_mapping.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SmsCategoryMappingAdapter extends TypeAdapter<SmsCategoryMapping> {
  @override
  final int typeId = 10;

  @override
  SmsCategoryMapping read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SmsCategoryMapping(
      id: fields[0] as String,
      templateId: fields[1] as String?,
      field: fields[2] as SmsMappingField,
      operator: fields[3] as SmsMappingOperator,
      value: fields[4] as String,
      categoryId: fields[5] as String?,
      sourceId: fields[6] as String?,
      destinationSourceId: fields[7] as String?,
      priority: fields[8] as int,
      enabled: fields[9] as bool,
      description: fields[10] as String?,
      createdAt: fields[11] as DateTime?,
      updatedAt: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SmsCategoryMapping obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.templateId)
      ..writeByte(2)
      ..write(obj.field)
      ..writeByte(3)
      ..write(obj.operator)
      ..writeByte(4)
      ..write(obj.value)
      ..writeByte(5)
      ..write(obj.categoryId)
      ..writeByte(6)
      ..write(obj.sourceId)
      ..writeByte(7)
      ..write(obj.destinationSourceId)
      ..writeByte(8)
      ..write(obj.priority)
      ..writeByte(9)
      ..write(obj.enabled)
      ..writeByte(10)
      ..write(obj.description)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmsCategoryMappingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SmsMappingFieldAdapter extends TypeAdapter<SmsMappingField> {
  @override
  final int typeId = 8;

  @override
  SmsMappingField read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SmsMappingField.account;
      case 1:
        return SmsMappingField.merchant;
      case 2:
        return SmsMappingField.reference;
      case 3:
        return SmsMappingField.description;
      case 4:
        return SmsMappingField.sender;
      case 5:
        return SmsMappingField.amount;
      case 6:
        return SmsMappingField.custom;
      default:
        return SmsMappingField.account;
    }
  }

  @override
  void write(BinaryWriter writer, SmsMappingField obj) {
    switch (obj) {
      case SmsMappingField.account:
        writer.writeByte(0);
        break;
      case SmsMappingField.merchant:
        writer.writeByte(1);
        break;
      case SmsMappingField.reference:
        writer.writeByte(2);
        break;
      case SmsMappingField.description:
        writer.writeByte(3);
        break;
      case SmsMappingField.sender:
        writer.writeByte(4);
        break;
      case SmsMappingField.amount:
        writer.writeByte(5);
        break;
      case SmsMappingField.custom:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmsMappingFieldAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SmsMappingOperatorAdapter extends TypeAdapter<SmsMappingOperator> {
  @override
  final int typeId = 9;

  @override
  SmsMappingOperator read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SmsMappingOperator.equals;
      case 1:
        return SmsMappingOperator.contains;
      case 2:
        return SmsMappingOperator.startsWith;
      case 3:
        return SmsMappingOperator.endsWith;
      case 4:
        return SmsMappingOperator.regex;
      default:
        return SmsMappingOperator.equals;
    }
  }

  @override
  void write(BinaryWriter writer, SmsMappingOperator obj) {
    switch (obj) {
      case SmsMappingOperator.equals:
        writer.writeByte(0);
        break;
      case SmsMappingOperator.contains:
        writer.writeByte(1);
        break;
      case SmsMappingOperator.startsWith:
        writer.writeByte(2);
        break;
      case SmsMappingOperator.endsWith:
        writer.writeByte(3);
        break;
      case SmsMappingOperator.regex:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmsMappingOperatorAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
