import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';

import 'package:wallet/core/boxes.dart';
import 'package:wallet/data/models/category.dart';
import 'package:wallet/data/models/source.dart';
import 'package:wallet/data/models/sms_mapping_type.dart';
import 'package:wallet/data/models/sms_match_field.dart';
import 'package:wallet/data/models/transaction.dart';
import 'package:wallet/data/models/transaction_type.dart';

/// Result returned after converting an SMS into a Transaction.
///
/// If [transaction] is null, [errorMessage] explains why conversion failed.
class SmsTransactionResult {
  final Transaction? transaction;
  final String? errorMessage;

  const SmsTransactionResult({this.transaction, this.errorMessage});

  bool get isSuccess => transaction != null;
}


class SmsHashUtil {
  const SmsHashUtil._();

  static String generate({
    required String sender,
    required String body,
    required DateTime date,
  }) {
    final normalized = [
      sender.trim().toUpperCase(),
      date.millisecondsSinceEpoch.toString(),
      body.trim(),
    ].join('|');

    return sha256
        .convert(utf8.encode(normalized))
        .toString();
  }
}
/// Handles all business logic related to converting an SMS into a Transaction.
///
/// This class does NOT:
/// - display UI
/// - navigate
/// - show SnackBars
/// - contain Flutter screens
///
/// It only performs calculations, parsing and database mapping.
class SmsTransactionService {
  const SmsTransactionService();
  bool isTransactionSms(String body) {
    return _parseSmsTransaction(body: body, date: DateTime.now())?.amount != null;

  }

  /// Converts the selected SMS into a Transaction.
  ///
  /// The selected SMS is passed through:
  /// [sender]
  /// [body]
  /// [date]
  ///
  /// The returned Transaction is NOT saved to Hive.
  /// It is only prepared to be passed to InputScreen.
  SmsTransactionResult createTransaction({
    required String sender,
    required String body,
    required DateTime date,
  }) {
    try {
      // ------------------------------------------------------------
      // 1. Parse amount and transaction type
      // ------------------------------------------------------------

      final parsed = _parseSmsTransaction(body: body, date: date);

      if (parsed == null) {
        return const SmsTransactionResult(
          errorMessage:
              'Could not identify the amount or transaction type from this SMS.',
        );
      }

      // ------------------------------------------------------------
      // 2. Find mapped category
      // ------------------------------------------------------------

      final mappedCategory = _findMappedCategory(sender: sender, body: body);

      final selectedCategory = mappedCategory ?? _getDefaultCategory();

      if (selectedCategory == null) {
        return const SmsTransactionResult(
          errorMessage:
              'No category is available. Please create a category first.',
        );
      }

      // ------------------------------------------------------------
      // 3. Find mapped source
      // ------------------------------------------------------------

      final mappedSource = _findMappedSource(sender: sender, body: body);

      final selectedSource = mappedSource ?? _getFallbackSource();

      if (selectedSource == null) {
        return const SmsTransactionResult(
          errorMessage: 'No source is available. Please create a source first.',
        );
      }

      // ------------------------------------------------------------
      // 4. Debug information
      // ------------------------------------------------------------


      // ------------------------------------------------------------
      // 5. Create Transaction
      // ------------------------------------------------------------
final smsHash = SmsHashUtil.generate(
  sender: sender,
  body: body,
  date: date,
);

      final transaction = Transaction(
        id: const Uuid().v4(),
        amount: parsed.amount,
        createdDate: parsed.date,
        note: '',
        category: selectedCategory,
        source: selectedSource,
        type: parsed.type,
        destinationSource: null,
          smsHash: smsHash,
      );
      return SmsTransactionResult(transaction: transaction);
    } catch (e) {

      return const SmsTransactionResult(
        errorMessage: 'Unable to create transaction from this SMS.',
      );
    }
  }

  // ================================================================
  // PARSE SMS
  // ================================================================

  _ParsedSmsTransaction? _parseSmsTransaction({
    required String body,
    required DateTime date,
  }) {
    final lowerBody = body.toLowerCase();

    // --------------------------------------------------------------
    // INCOME
    // --------------------------------------------------------------

    final bool isIncome =
        lowerBody.contains('credited') ||
        lowerBody.contains('credit') ||
        lowerBody.contains('deposited') ||
        lowerBody.contains('received');

    // --------------------------------------------------------------
    // EXPENSE
    // --------------------------------------------------------------

    final bool isExpense =
        lowerBody.contains('debited') ||
        lowerBody.contains('debit') ||
        lowerBody.contains('spent') ||
        lowerBody.contains('sent') ||
        lowerBody.contains('paid');

    if (!isIncome && !isExpense) {
      return null;
    }

    // --------------------------------------------------------------
    // AMOUNT
    // --------------------------------------------------------------

    final amount = _extractAmount(body);

    if (amount == null || amount <= 0) {
      return null;
    }

    return _ParsedSmsTransaction(
      amount: amount,
      type: isIncome ? TransactionType.income : TransactionType.expense,
      date: date,
    );
  }

  // ================================================================
  // EXTRACT AMOUNT
  // ================================================================

  double? _extractAmount(String text) {
    final patterns = [
      // ₹1,250.50
      // Rs 1,250.50
      // INR 1250
      RegExp(
        r'(?:₹\s*|\brs\.?\s*|\binr\b\s*)'
        r'([0-9,]+(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),

      // 1,250.50 ₹
      // 1,250.50 Rs
      // 1250 INR
      RegExp(
        r'([0-9,]+(?:\.[0-9]{1,2})?)'
        r'\s*(?:₹|\brs\b\.?|\binr\b)',
        caseSensitive: false,
      ),

      // Amount Rs 1250
      // Amt: 1250
      RegExp(
        r'(?:amount|amt)'
        r'[^0-9]{0,20}'
        r'([0-9,]+(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);

      if (match == null) {
        continue;
      }

      final value = match.group(1);

      if (value == null) {
        continue;
      }

      final cleaned = value.replaceAll(',', '');

      final amount = double.tryParse(cleaned);

      if (amount != null) {
        return amount;
      }
    }

    return null;
  }

  // ================================================================
  // SOURCE MAPPING
  // ================================================================

  Source? _findMappedSource({required String sender, required String body}) {
    try {
      final mappingBox = Boxes.getSmsMappings();
      final sourceBox = Boxes.getSources();

      final mappings = mappingBox.values
          .where(
            (mapping) =>
                mapping.isActive &&
                mapping.mappingType == SmsMappingType.source,
          )
          .toList();

      // Highest priority first.
      mappings.sort((a, b) => b.priority.compareTo(a.priority));

      for (final mapping in mappings) {
        final matchValue = mapping.matchValue.trim().toLowerCase();

        if (matchValue.isEmpty) {
          continue;
        }

        final String textToSearch;

        if (mapping.matchField == SmsMatchField.sender) {
          textToSearch = sender.toLowerCase();
        } else {
          textToSearch = body.toLowerCase();
        }

        if (!textToSearch.contains(matchValue)) {
          continue;
        }

        final source = sourceBox.get(mapping.targetId);

        if (source == null) {

          continue;
        }

        if (source.isArchived) {


          continue;
        }



        return source;
      }
    } catch (e) {
//TODO: Handle error appropriately, e.g., log it or show a message to the user.
    }

    return null;
  }

  // ================================================================
  // CATEGORY MAPPING
  // ================================================================

  Category? _findMappedCategory({
    required String sender,
    required String body,
  }) {
    try {
      final mappingBox = Boxes.getSmsMappings();
      final categoryBox = Boxes.getCategories();

      final mappings = mappingBox.values
          .where(
            (mapping) =>
                mapping.isActive &&
                mapping.mappingType == SmsMappingType.category,
          )
          .toList();

      // Highest priority first.
      mappings.sort((a, b) => b.priority.compareTo(a.priority));

      for (final mapping in mappings) {
        final matchValue = mapping.matchValue.trim().toLowerCase();

        if (matchValue.isEmpty) {
          continue;
        }

        final String textToSearch;

        if (mapping.matchField == SmsMatchField.sender) {
          textToSearch = sender.toLowerCase();
        } else {
          textToSearch = body.toLowerCase();
        }

        if (!textToSearch.contains(matchValue)) {
          continue;
        }

        final category = categoryBox.get(mapping.targetId);

        if (category == null) {


          continue;
        }



        return category;
      }
    } catch (e) {
  //TODO: Handle error appropriately, e.g., log it or show a message to the user.
    }

    return null;
  }

  // ================================================================
  // DEFAULT CATEGORY
  // ================================================================

  Category? _getDefaultCategory() {
    try {
      final box = Boxes.getCategories();

      if (box.isEmpty) {
        return null;
      }

      final categories = box.values.toList();

      if (categories.isEmpty) {
        return null;
      }

      return categories.first;
    } catch (e) {
//TODO: Handle error appropriately, e.g., log it or show a message to the user.
      return null;
    }
  }

  // ================================================================
  // FALLBACK SOURCE
  // ================================================================

  Source? _getFallbackSource() {
    try {
      final box = Boxes.getSources();

      if (box.isEmpty) {
        return null;
      }

      final sources = box.values.where((source) => !source.isArchived).toList();

      if (sources.isEmpty) {
        return null;
      }

      return sources.first;
    } catch (e) {
//TODO: Handle error appropriately, e.g., log it or show a message to the user.

      return null;
    }
  }
}

// ==================================================================
// INTERNAL PARSED RESULT
// ==================================================================

class _ParsedSmsTransaction {
  final double amount;
  final TransactionType type;
  final DateTime date;

  const _ParsedSmsTransaction({
    required this.amount,
    required this.type,
    required this.date,
  });
}
