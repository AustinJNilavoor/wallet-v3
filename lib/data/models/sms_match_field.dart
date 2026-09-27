import 'package:hive/hive.dart';

part 'sms_match_field.g.dart';

@HiveType(typeId: 7)
enum SmsMatchField {
  @HiveField(0)
  sender,

  @HiveField(1)
  message,
}