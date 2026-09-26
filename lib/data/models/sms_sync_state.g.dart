// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sms_sync_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SmsSyncStateAdapter extends TypeAdapter<SmsSyncState> {
  @override
  final int typeId = 13;

  @override
  SmsSyncState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SmsSyncState(
      id: fields[0] as String,
      lastSyncedAt: fields[1] as DateTime?,
      lastSyncedSmsId: fields[2] as String?,
      overlapMilliseconds: fields[3] as int,
      lastScanCount: fields[4] as int,
      lastImportedCount: fields[5] as int,
      lastDuplicateCount: fields[6] as int,
      lastUnmatchedCount: fields[7] as int,
      lastSyncStartedAt: fields[8] as DateTime?,
      lastSyncCompletedAt: fields[9] as DateTime?,
      lastSyncSuccessful: fields[10] as bool,
      lastError: fields[11] as String?,
      enabled: fields[12] as bool,
      timezoneOffsetMinutes: fields[13] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SmsSyncState obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.lastSyncedAt)
      ..writeByte(2)
      ..write(obj.lastSyncedSmsId)
      ..writeByte(3)
      ..write(obj.overlapMilliseconds)
      ..writeByte(4)
      ..write(obj.lastScanCount)
      ..writeByte(5)
      ..write(obj.lastImportedCount)
      ..writeByte(6)
      ..write(obj.lastDuplicateCount)
      ..writeByte(7)
      ..write(obj.lastUnmatchedCount)
      ..writeByte(8)
      ..write(obj.lastSyncStartedAt)
      ..writeByte(9)
      ..write(obj.lastSyncCompletedAt)
      ..writeByte(10)
      ..write(obj.lastSyncSuccessful)
      ..writeByte(11)
      ..write(obj.lastError)
      ..writeByte(12)
      ..write(obj.enabled)
      ..writeByte(13)
      ..write(obj.timezoneOffsetMinutes);
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
