import 'package:hive/hive.dart';

part 'sms_sync_state.g.dart';

@HiveType(typeId: 13)
class SmsSyncState extends HiveObject {
  @HiveField(0)
  String id;

  /// The latest SMS timestamp that has been completely scanned.
  @HiveField(1)
  DateTime? lastSyncedAt;

  /// Provider SMS ID, when available.
  @HiveField(2)
  String? lastSyncedSmsId;

  /// Number of milliseconds to look backwards from lastSyncedAt.
  ///
  /// Example:
  /// 300000 = 5 minutes.
  @HiveField(3)
  int overlapMilliseconds;

  /// Number of messages scanned in the last sync.
  @HiveField(4)
  int lastScanCount;

  /// Number of messages that became pending transactions
  /// in the last sync.
  @HiveField(5)
  int lastImportedCount;

  /// Number of duplicate messages ignored in the last sync.
  @HiveField(6)
  int lastDuplicateCount;

  /// Number of messages for which no template matched.
  @HiveField(7)
  int lastUnmatchedCount;

  /// Last time sync was started.
  @HiveField(8)
  DateTime? lastSyncStartedAt;

  /// Last time sync completed.
  @HiveField(9)
  DateTime? lastSyncCompletedAt;

  /// Whether the previous sync completed successfully.
  @HiveField(10)
  bool lastSyncSuccessful;

  /// Useful for debugging.
  @HiveField(11)
  String? lastError;

  /// Whether SMS importing is enabled.
  @HiveField(12)
  bool enabled;

  /// Stores the timezone offset used when the sync
  /// state was written.
  ///
  /// Example:
  /// +330 for IST.
  @HiveField(13)
  int timezoneOffsetMinutes;

  SmsSyncState({
    this.id = 'default',
    this.lastSyncedAt,
    this.lastSyncedSmsId,
    this.overlapMilliseconds = 5 * 60 * 1000,
    this.lastScanCount = 0,
    this.lastImportedCount = 0,
    this.lastDuplicateCount = 0,
    this.lastUnmatchedCount = 0,
    this.lastSyncStartedAt,
    this.lastSyncCompletedAt,
    this.lastSyncSuccessful = true,
    this.lastError,
    this.enabled = true,
    this.timezoneOffsetMinutes = 330,
  });

  Duration get overlap =>
      Duration(milliseconds: overlapMilliseconds);

  DateTime? get effectiveSyncFrom {
    if (lastSyncedAt == null) {
      return null;
    }

    return lastSyncedAt!.subtract(overlap);
  }

  void markSyncStarted() {
    lastSyncStartedAt = DateTime.now();
    lastSyncSuccessful = false;
    lastError = null;
  }

  void markSyncCompleted({
    required DateTime syncedAt,
    String? smsId,
    int scanCount = 0,
    int importedCount = 0,
    int duplicateCount = 0,
    int unmatchedCount = 0,
  }) {
    lastSyncedAt = syncedAt;
    lastSyncedSmsId = smsId;

    lastScanCount = scanCount;
    lastImportedCount = importedCount;
    lastDuplicateCount = duplicateCount;
    lastUnmatchedCount = unmatchedCount;

    lastSyncCompletedAt = DateTime.now();
    lastSyncSuccessful = true;
    lastError = null;

    timezoneOffsetMinutes =
        DateTime.now().timeZoneOffset.inMinutes;
  }

  void markSyncFailed(Object error) {
    lastSyncCompletedAt = DateTime.now();
    lastSyncSuccessful = false;
    lastError = error.toString();
  }
}