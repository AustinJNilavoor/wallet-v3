import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  const PermissionHelper._();

  static Future<bool> requestSmsPermission() async {
    var status = await Permission.sms.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      status = await Permission.sms.request();

      return status.isGranted;
    }

    if (status.isPermanentlyDenied) {
      return false;
    }

    return false;
  }

  static Future<bool> hasSmsPermission() async {
    final status = await Permission.sms.status;

    return status.isGranted;
  }

  static Future<bool> openSettings() async {
    return openAppSettings();
  }
}