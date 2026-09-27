// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sms_sync_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SmsSyncStateAdapter extends TypeAdapter<SmsSyncState> {
  @override
  final int typeId = 5;

  @override
  SmsSyncState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SmsSyncState(
      lastSyncedAt: fields[0] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SmsSyncState obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.lastSyncedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmsSyncStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
