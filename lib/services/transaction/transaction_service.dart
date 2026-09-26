import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:wallet/core/boxes.dart';
import 'package:wallet/data/models/category.dart';
import 'package:wallet/data/models/source.dart';
import 'package:wallet/data/models/transaction.dart';
import 'package:wallet/data/models/transaction_type.dart';

/// Thrown when a transaction can't be created/updated because a
/// referenced [Source] or [Category] no longer exists.
class TransactionServiceException implements Exception {
  final String message;

  TransactionServiceException(this.message);

  @override
  String toString() => message;
}

/// Centralises the logic for creating, updating and deleting
/// [Transaction]s together with the [Source] balance changes they
/// imply.
///
/// Previously this math was duplicated (and could drift) across the
/// input screen, the history screen's delete handler and the pending
/// transaction approval flow. Routing all three through this service
/// keeps the balance bookkeeping in exactly one place.
class TransactionService {
  TransactionService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  /// The virtual category used to represent a transfer between two
  /// of the user's own sources. It is never persisted in the
  /// categories box.
  static Category get transferCategory => Category(
    id: 'transfer',
    name: 'Transfer',
    iconIndex: 0,
    colorValue: Colors.blue.toARGB32(),
  );

  Box<Source> get _sourceBox => Boxes.getSources();

  Box<Transaction> get _transactionBox => Boxes.getTransactions();

  /// Creates a new income/expense transaction and applies its effect
  /// to [sourceId]'s balance.
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

    _applySimple(source: source, amount: amount, type: type);
    source.lastUpdated = DateTime.now();
    await source.save();

    await _transactionBox.put(transaction.id, transaction);
    return transaction;
  }

  /// Creates a new transfer transaction between two sources.
  Future<Transaction> createTransfer({
    required double amount,
    required DateTime date,
    required String note,
    required String fromSourceId,
    required String toSourceId,
    String? id,
  }) async {
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
  ///
  /// Used before re-applying an edited transaction, and before
  /// deleting one outright.
  Future<void> revert(Transaction transaction) async {
    final now = DateTime.now();
    final source = _sourceBox.get(transaction.source.id);

    if (source == null) return;

    if (transaction.type == TransactionType.transfer) {
      final destination = transaction.destinationSource != null
          ? _sourceBox.get(transaction.destinationSource!.id)
          : null;

      // Undo: give back to sender, take back from receiver.
      source.balance += transaction.amount;
      source.lastUpdated = now;
      await source.save();

      if (destination != null) {
        destination.balance -= transaction.amount;
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

  void _applySimple({
    required Source source,
    required double amount,
    required TransactionType type,
  }) {
    if (type == TransactionType.income) {
      source.balance += amount;
    } else {
      source.balance -= amount;
    }
  }
}
