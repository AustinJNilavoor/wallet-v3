import 'package:wallet/core/boxes.dart';
import 'package:wallet/data/models/sms_template.dart';

class SmsTemplateMatcher {
  final _templateBox = Boxes.getSmsTemplates();

  /// Returns the best matching template.
  SmsTemplate? findTemplate({
    required String sender,
    required String body,
  }) {
    final templates = _templateBox.values
        .where((template) => template.enabled)
        .toList();

    templates.sort(
      (a, b) => b.priority.compareTo(a.priority),
    );

    SmsTemplate? bestTemplate;

    for (final template in templates) {
      if (!_senderMatches(
        sender: sender,
        pattern: template.senderPattern,
      )) {
        continue;
      }

      if (!_keywordsMatch(
        body: body,
        keywords: template.keywords,
      )) {
        continue;
      }

      bestTemplate = template;
      break;
    }

    return bestTemplate;
  }

  bool _senderMatches({
    required String sender,
    required String pattern,
  }) {
    if (pattern.trim().isEmpty) {
      return true;
    }

    final normalizedSender =
        sender.trim().toLowerCase();

    final normalizedPattern =
        pattern.trim().toLowerCase();

    // Exact match.
    if (normalizedSender == normalizedPattern) {
      return true;
    }

    // Contains match.
    if (normalizedSender.contains(normalizedPattern)) {
      return true;
    }

    // Regex support.
    try {
      final regex = RegExp(
        pattern,
        caseSensitive: false,
      );

      return regex.hasMatch(sender);
    } catch (_) {
      return false;
    }
  }

  bool _keywordsMatch({
    required String body,
    required List<String> keywords,
  }) {
    if (keywords.isEmpty) {
      return true;
    }

    final normalizedBody =
        body.toLowerCase();

    return keywords.every(
      (keyword) =>
          normalizedBody.contains(
            keyword.trim().toLowerCase(),
          ),
    );
  }
}