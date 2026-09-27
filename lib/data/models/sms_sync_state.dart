import 'package:hive/hive.dart';

part 'sms_sync_state.g.dart';

@HiveType(typeId: 5)
class SmsSyncState extends HiveObject {
  @HiveField(0)
  DateTime? lastSyncedAt;

  SmsSyncState({
    this.lastSyncedAt,
  });
}