import 'package:hive/hive.dart';

part 'stock.g.dart';

@HiveType(typeId: 4)
class Stock extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double totalQty;

  @HiveField(3)
  double totalInvestedMoney;

  @HiveField(4)
  double totalReturnedMoney;

  @HiveField(5)
  double totalCharges;

  @HiveField(6)
  double avgPrice;

  @HiveField(7)
  double realizedProfit;

  @HiveField(8)
  DateTime lastUpdated;

  Stock({
    required this.id,
    required this.name,
    required this.totalQty,
    required this.totalInvestedMoney,
    required this.totalReturnedMoney,
    required this.totalCharges,
    required this.avgPrice,
    required this.realizedProfit,
    required this.lastUpdated,
  });
}
