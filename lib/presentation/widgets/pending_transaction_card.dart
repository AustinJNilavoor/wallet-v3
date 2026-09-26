import 'package:flutter/material.dart';

import 'package:wallet/core/boxes.dart';
import 'package:wallet/data/models/pending_transaction.dart';

class PendingTransactionCard extends StatelessWidget {
  final PendingTransaction transaction;

  final VoidCallback onTap;

  final VoidCallback onApprove;

  final VoidCallback onReject;

  const PendingTransactionCard({
    super.key,
    required this.transaction,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final amount =
        transaction.amount;

    final merchant =
        transaction.merchant?.trim();

    final title =
        merchant != null &&
                merchant.isNotEmpty
            ? merchant
            : 'SMS Transaction';

    final date =
        _formatDate(
      transaction.transactionDate ??
          transaction.smsDate,
    );

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Icon(
                      _getTransactionIcon(
                        transaction.transactionType,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: theme
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight:
                                    FontWeight.w600,
                              ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          date,
                          style: theme
                              .textTheme
                              .bodySmall,
                        ),
                      ],
                    ),
                  ),

                  if (amount != null)
                    Text(
                      _formatAmount(amount),
                      style: theme
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                          ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              if (transaction.accountNumber !=
                  null)
                _InfoRow(
                  label: 'Account',
                  value:
                      transaction.accountNumber!,
                ),

              if (transaction.categoryId !=
                  null)
                _InfoRow(
                  label: 'Category',
                  value:
                      Boxes.getCategories()
                          .get(transaction.categoryId)
                          ?.name ??
                      'Unknown category',
                ),

              if (transaction.sourceId !=
                  null)
                _InfoRow(
                  label: 'Source',
                  value:
                      Boxes.getSources()
                          .get(transaction.sourceId)
                          ?.name ??
                      'Unknown source',
                ),

              if (transaction.parsingSuccessful ==
                  false)
                Padding(
                  padding:
                      const EdgeInsets.only(
                    top: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        size: 18,
                        color: theme
                            .colorScheme
                            .error,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Some fields could not be parsed',
                          style: theme
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: theme
                                    .colorScheme
                                    .error,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(
                      Icons.close,
                    ),
                    label:
                        const Text('Reject'),
                  ),

                  const SizedBox(width: 8),

                  FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(
                      Icons.check,
                    ),
                    label:
                        const Text('Approve'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTransactionIcon(
    String? type,
  ) {
    switch (type?.toLowerCase()) {
      case 'income':
      case 'credit':
      case 'credited':
        return Icons.arrow_downward;

      case 'expense':
      case 'debit':
      case 'debited':
        return Icons.arrow_upward;

      case 'transfer':
        return Icons.swap_horiz;

      default:
        return Icons.receipt_long;
    }
  }

  String _formatAmount(
    double amount,
  ) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _formatDate(
    DateTime date,
  ) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    final year =
        date.year.toString();

    final hour =
        date.hour.toString().padLeft(2, '0');

    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                    fontWeight:
                        FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}