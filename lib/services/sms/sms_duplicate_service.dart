import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:wallet/data/repositories/pending_transaction_repository.dart';

class SmsDuplicateService {
  SmsDuplicateService({PendingTransactionRepository? repository})
    : _repository = repository ?? PendingTransactionRepository();

  final PendingTransactionRepository _repository;

  /// Creates a stable duplicate key for an SMS.
  String generateDuplicateKey({
    required String sender,
    required String body,
    required DateTime date,
  }) {
    final normalizedSender = sender.trim().toLowerCase();

    final normalizedBody = body
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();

    final input = [
      normalizedSender,
      date.millisecondsSinceEpoch.toString(),
      normalizedBody,
    ].join('|');

    return sha256.convert(utf8.encode(input)).toString();
  }

  /// Checks whether this SMS has already been imported.
  ///
  /// We check both:
  /// 1. provider SMS ID
  /// 2. generated duplicate key
  bool isDuplicate({String? smsId, required String duplicateKey}) {
    return _repository.isKnown(smsId: smsId, duplicateKey: duplicateKey);
  }

  /// Checks whether the SMS was already approved/rejected by looking
  /// through stored pending records.
  ///
  /// This becomes especially useful if you decide to retain processed
  /// records instead of deleting them.
  bool hasProcessedSms({String? smsId, required String duplicateKey}) {
    return _repository.isKnown(smsId: smsId, duplicateKey: duplicateKey);
  }
}
