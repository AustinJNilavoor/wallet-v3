import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:wallet/core/boxes.dart';
import 'package:wallet/data/models/category.dart';
import 'package:wallet/data/models/source.dart';
import 'package:wallet/data/models/transaction.dart';
import 'package:wallet/data/models/transaction_type.dart';

/// Thrown when a transaction can't be created/updated because a
/// referenced [Source] no longer exists, or the inputs are invalid.
class TransactionServiceException implements Exception {
  final String message;
  TransactionServiceException(this.message);

  @override
  String toString() => message;
}

/// Single place that knows how to create, update and delete
/// [Transaction]s together with the [Source] balance changes they
/// imply.
///
/// Any caller — the manual input screen today, an SMS-approval flow
/// tomorrow, a CSV importer later — should go through this class
/// instead of touching Hive boxes / balances directly. That's what
/// keeps the math in exactly one place.
class TransactionService {
  TransactionService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  /// Virtual category used to represent a transfer between two of the
  /// user's own sources. Never persisted in the categories box.
  static Category get transferCategory => Category(
    id: 'transfer',
    name: 'Transfer',
    iconIndex: 0,
    colorValue: Colors.blue.toARGB32(),
  );

  Box<Source> get _sourceBox => Boxes.getSources();
  Box<Transaction> get _transactionBox => Boxes.getTransactions();

  /// Same as [createSimpleTransaction], but takes a category **id**
  /// instead of a [Category] object.
  ///
  /// This is what the SMS-import flow needs: by the time
  /// `SmsTransactionParser` has run, all it has is resolved ids (from
  /// the Category/Source translators), not live domain objects.
  Future<Transaction> createSimpleTransactionFromIds({
    required double amount,
    required DateTime date,
    required String note,
    required String categoryId,
    required String sourceId,
    required TransactionType type,
    String? id,
  }) async {
    final category = Boxes.getCategories().get(categoryId);
    if (category == null) {
      throw TransactionServiceException('Category not found.');
    }

    return createSimpleTransaction(
      amount: amount,
      date: date,
      note: note,
      category: category,
      sourceId: sourceId,
      type: type,
      id: id,
    );
  }

  /// Creates (or, if [id] matches an existing transaction, overwrites)
  /// an income/expense transaction and applies its effect to
  /// [sourceId]'s balance.
  ///
  /// Pass the *same* [id] you're replacing when this is an edit —
  /// remember to call [revert] on the old transaction first so its
  /// old balance effect isn't double-counted.
  Future<Transaction> createSimpleTransaction({
    required double amount,
    required DateTime date,
    required String note,
    required Category category,
    required String sourceId,
    required TransactionType type,
    String? id,
  }) async {
    assert(type != TransactionType.transfer);

    if (amount <= 0) {
      throw TransactionServiceException('Enter a valid amount.');
    }

    final source = _sourceBox.get(sourceId);
    if (source == null) {
      throw TransactionServiceException('Source not found.');
    }

    final transaction = Transaction(
      id: id ?? _uuid.v4(),
      amount: amount,
      createdDate: date,
      note: note,
      category: category,
      source: source,
      type: type,
    );

    if (type == TransactionType.income) {
      source.balance += amount;
    } else {
      source.balance -= amount;
    }
    source.lastUpdated = DateTime.now();
    await source.save();

    await _transactionBox.put(transaction.id, transaction);
    return transaction;
  }

  /// Creates (or overwrites, if [id] is passed) a transfer transaction
  /// between two sources.
  Future<Transaction> createTransfer({
    required double amount,
    required DateTime date,
    required String note,
    required String fromSourceId,
    required String toSourceId,
    String? id,
  }) async {
    if (amount <= 0) {
      throw TransactionServiceException('Enter a valid amount.');
    }

    if (fromSourceId == toSourceId) {
      throw TransactionServiceException('Cannot transfer to the same source.');
    }

    final from = _sourceBox.get(fromSourceId);
    final to = _sourceBox.get(toSourceId);

    if (from == null || to == null) {
      throw TransactionServiceException('Source not found.');
    }

    final transaction = Transaction(
      id: id ?? _uuid.v4(),
      amount: amount,
      createdDate: date,
      note: note,
      category: transferCategory,
      source: from,
      destinationSource: to,
      type: TransactionType.transfer,
    );

    final now = DateTime.now();
    from.balance -= amount;
    to.balance += amount;
    from.lastUpdated = now;
    to.lastUpdated = now;
    await from.save();
    await to.save();

    await _transactionBox.put(transaction.id, transaction);
    return transaction;
  }

  /// Reverts the balance effect of [transaction] without deleting it.
  /// Call this before re-applying an edited transaction, or before
  /// deleting one outright.
  Future<void> revert(Transaction transaction) async {
    final now = DateTime.now();
    final source = _sourceBox.get(transaction.source.id);
    if (source == null) return;

    if (transaction.type == TransactionType.transfer) {
      final destination = transaction.destinationSource != null
          ? _sourceBox.get(transaction.destinationSource!.id)
          : null;

      source.balance += transaction.amount; // give back to sender
      source.lastUpdated = now;
      await source.save();

      if (destination != null) {
        destination.balance -= transaction.amount; // take back from receiver
        destination.lastUpdated = now;
        await destination.save();
      }
    } else {
      if (transaction.type == TransactionType.income) {
        source.balance -= transaction.amount;
      } else {
        source.balance += transaction.amount;
      }
      source.lastUpdated = now;
      await source.save();
    }
  }

  /// Deletes [transaction] and reverts its balance effect.
  Future<void> deleteAndRevert(Transaction transaction) async {
    await revert(transaction);
    await transaction.delete();
  }
}