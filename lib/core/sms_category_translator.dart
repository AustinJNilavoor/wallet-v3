import 'package:wallet/data/repository/sms_category_mapping_repository.dart';

/// Resolves a Category id from free text (typically the merchant or
/// description extracted from an SMS), via the keyword mappings the
/// user has configured.
///
/// This is deliberately a thin wrapper around
/// [SmsCategoryMappingRepository] - kept as its own class so the
/// parser depends on a named "translator" step matching the design
/// (Extract merchant -> Category Translator -> categoryId), and so it
/// can grow independent matching strategies later without touching
/// the repository or the parser.
class SmsCategoryTranslator {
  SmsCategoryTranslator({SmsCategoryMappingRepository? repository})
    : _repository = repository ?? SmsCategoryMappingRepository();

  final SmsCategoryMappingRepository _repository;

  /// Returns the mapped Category id for [text], or null if no keyword
  /// mapping matches.
  String? translate(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    return _repository.resolveCategoryId(text);
  }
}