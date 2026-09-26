/// Shared constants used across the SMS auto-import feature.
///
/// Centralising these avoids "magic string" drift between the
/// sync service, the settings screen and the repositories.
class SmsConstants {
  SmsConstants._();

  /// Key used for the single [SmsSyncState] record stored in Hive.
  static const String defaultSyncStateId = 'default';

  /// Default look-back window (in minutes) used to avoid missing
  /// SMS messages that arrive right around the last sync time.
  static const int defaultOverlapMinutes = 5;

  /// Maximum number of inbox messages read per sync pass.
  static const int defaultReadCount = 1000;

  /// Selectable overlap presets shown in the sync settings screen.
  static const List<int> overlapMinutePresets = [0, 5, 15, 30, 60];

  /// Separator used by the "between" extraction pattern:
  /// `START|||END`.
  static const String betweenPatternSeparator = '|||';
}
