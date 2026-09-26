import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:wallet/core/boxes.dart';
import 'package:wallet/core/category_icons.dart';
import 'package:wallet/core/source_icons.dart';
import 'package:wallet/data/models/transaction.dart';
import 'package:wallet/data/models/transaction_type.dart';
import 'package:wallet/presentation/screens/input_screen.dart';
import 'package:wallet/presentation/widgets/delete_dialog.dart';
import 'package:wallet/services/transaction/transaction_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _selectedDate = DateTime.now();
  final format = NumberFormat('##,##,##0.00');
  final TransactionService _transactionService = TransactionService();

  void _changeMonth(int value) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + value);
    });
  }

  Future<void> _handleDelete(Transaction tx) async {
    try {
      await _transactionService.deleteAndRevert(tx);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete transaction')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "History",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<Box<Transaction>>(
        valueListenable: Boxes.getTransactions().listenable(),
        builder: (context, box, _) {
          final all = box.values.toList();
          final filtered = all.where((tx) {
            return tx.createdDate.year == _selectedDate.year &&
                tx.createdDate.month == _selectedDate.month;
          }).toList();

          final grouped = _groupTransactions(filtered);
          final keys = grouped.keys.toList();

          final totalIncome = filtered
              .where((e) => e.type == TransactionType.income)
              .fold(0.0, (s, e) => s + e.amount);

          final totalExpense = filtered
              .where((e) => e.type == TransactionType.expense)
              .fold(0.0, (s, e) => s + e.amount);

          return Column(
            children: [
              _buildMonthHeader(),
              _buildSummaryRow(totalIncome, totalExpense),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : _buildTransactionList(keys, grouped),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthHeader() {
    final label = DateFormat('MMM yyyy').format(_selectedDate);
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        
        if (details.primaryVelocity! > 0) {
          // Swiped Right -> Previous Month
          _changeMonth(-1);
        } else if (details.primaryVelocity! < 0) {
          // Swiped Left -> Next Month
          _changeMonth(1);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => _changeMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            IconButton(
              onPressed: () => _changeMonth(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(double income, double expense) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildSummaryCard("Income", income, Colors.green),
          const SizedBox(width: 12),
          _buildSummaryCard("Expense", expense, Colors.red),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "₹ ${format.format(amount)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(
    List<String> keys,
    Map<String, List<Transaction>> grouped,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: keys.length,
      itemBuilder: (_, index) {
        final key = keys[index];
        final list = grouped[key]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                key,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            ...list.map(_buildTransactionItem),
          ],
        );
      },
    );
  }

  Widget _buildTransactionItem(Transaction tx) {
    final bool isTransfer = tx.destinationSource != null;
    final Color categoryColor = Color(tx.category.colorValue ?? 0xFF9E9E9E);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => InputScreen(editTransaction: tx)),
      ),
      onLongPress: () async {
        HapticFeedback.mediumImpact();
        final confirm = await DeleteDialog.show(
          context,
          title: "Delete",
          message:
              "Delete this transaction? This will revert the source balances.",
        );

        if (confirm) {
          await _handleDelete(tx);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5),
          ],
        ),
        child: Row(
          children: [
            // Icon with Colored Background
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isTransfer
                    ? Icons.swap_horiz
                    : CategoryIcons.icons[tx.category.iconIndex],
                color: categoryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.category.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Source Differentiation
                  Row(
                    children: [
                      Icon(
                        SourceIcons.icons[tx.source.iconIndex],
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tx.source.name,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      if (isTransfer && tx.destinationSource != null) ...[
                        Icon(
                          Icons.arrow_right_alt,
                          size: 14,
                          color: Colors.grey[400],
                        ),
                        Icon(
                          SourceIcons.icons[tx.destinationSource!.iconIndex],
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tx.destinationSource!.name,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (tx.note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        tx.note,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  " ₹ ${format.format(tx.amount)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isTransfer
                        ? Colors.blue
                        : (tx.type == TransactionType.income
                              ? Colors.green
                              : Colors.red),
                  ),
                ),
                Text(
                  DateFormat('hh:mm a').format(tx.createdDate),
                  style: TextStyle(color: Colors.grey[400], fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<Transaction>> _groupTransactions(List<Transaction> list) {
    list.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    final Map<String, List<Transaction>> grouped = {};
    for (var tx in list) {
      final key = _getDateHeader(tx.createdDate);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    return grouped;
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final check = DateTime(date.year, date.month, date.day);
    if (check == today) return "Today";
    if (check == yesterday) return "Yesterday";
    return DateFormat('EEE, dd MMM yyyy').format(date);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No transactions this month",
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
