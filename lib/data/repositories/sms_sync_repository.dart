import 'package:hive/hive.dart';

import 'package:wallet/core/boxes.dart';
import 'package:wallet/core/sms_constants.dart';
import 'package:wallet/data/models/sms_sync_state.dart';

/// Thin data-access layer around the `sms_sync_state` Hive box.
///
/// There is only ever one [SmsSyncState] record (keyed by
/// [SmsConstants.defaultSyncStateId]), so this repository exposes a
/// simple get-or-create API instead of a generic CRUD surface.
class SmsSyncRepository {
  SmsSyncRepository({Box<SmsSyncState>? box})
    : _box = box ?? Boxes.getSmsSyncState();

  final Box<SmsSyncState> _box;

  /// Returns the existing sync state, creating (and persisting) a
  /// fresh one on first launch.
  SmsSyncState getOrCreate() {
    final existing = _box.get(SmsConstants.defaultSyncStateId);

    if (existing != null) {
      return existing;
    }

    final state = SmsSyncState(
      id: SmsConstants.defaultSyncStateId,
      overlapMilliseconds:
          SmsConstants.defaultOverlapMinutes * 60 * 1000,
      enabled: true,
      timezoneOffsetMinutes: DateTime.now().timeZoneOffset.inMinutes,
    );

    _box.put(SmsConstants.defaultSyncStateId, state);

    return state;
  }

  Future<void> save(SmsSyncState state) async {
    await _box.put(SmsConstants.defaultSyncStateId, state);
  }
}
