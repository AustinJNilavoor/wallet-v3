import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsReaderService {
  SmsReaderService({
    SmsQuery? query,
  }) : _query = query ?? SmsQuery();

  final SmsQuery _query;

  /// Checks whether READ_SMS permission is available.
  Future<bool> hasPermission() async {
    final status = await Permission.sms.status;

    return status.isGranted;
  }

  /// Requests READ_SMS permission.
  Future<bool> requestPermission() async {
    final status = await Permission.sms.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    final result = await Permission.sms.request();

    return result.isGranted;
  }

  /// Ensures SMS permission exists.
  Future<bool> ensurePermission() async {
    if (await hasPermission()) {
      return true;
    }

    return requestPermission();
  }

  /// Reads inbox messages.
  ///
  /// We intentionally read only inbox messages.
  Future<List<SmsMessage>> readInbox({
    int count = 1000,
  }) async {
    final permitted = await ensurePermission();

    if (!permitted) {
      throw SmsPermissionException(
        'READ_SMS permission was not granted.',
      );
    }

    return _query.querySms(
      kinds: [
        SmsQueryKind.inbox,
      ],
      count: count,
      sort: true,
    );
  }
}

class SmsPermissionException implements Exception {
  final String message;

  SmsPermissionException(this.message);

  @override
  String toString() => message;
}