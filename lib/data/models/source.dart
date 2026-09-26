import 'package:hive/hive.dart';

part 'source.g.dart';

@HiveType(typeId: 1)
class Source extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  // 🔁 Replace raw icon with index (tree-shaking safe)
  @HiveField(2)
  int iconIndex;

  @HiveField(3)
  double balance;

  @HiveField(4)
  bool isIncludedInTotal;

  @HiveField(5)
  int order; // 🔥 replaces isPinned

  @HiveField(6)
  DateTime lastUpdated;

  @HiveField(7)
  bool isCreditCard;

  @HiveField(8)
  bool isArchived;

  @HiveField(9)
  bool isBalanceHidden;

  @HiveField(10)
  double? creditLimit;

  @HiveField(11)
  double? outstandingAmount;

  @HiveField(12)
  int? billingDay;

  @HiveField(13)
  int? dueDays;

  @HiveField(14)
  int colorValue;

  Source({
    required this.id,
    required this.name,
    required this.iconIndex,
    required this.balance,
    required this.isIncludedInTotal,
    required this.order,
    required this.lastUpdated,
    required this.isCreditCard,
    this.isBalanceHidden = false,
    this.isArchived = false,
    this.creditLimit,
    this.outstandingAmount,
    this.dueDays,
    this.billingDay,
    this.colorValue = 0xFF2196F3,
  });
}
