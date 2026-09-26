import 'package:flutter/foundation.dart';

import 'package:wallet/data/models/pending_transaction.dart';
import 'package:wallet/data/models/transaction_type.dart';
import 'package:wallet/data/repositories/pending_transaction_repository.dart';
import 'package:wallet/core/boxes.dart';
import 'package:wallet/services/transaction/transaction_service.dart';

/// Result of attempting to approve a [PendingTransaction].
///
/// Approval can fail for reasons the UI needs to react to (missing
/// category/source, invalid amount, referenced records deleted since
/// the SMS was parsed), so this is returned instead of throwing.
class PendingApprovalResult {
  final bool success;
  final String? error;

  const PendingApprovalResult.success() : success = true, error = null;

  const PendingApprovalResult.failure(this.error) : success = false;
}

class PendingTransactionService extends ChangeNotifier {
  PendingTransactionService({
    PendingTransactionRepository? repository,
    TransactionService? transactionService,
  }) : _repository = repository ?? PendingTransactionRepository(),
       _transactionService = transactionService ?? TransactionService();

  final PendingTransactionRepository _repository;
  final TransactionService _transactionService;

  List<PendingTransaction> get pendingTransactions {
    final transactions = _repository.getByStatus(
      PendingTransactionStatus.pending,
    );

    transactions.sort((a, b) => b.smsDate.compareTo(a.smsDate));

    return transactions;
  }

  int get pendingCount => pendingTransactions.length;

  PendingTransaction? getById(String id) => _repository.getById(id);

  Future<void> update(PendingTransaction transaction) async {
    transaction.updatedAt = DateTime.now();
    await _repository.save(transaction);
    notifyListeners();
  }

  Future<void> reject(PendingTransaction transaction) async {
    transaction.status = PendingTransactionStatus.rejected;
    transaction.updatedAt = DateTime.now();
    transaction.reviewedAt = DateTime.now();

    await transaction.save();

    notifyListeners();
  }

  /// Approves [transaction], creating a real [Transaction] record and
  /// applying its effect to the relevant source balance(s).
  ///
  /// Requires [PendingTransaction.amount] and [PendingTransaction.sourceId]
  /// to be set, plus [PendingTransaction.categoryId] for income/expense
  /// or [PendingTransaction.destinationSourceId] for transfers. The
  /// review sheet is responsible for letting the user fill these in
  /// before calling this.
  Future<PendingApprovalResult> approve(PendingTransaction transaction) async {
    final amount = transaction.amount;

    if (amount == null || amount <= 0) {
      return const PendingApprovalResult.failure(
        'Enter a valid amount before approving.',
      );
    }

    if (transaction.sourceId == null || transaction.sourceId!.isEmpty) {
      return const PendingApprovalResult.failure(
        'Select a source before approving.',
      );
    }

    final type = _resolveType(transaction.transactionType);

    try {
      if (type == TransactionType.transfer) {
        final destinationId = transaction.destinationSourceId;

        if (destinationId == null || destinationId.isEmpty) {
          return const PendingApprovalResult.failure(
            'Select a destination source before approving.',
          );
        }

        await _transactionService.createTransfer(
          amount: amount,
          date: transaction.transactionDate ?? transaction.smsDate,
          note: transaction.note ?? transaction.description ?? '',
          fromSourceId: transaction.sourceId!,
          toSourceId: destinationId,
        );
      } else {
        if (transaction.categoryId == null || transaction.categoryId!.isEmpty) {
          return const PendingApprovalResult.failure(
            'Select a category before approving.',
          );
        }

        final category = Boxes.getCategories().get(transaction.categoryId);

        if (category == null) {
          return const PendingApprovalResult.failure(
            'The selected category no longer exists.',
          );
        }

        await _transactionService.createSimpleTransaction(
          amount: amount,
          date: transaction.transactionDate ?? transaction.smsDate,
          note: transaction.note ?? transaction.description ?? '',
          category: category,
          sourceId: transaction.sourceId!,
          type: type,
        );
      }
    } on TransactionServiceException catch (e) {
      return PendingApprovalResult.failure(e.message);
    } catch (_) {
      return const PendingApprovalResult.failure(
        'Something went wrong while approving this transaction.',
      );
    }

    transaction.status = PendingTransactionStatus.approved;
    transaction.updatedAt = DateTime.now();
    transaction.reviewedAt = DateTime.now();

    await transaction.save();

    notifyListeners();

    return const PendingApprovalResult.success();
  }

  Future<void> delete(PendingTransaction transaction) async {
    await _repository.delete(transaction.id);
    notifyListeners();
  }

  TransactionType _resolveType(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'income':
      case 'credit':
      case 'credited':
        return TransactionType.income;
      case 'transfer':
        return TransactionType.transfer;
      case 'expense':
      case 'debit':
      case 'debited':
        return TransactionType.expense;
      default:
        return TransactionType.expense;
    }
  }
}
