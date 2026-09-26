import 'package:intl/intl.dart';

import 'package:wallet/core/boxes.dart';
import 'package:wallet/data/models/sms_template.dart';
import 'package:wallet/data/models/sms_template_field.dart';
import 'package:wallet/data/models/parsed_sms_transaction.dart';
import 'package:wallet/services/sms/sms_duplicate_service.dart';

class SmsParserService {
  SmsParserService({
    SmsDuplicateService? duplicateService,
  }) : _duplicateService =
            duplicateService ?? SmsDuplicateService();

  final SmsDuplicateService _duplicateService;

  final _fieldBox = Boxes.getSmsTemplateFields();

  ParsedSmsTransaction parse({
    required String sender,
    required String body,
    required DateTime smsDate,
    required SmsTemplate template,
    String? smsId,
  }) {
    final duplicateKey =
        _duplicateService.generateDuplicateKey(
      sender: sender,
      body: body,
      date: smsDate,
    );

    final fields = _fieldBox.values
        .where(
          (field) =>
              field.templateId == template.id,
        )
        .toList();

    fields.sort(
      (a, b) => a.order.compareTo(b.order),
    );

    double? amount;
    DateTime? transactionDate;
    String? merchant;
    String? accountNumber;
    String? referenceNumber;
    double? balance;
    String? description;
    String? transactionType;

    final customFields =
        <String, String>{};

    final missingFields = <String>[];

    int successfulFields = 0;

    for (final field in fields) {
      final extracted =
          _extractField(
        body: body,
        field: field,
      );

      final value =
          extracted?.trim();

      if (value == null || value.isEmpty) {
        if (field.required) {
          missingFields.add(field.name);
        }

        if (field.defaultValue != null) {
          final fallback =
              field.defaultValue!.trim();

          _assignField(
            field: field,
            value: fallback,
            onAmount: (v) => amount = v,
            onDate: (v) => transactionDate = v,
            onMerchant: (v) => merchant = v,
            onAccount: (v) => accountNumber = v,
            onReference: (v) =>
                referenceNumber = v,
            onBalance: (v) => balance = v,
            onDescription: (v) =>
                description = v,
            onTransactionType: (v) =>
                transactionType = v,
            customFields: customFields,
          );
        }

        continue;
      }

      successfulFields++;

      _assignField(
        field: field,
        value: value,
        onAmount: (v) => amount = v,
        onDate: (v) => transactionDate = v,
        onMerchant: (v) => merchant = v,
        onAccount: (v) => accountNumber = v,
        onReference: (v) =>
            referenceNumber = v,
        onBalance: (v) => balance = v,
        onDescription: (v) =>
            description = v,
        onTransactionType: (v) =>
            transactionType = v,
        customFields: customFields,
      );
    }

    final requiredFieldCount =
        fields.where((f) => f.required).length;

    final parsingSuccessful =
        missingFields.isEmpty &&
        (requiredFieldCount == 0 ||
            successfulFields >= requiredFieldCount);

    final confidence =
        fields.isEmpty
            ? 0.0
            : successfulFields / fields.length;

    return ParsedSmsTransaction(
      smsId: smsId,
      sender: sender,
      rawMessage: body,
      smsDate: smsDate,
      duplicateKey: duplicateKey,
      templateId: template.id,
      amount: amount,
      transactionDate: transactionDate,
      merchant: merchant,
      accountNumber: accountNumber,
      referenceNumber: referenceNumber,
      balance: balance,
      description: description,
      transactionType: transactionType,
      customFields: customFields,
      missingFields: missingFields,
      parsingSuccessful: parsingSuccessful,
      confidence: confidence.clamp(0.0, 1.0),
    );
  }

  String? _extractField({
    required String body,
    required SmsTemplateField field,
  }) {
    if (field.pattern.trim().isEmpty) {
      return null;
    }

    try {
      switch (field.extractionType) {
        case SmsExtractionType.regex:
          return _extractRegex(
            body,
            field.pattern,
            field.captureGroup,
          );

        case SmsExtractionType.contains:
          return body.toLowerCase().contains(
                field.pattern.toLowerCase(),
              )
              ? field.pattern
              : null;

        case SmsExtractionType.before:
          return _extractBefore(
            body,
            field.pattern,
          );

        case SmsExtractionType.after:
          return _extractAfter(
            body,
            field.pattern,
          );

        case SmsExtractionType.between:
          return _extractBetween(
            body,
            field.pattern,
          );
      }
    } catch (_) {
      return null;
    }
  }

  String? _extractRegex(
    String body,
    String pattern,
    int captureGroup,
  ) {
    final regex = RegExp(
      pattern,
      caseSensitive: false,
      multiLine: true,
    );

    final match = regex.firstMatch(body);

    if (match == null) {
      return null;
    }

    if (match.groupCount >= captureGroup) {
      return match.group(captureGroup);
    }

    return match.group(0);
  }

  String? _extractBefore(
    String body,
    String delimiter,
  ) {
    final index = body
        .toLowerCase()
        .indexOf(delimiter.toLowerCase());

    if (index <= 0) {
      return null;
    }

    return body.substring(0, index).trim();
  }

  String? _extractAfter(
    String body,
    String delimiter,
  ) {
    final lowerBody =
        body.toLowerCase();

    final lowerDelimiter =
        delimiter.toLowerCase();

    final index =
        lowerBody.indexOf(lowerDelimiter);

    if (index == -1) {
      return null;
    }

    final start =
        index + delimiter.length;

    if (start >= body.length) {
      return null;
    }

    return body.substring(start).trim();
  }

  String? _extractBetween(
    String body,
    String pattern,
  ) {
    /*
     * Pattern format:
     *
     * START|||END
     *
     * Example:
     *
     * "A/c "||| " on "
     */

    final parts = pattern.split('|||');

    if (parts.length != 2) {
      return null;
    }

    final startMarker = parts[0];
    final endMarker = parts[1];

    final lowerBody =
        body.toLowerCase();

    final lowerStart =
        startMarker.toLowerCase();

    final lowerEnd =
        endMarker.toLowerCase();

    final startIndex =
        lowerBody.indexOf(lowerStart);

    if (startIndex == -1) {
      return null;
    }

    final contentStart =
        startIndex + startMarker.length;

    final endIndex =
        lowerBody.indexOf(
      lowerEnd,
      contentStart,
    );

    if (endIndex == -1) {
      return null;
    }

    return body
        .substring(
          contentStart,
          endIndex,
        )
        .trim();
  }

  void _assignField({
    required SmsTemplateField field,
    required String value,
    required void Function(double) onAmount,
    required void Function(DateTime) onDate,
    required void Function(String) onMerchant,
    required void Function(String) onAccount,
    required void Function(String) onReference,
    required void Function(double) onBalance,
    required void Function(String) onDescription,
    required void Function(String) onTransactionType,
    required Map<String, String> customFields,
  }) {
    final cleanValue =
        value.trim();

    switch (field.fieldType) {
      case SmsFieldType.amount:
        final parsed =
            _parseAmount(cleanValue);

        if (parsed != null) {
          onAmount(parsed);
        }
        break;

      case SmsFieldType.date:
        final parsed =
            _parseDate(cleanValue);

        if (parsed != null) {
          onDate(parsed);
        }
        break;

      case SmsFieldType.merchant:
        onMerchant(cleanValue);
        break;

      case SmsFieldType.account:
        onAccount(cleanValue);
        break;

      case SmsFieldType.reference:
        onReference(cleanValue);
        break;

      case SmsFieldType.balance:
        final parsed =
            _parseAmount(cleanValue);

        if (parsed != null) {
          onBalance(parsed);
        }
        break;

      case SmsFieldType.description:
        onDescription(cleanValue);
        break;

      case SmsFieldType.transactionType:
        onTransactionType(
          cleanValue.toLowerCase(),
        );
        break;

      case SmsFieldType.custom:
        final key =
            field.customFieldName?.trim().isNotEmpty == true
                ? field.customFieldName!.trim()
                : field.name.trim();

        customFields[key] = cleanValue;
        break;
    }
  }

  double? _parseAmount(String value) {
    var normalized =
        value.trim();

    normalized = normalized
        .replaceAll(',', '')
        .replaceAll('₹', '')
        .replaceAll('Rs.', '')
        .replaceAll('Rs', '')
        .trim();

    final match =
        RegExp(
          r'-?\d+(?:\.\d+)?',
        ).firstMatch(normalized);

    if (match == null) {
      return null;
    }

    return double.tryParse(
      match.group(0)!,
    );
  }

  DateTime? _parseDate(String value) {
    final clean =
        value.trim();

    final formats = [
      'dd-MM-yyyy',
      'dd/MM/yyyy',
      'dd-MM-yy',
      'dd/MM/yy',
      'dd MMM yyyy',
      'dd MMMM yyyy',
      'dd-MM-yyyy HH:mm',
      'dd/MM/yyyy HH:mm',
      'dd-MM-yyyy HH:mm:ss',
      'dd/MM/yyyy HH:mm:ss',
    ];

    for (final format in formats) {
      try {
        return DateFormat(
          format,
        ).parseStrict(clean);
      } catch (_) {}
    }

    return DateTime.tryParse(clean);
  }
}