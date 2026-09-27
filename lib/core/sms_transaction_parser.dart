import 'package:wallet/core/sms_category_translator.dart';
import 'package:wallet/core/sms_source_translator.dart';
import 'package:wallet/data/models/sms_preview_item.dart';
import 'package:wallet/data/models/sms_template.dart';
import 'package:wallet/data/repository/sms_template_repository.dart';

/// Result of running a matched [SmsTemplate] against one [SmsPreviewItem].
///
/// Every id here (category/source/destinationSource) is already fully
/// resolved - there is no raw keyword left for a caller to translate.
/// Anything that couldn't be resolved shows up in [missingFields] so a
/// review/approval UI knows exactly what to ask the user for.
class ParsedSmsResult {
  final SmsTemplate template;
  final double? amount;
  final DateTime? transactionDate;
  final String? categoryId;
  final String? sourceId;
  final String? destinationSourceId;

  /// `TransactionType.name` ("income" / "expense" / "transfer").
  final String? transactionType;

  final String? note;
  final List<SmsFieldKey> missingFields;

  const ParsedSmsResult({
    required this.template,
    required this.missingFields,
    this.amount,
    this.transactionDate,
    this.categoryId,
    this.sourceId,
    this.destinationSourceId,
    this.transactionType,
    this.note,
  });

  bool get isComplete => missingFields.isEmpty;
}

/// Runs the full SMS -> transaction pipeline:
///
/// ```
/// find matching template (by sender)
///   -> extract each field per its mapping (map / ask / default)
///   -> translate extracted merchant text into a Category id
///   -> translate sender (or extracted bank text) into a Source id
///   -> return a ParsedSmsResult, with anything unresolved flagged
///      in missingFields for the approval UI to ask about
/// ```
class SmsTransactionParser {
  SmsTransactionParser({
    SmsTemplateRepository? templateRepository,
    SmsCategoryTranslator? categoryTranslator,
    SmsSourceTranslator? sourceTranslator,
  }) : _templateRepository = templateRepository ?? SmsTemplateRepository(),
       _categoryTranslator = categoryTranslator ?? SmsCategoryTranslator(),
       _sourceTranslator = sourceTranslator ?? SmsSourceTranslator();

  final SmsTemplateRepository _templateRepository;
  final SmsCategoryTranslator _categoryTranslator;
  final SmsSourceTranslator _sourceTranslator;

  /// Finds a template whose sender pattern matches [message] and
  /// parses it. Returns null if nothing matches (i.e. this message
  /// isn't a recognized transaction SMS at all).
  ParsedSmsResult? parse(SmsPreviewItem message) {
    final template = _templateRepository.findMatchingTemplate(message.sender);
    if (template == null) return null;
    return parseWithTemplate(message, template);
  }

  /// Parses [message] against a specific [template], bypassing sender
  /// lookup. Useful for previewing a template against a sample
  /// message while authoring it.
  ParsedSmsResult parseWithTemplate(
    SmsPreviewItem message,
    SmsTemplate template,
  ) {
    final missing = <SmsFieldKey>[];

    double? amount;
    DateTime? transactionDate;
    String? categoryId;
    String? sourceId;
    String? destinationSourceId;
    String? transactionType;
    String? note;

    for (final mapping in template.fieldMappings) {
      final resolved = _resolveField(mapping, message);

      switch (mapping.fieldKey) {
        case SmsFieldKey.amount:
          amount = resolved == null
              ? null
              : double.tryParse(resolved.replaceAll(',', ''));
          if (amount == null) missing.add(SmsFieldKey.amount);
          break;

        case SmsFieldKey.date:
          transactionDate = resolved == null ? null : _parseDate(resolved);
          // Falling back to the SMS's own received time is a
          // reasonable default, so a missing/unparseable date is not
          // treated as something that needs asking about.
          transactionDate ??= message.date;
          break;

        case SmsFieldKey.category:
          categoryId = resolved;
          if (categoryId == null) missing.add(SmsFieldKey.category);
          break;

        case SmsFieldKey.source:
          sourceId = resolved;
          // Sender-based fallback is applied after this loop.
          break;

        case SmsFieldKey.destinationSource:
          destinationSourceId = resolved;
          break;

        case SmsFieldKey.type:
          transactionType = _normalizeTransactionType(resolved);
          if (transactionType == null) missing.add(SmsFieldKey.type);
          break;

        case SmsFieldKey.note:
          note = resolved;
          break;
      }
    }

    // Source resolution has two layers: whatever the template itself
    // produced wins; if the template didn't resolve one (field left
    // as "ask", or mapped/translated to nothing), fall back to the
    // generic sender -> source mapping before giving up.
    sourceId ??= _sourceTranslator.translate(message.sender);
    if (sourceId == null) missing.add(SmsFieldKey.source);

    if (transactionType == 'transfer' &&
        destinationSourceId == null &&
        !missing.contains(SmsFieldKey.destinationSource)) {
      missing.add(SmsFieldKey.destinationSource);
    }

    return ParsedSmsResult(
      template: template,
      amount: amount,
      transactionDate: transactionDate,
      categoryId: categoryId,
      sourceId: sourceId,
      destinationSourceId: destinationSourceId,
      transactionType: transactionType,
      note: note,
      missingFields: missing,
    );
  }

  /// Resolves one field per its mapping mode.
  ///
  /// For [SmsFieldKey.category]/[SmsFieldKey.source]/
  /// [SmsFieldKey.destinationSource] in "mapped" mode, the raw
  /// extracted text is run through the relevant translator here, so
  /// every other caller in this class only ever sees a final id, never
  /// a raw keyword.
  String? _resolveField(SmsFieldMapping mapping, SmsPreviewItem message) {
    switch (mapping.mode) {
      case SmsFieldMappingMode.ask:
        return null;

      case SmsFieldMappingMode.defaultValue:
        return mapping.defaultValue;

      case SmsFieldMappingMode.mapped:
        final extracted = mapping.extract(message.body);
        if (extracted == null) return null;

        if (mapping.fieldKey == SmsFieldKey.category) {
          return _categoryTranslator.translate(extracted);
        }

        if (mapping.fieldKey == SmsFieldKey.source ||
            mapping.fieldKey == SmsFieldKey.destinationSource) {
          return _sourceTranslator.translate(extracted);
        }

        return extracted;
    }
  }

  String? _normalizeTransactionType(String? raw) {
    if (raw == null) return null;
    final lower = raw.toLowerCase().trim();

    if (lower == 'income' || lower == 'expense' || lower == 'transfer') {
      return lower;
    }
    if (lower.contains('credit')) return 'income';
    if (lower.contains('debit')) return 'expense';
    if (lower.contains('transfer')) return 'transfer';

    return null;
  }

  DateTime? _parseDate(String raw) {
    final trimmed = raw.trim();

    // Numeric: dd-mm-yyyy / dd/mm/yy
    final numeric = RegExp(
      r'^(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})$',
    ).firstMatch(trimmed);

    if (numeric != null) {
      final day = int.tryParse(numeric.group(1)!);
      final month = int.tryParse(numeric.group(2)!);
      var year = int.tryParse(numeric.group(3)!);

      if (day != null && month != null && year != null) {
        if (year < 100) year += 2000;
        try {
          return DateTime(year, month, day);
        } catch (_) {
          return null;
        }
      }
    }

    // Textual: dd-MMM-yy / dd MMM yyyy
    final textual = RegExp(
      r'^(\d{1,2})[\s-]([A-Za-z]{3,9})[\s-](\d{2,4})$',
    ).firstMatch(trimmed);

    if (textual != null) {
      final day = int.tryParse(textual.group(1)!);
      final month = _monthFromName(textual.group(2)!);
      var year = int.tryParse(textual.group(3)!);

      if (day != null && month != null && year != null) {
        if (year < 100) year += 2000;
        try {
          return DateTime(year, month, day);
        } catch (_) {
          return null;
        }
      }
    }

    return null;
  }

  int? _monthFromName(String name) {
    const months = [
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec',
    ];
    final lower = name.toLowerCase();
    final index = months.indexWhere((m) => lower.startsWith(m));
    return index == -1 ? null : index + 1;
  }
}