// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'source.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SourceAdapter extends TypeAdapter<Source> {
  @override
  final int typeId = 1;

  @override
  Source read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Source(
      id: fields[0] as String,
      name: fields[1] as String,
      iconIndex: fields[2] as int,
      balance: fields[3] as double,
      isIncludedInTotal: fields[4] as bool,
      order: fields[5] as int,
      lastUpdated: fields[6] as DateTime,
      isCreditCard: fields[7] as bool,
      isBalanceHidden: fields[9] as bool,
      isArchived: fields[8] as bool,
      creditLimit: fields[10] as double?,
      outstandingAmount: fields[11] as double?,
      dueDays: fields[13] as int?,
      billingDay: fields[12] as int?,
      colorValue: fields[14] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Source obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.iconIndex)
      ..writeByte(3)
      ..write(obj.balance)
      ..writeByte(4)
      ..write(obj.isIncludedInTotal)
      ..writeByte(5)
      ..write(obj.order)
      ..writeByte(6)
      ..write(obj.lastUpdated)
      ..writeByte(7)
      ..write(obj.isCreditCard)
      ..writeByte(8)
      ..write(obj.isArchived)
      ..writeByte(9)
      ..write(obj.isBalanceHidden)
      ..writeByte(10)
      ..write(obj.creditLimit)
      ..writeByte(11)
      ..write(obj.outstandingAmount)
      ..writeByte(12)
      ..write(obj.billingDay)
      ..writeByte(13)
      ..write(obj.dueDays)
      ..writeByte(14)
      ..write(obj.colorValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
