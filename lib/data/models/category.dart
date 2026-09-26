import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 0)
class Category extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int iconIndex;

  @HiveField(3)
  int? colorValue;

  Category({
    required this.id,
    required this.name,
    required this.iconIndex,
    this.colorValue = 0xFF2196F3,
  });
}
