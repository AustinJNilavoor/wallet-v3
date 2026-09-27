import 'package:wallet/data/repository/sms_source_mapping_repository.dart';

/// Resolves a Source id from a raw SMS sender id, via the
/// sender-pattern mappings the user has configured.
class SmsSourceTranslator {
  SmsSourceTranslator({SmsSourceMappingRepository? repository})
    : _repository = repository ?? SmsSourceMappingRepository();

  final SmsSourceMappingRepository _repository;

  /// Returns the mapped Source id for [sender], or null if no
  /// sender-pattern mapping matches.
  String? translate(String sender) {
    if (sender.trim().isEmpty) return null;
    return _repository.resolveSourceId(sender);
  }
}