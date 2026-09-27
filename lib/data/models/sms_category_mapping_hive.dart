import 'package:hive/hive.dart';

/// Keyword -> Category translation rule.
///
/// `categoryId` references an existing Category record in your
/// Categories box - it never stores the category name as plain text,
/// so renaming a category doesn't silently break every mapping that
/// points at it.
///
/// TypeId: 52.
class SmsCategoryMappingHive extends HiveObject {
  String id;

  /// Matched case-insensitively as a substring against the extracted
  /// merchant/description text, e.g. "SWIGGY", "AMAZON".
  String keyword;

  String categoryId;
  bool enabled;

  SmsCategoryMappingHive({
    required this.id,
    required this.keyword,
    required this.categoryId,
    this.enabled = true,
  });

  SmsCategoryMappingHive copyWith({
    String? keyword,
    String? categoryId,
    bool? enabled,
  }) {
    return SmsCategoryMappingHive(
      id: id,
      keyword: keyword ?? this.keyword,
      categoryId: categoryId ?? this.categoryId,
      enabled: enabled ?? this.enabled,
    );
  }
}

class SmsCategoryMappingHiveAdapter
    extends TypeAdapter<SmsCategoryMappingHive> {
  @override
  final int typeId = 52;

  @override
  SmsCategoryMappingHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return SmsCategoryMappingHive(
      id: fields[0] as String,
      keyword: fields[1] as String,
      categoryId: fields[2] as String,
      enabled: fields[3] as bool? ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, SmsCategoryMappingHive obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.keyword)
      ..writeByte(2)
      ..write(obj.categoryId)
      ..writeByte(3)
      ..write(obj.enabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmsCategoryMappingHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}