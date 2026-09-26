import 'package:hive/hive.dart';

import 'package:wallet/core/boxes.dart';
import 'package:wallet/data/models/pending_transaction.dart';

/// Thin data-access layer around the `pending_transactions` Hive box.
///
/// Keeping Hive access behind a repository means the services/UI layers
/// don't need to know about box names or Hive-specific APIs, and makes
/// it easy to unit test [PendingTransactionService] with a fake box.
class PendingTransactionRepository {
  PendingTransactionRepository({Box<PendingTransaction>? box})
    : _box = box ?? Boxes.getPendingTransactions();

  final Box<PendingTransaction> _box;

  List<PendingTransaction> getAll() => _box.values.toList();

  List<PendingTransaction> getByStatus(PendingTransactionStatus status) {
    return _box.values.where((t) => t.status == status).toList();
  }

  PendingTransaction? getById(String id) => _box.get(id);

  Future<void> save(PendingTransaction transaction) async {
    await _box.put(transaction.id, transaction);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Checks both the provider SMS id and the generated duplicate key.
  bool isKnown({String? smsId, required String duplicateKey}) {
    for (final pending in _box.values) {
      final sameId = smsId != null && smsId.isNotEmpty && pending.smsId == smsId;
      final sameHash = pending.duplicateKey == duplicateKey;

      if (sameId || sameHash) {
        return true;
      }
    }
    return false;
  }
}
