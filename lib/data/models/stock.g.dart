// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StockAdapter extends TypeAdapter<Stock> {
  @override
  final int typeId = 4;

  @override
  Stock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Stock(
      id: fields[0] as String,
      name: fields[1] as String,
      totalQty: fields[2] as double,
      totalInvestedMoney: fields[3] as double,
      totalReturnedMoney: fields[4] as double,
      totalCharges: fields[5] as double,
      avgPrice: fields[6] as double,
      realizedProfit: fields[7] as double,
      lastUpdated: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Stock obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.totalQty)
      ..writeByte(3)
      ..write(obj.totalInvestedMoney)
      ..writeByte(4)
      ..write(obj.totalReturnedMoney)
      ..writeByte(5)
      ..write(obj.totalCharges)
      ..writeByte(6)
      ..write(obj.avgPrice)
      ..writeByte(7)
      ..write(obj.realizedProfit)
      ..writeByte(8)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
