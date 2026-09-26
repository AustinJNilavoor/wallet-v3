import 'package:flutter/material.dart';

import 'package:wallet/data/models/pending_transaction.dart';
import 'package:wallet/services/sms/pending_transaction_service.dart';
import 'package:wallet/presentation/widgets/pending_transaction_card.dart';
import 'package:wallet/presentation/widgets/pending_transaction_review_sheet.dart';

class PendingTransactionsScreen
    extends StatefulWidget {
  const PendingTransactionsScreen({
    super.key,
  });

  @override
  State<PendingTransactionsScreen>
      createState() =>
          _PendingTransactionsScreenState();
}

class _PendingTransactionsScreenState
    extends State<
        PendingTransactionsScreen> {
  final PendingTransactionService
      _service =
      PendingTransactionService();

  @override
  void initState() {
    super.initState();

    _service.addListener(
      _refresh,
    );
  }

  @override
  void dispose() {
    _service.removeListener(
      _refresh,
    );

    _service.dispose();

    super.dispose();
  }

  void _refresh() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final transactions =
        _service.pendingTransactions;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pending Transactions'
          '${transactions.isEmpty ? '' : ' (${transactions.length})'}',
        ),
      ),
      body: transactions.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: ListView.builder(
                padding:
                    const EdgeInsets.only(
                  top: 8,
                  bottom: 24,
                ),
                itemCount:
                    transactions.length,
                itemBuilder:
                    (context, index) {
                  final transaction =
                      transactions[index];

                  return PendingTransactionCard(
                    transaction:
                        transaction,
                    onTap: () {
                      _openReview(
                        transaction,
                      );
                    },
                    onApprove: () {
                      _approve(
                        transaction,
                      );
                    },
                    onReject: () {
                      _reject(
                        transaction,
                      );
                    },
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 72,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),

            const SizedBox(height: 20),

            Text(
              'No Pending Transactions',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight:
                        FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 8),

            Text(
              'Transactions parsed from SMS '
              'will appear here for approval.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(
    PendingTransaction transaction,
  ) async {
    final result = await _service.approve(
      transaction,
    );

    if (!mounted) {
      return;
    }

    if (result.success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Transaction approved',
          ),
        ),
      );
      return;
    }

    // Missing details (category/source/etc): let the user fill
    // them in via the review sheet instead of failing silently.
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          result.error ??
              'Could not approve this transaction.',
        ),
      ),
    );

    _openReview(transaction);
  }

  Future<void> _reject(
    PendingTransaction transaction,
  ) async {
    final confirmed =
        await _showRejectDialog();

    if (!confirmed) {
      return;
    }

    await _service.reject(
      transaction,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Transaction rejected',
        ),
      ),
    );
  }

  Future<void> _openReview(
    PendingTransaction transaction,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) {
        return PendingTransactionReviewSheet(
          transaction: transaction,
          onApprove:
              _service.approve,
          onReject:
              _service.reject,
        );
      },
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<bool> _showRejectDialog() async {
    final result =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Reject transaction?',
          ),
          content: const Text(
            'This SMS transaction will not '
            'be added to your wallet.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
                  const Text('Reject'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}