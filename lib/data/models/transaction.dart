import 'package:hive/hive.dart';
import 'category.dart';
import 'source.dart';
import 'transaction_type.dart';

part 'transaction.g.dart';

@HiveType(typeId: 2)
class Transaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  DateTime createdDate;

  @HiveField(3)
  String note;

  @HiveField(4)
  Category category;

  @HiveField(5)
  Source source; // FROM

  @HiveField(6)
  TransactionType type;

  @HiveField(7)
  Source? destinationSource; 

  @HiveField(8)
String? smsHash;

  Transaction({
    required this.id,
    required this.amount,
    required this.createdDate,
    required this.note,
    required this.category,
    required this.source,
    required this.type,
    this.destinationSource,
    this.smsHash,
  });
}
