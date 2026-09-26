import 'package:wallet/core/boxes.dart';
import 'package:wallet/data/models/parsed_sms_transaction.dart';
import 'package:wallet/data/models/sms_category_mapping.dart';

class SmsMappingResult {
  final String? categoryId;

  final String? sourceId;

  final String? destinationSourceId;

  final String? transactionType;

  const SmsMappingResult({
    this.categoryId,
    this.sourceId,
    this.destinationSourceId,
    this.transactionType,
  });
}

class SmsMappingService {
  final _mappingBox = Boxes.getSmsCategoryMappings();

  SmsMappingResult applyMappings({required ParsedSmsTransaction parsed}) {
    final mappings = _mappingBox.values
        .where(
          (mapping) =>
              mapping.enabled &&
              _templateMatches(mapping.templateId, parsed.templateId),
        )
        .toList();

    mappings.sort((a, b) => b.priority.compareTo(a.priority));

    String? categoryId;
    String? sourceId;
    String? destinationSourceId;

    for (final mapping in mappings) {
      final value = _getFieldValue(mapping.field, parsed);

      if (value == null || value.trim().isEmpty) {
        continue;
      }

      if (!_matches(
        actual: value,
        operator: mapping.operator,
        expected: mapping.value,
      )) {
        continue;
      }

      categoryId ??= mapping.categoryId;

      sourceId ??= mapping.sourceId;

      destinationSourceId ??= mapping.destinationSourceId;

      if (categoryId != null && sourceId != null) {
        break;
      }
    }

    return SmsMappingResult(
      categoryId: categoryId,
      sourceId: sourceId,
      destinationSourceId: destinationSourceId,
      transactionType: inferTransactionType(parsed),
    );
  }

  String? inferTransactionType(ParsedSmsTransaction parsed) {
    final text = parsed.rawMessage.toLowerCase();

    const incomeKeywords = [
      'credited',
      'credit',
      'received',
      'deposited',
      'salary',
      'refund',
    ];

    const expenseKeywords = [
      'debited',
      'debit',
      'spent',
      'withdrawn',
      'purchase',
      'paid',
    ];

    if (incomeKeywords.any(text.contains)) {
      return 'income';
    }

    if (expenseKeywords.any(text.contains)) {
      return 'expense';
    }

    return parsed.transactionType;
  }

  String? _getFieldValue(SmsMappingField field, ParsedSmsTransaction parsed) {
    switch (field) {
      case SmsMappingField.account:
        return parsed.accountNumber;

      case SmsMappingField.merchant:
        return parsed.merchant;

      case SmsMappingField.reference:
        return parsed.referenceNumber;

      case SmsMappingField.description:
        return parsed.description;

      case SmsMappingField.sender:
        return parsed.sender;

      case SmsMappingField.amount:
        return parsed.amount?.toString();

      case SmsMappingField.custom:
        if (parsed.customFields.isEmpty) {
          return null;
        }

        return parsed.customFields.values.first;
    }
  }

  bool _templateMatches(String? mappingTemplateId, String? parsedTemplateId) {
    if (mappingTemplateId == null || mappingTemplateId.isEmpty) {
      return true;
    }

    return mappingTemplateId == parsedTemplateId;
  }

  bool _matches({
    required String actual,
    required SmsMappingOperator operator,
    required String expected,
  }) {
    final actualValue = actual.trim();

    final expectedValue = expected.trim();

    switch (operator) {
      case SmsMappingOperator.equals:
        return actualValue.toLowerCase() == expectedValue.toLowerCase();

      case SmsMappingOperator.contains:
        return actualValue.toLowerCase().contains(expectedValue.toLowerCase());

      case SmsMappingOperator.startsWith:
        return actualValue.toLowerCase().startsWith(
          expectedValue.toLowerCase(),
        );

      case SmsMappingOperator.endsWith:
        return actualValue.toLowerCase().endsWith(expectedValue.toLowerCase());

      case SmsMappingOperator.regex:
        try {
          return RegExp(
            expectedValue,
            caseSensitive: false,
          ).hasMatch(actualValue);
        } catch (_) {
          return false;
        }
    }
  }

}
