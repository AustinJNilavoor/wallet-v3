// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sms_template_field.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SmsTemplateFieldAdapter extends TypeAdapter<SmsTemplateField> {
  @override
  final int typeId = 14;

  @override
  SmsTemplateField read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SmsTemplateField(
      id: fields[0] as String,
      templateId: fields[1] as String,
      name: fields[2] as String,
      fieldType: fields[3] as SmsFieldType,
      extractionType: fields[4] as SmsExtractionType,
      pattern: fields[5] as String,
      captureGroup: fields[6] as int,
      required: fields[7] as bool,
      defaultValue: fields[8] as String?,
      customFieldName: fields[9] as String?,
      order: fields[10] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SmsTemplateField obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.templateId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.fieldType)
      ..writeByte(4)
      ..write(obj.extractionType)
      ..writeByte(5)
      ..write(obj.pattern)
      ..writeByte(6)
      ..write(obj.captureGroup)
      ..writeByte(7)
      ..write(obj.required)
      ..writeByte(8)
      ..write(obj.defaultValue)
      ..writeByte(9)
      ..write(obj.customFieldName)
      ..writeByte(10)
      ..write(obj.order);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmsTemplateFieldAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SmsFieldTypeAdapter extends TypeAdapter<SmsFieldType> {
  @override
  final int typeId = 5;

  @override
  SmsFieldType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SmsFieldType.amount;
      case 1:
        return SmsFieldType.date;
      case 2:
        return SmsFieldType.merchant;
      case 3:
        return SmsFieldType.account;
      case 4:
        return SmsFieldType.reference;
      case 5:
        return SmsFieldType.balance;
      case 6:
        return SmsFieldType.description;
      case 7:
        return SmsFieldType.transactionType;
      case 8:
        return SmsFieldType.custom;
      default:
        return SmsFieldType.amount;
    }
  }

  @override
  void write(BinaryWriter writer, SmsFieldType obj) {
    switch (obj) {
      case SmsFieldType.amount:
        writer.writeByte(0);
        break;
      case SmsFieldType.date:
        writer.writeByte(1);
        break;
      case SmsFieldType.merchant:
        writer.writeByte(2);
        break;
      case SmsFieldType.account:
        writer.writeByte(3);
        break;
      case SmsFieldType.reference:
        writer.writeByte(4);
        break;
      case SmsFieldType.balance:
        writer.writeByte(5);
        break;
      case SmsFieldType.description:
        writer.writeByte(6);
        break;
      case SmsFieldType.transactionType:
        writer.writeByte(7);
        break;
      case SmsFieldType.custom:
        writer.writeByte(8);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmsFieldTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SmsExtractionTypeAdapter extends TypeAdapter<SmsExtractionType> {
  @override
  final int typeId = 6;

  @override
  SmsExtractionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SmsExtractionType.regex;
      case 1:
        return SmsExtractionType.contains;
      case 2:
        return SmsExtractionType.before;
      case 3:
        return SmsExtractionType.after;
      case 4:
        return SmsExtractionType.between;
      default:
        return SmsExtractionType.regex;
    }
  }

  @override
  void write(BinaryWriter writer, SmsExtractionType obj) {
    switch (obj) {
      case SmsExtractionType.regex:
        writer.writeByte(0);
        break;
      case SmsExtractionType.contains:
        writer.writeByte(1);
        break;
      case SmsExtractionType.before:
        writer.writeByte(2);
        break;
      case SmsExtractionType.after:
        writer.writeByte(3);
        break;
      case SmsExtractionType.between:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmsExtractionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
