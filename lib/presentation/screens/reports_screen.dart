import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:wallet/core/boxes.dart';
import 'package:wallet/data/models/transaction.dart';
import 'package:wallet/data/models/transaction_type.dart';

enum ReportFilter { today, week, month, custom }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportFilter _selectedFilter = ReportFilter.month;
  final format = NumberFormat('##,##,##0.00');
  double _calculateTotalDebt() {
    final sourceBox = Boxes.getSources();
    // Filter for credit cards and sum their absolute balance (since debt is usually negative)
    return sourceBox.values
        .where((source) => source.isCreditCard)
        .fold(0.0, (sum, source) => sum + source.balance.abs());
  }

  DateTimeRange _customRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Reports",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterChips(),

          Expanded(
            child: ValueListenableBuilder<Box<Transaction>>(
              valueListenable: Boxes.getTransactions().listenable(),
              builder: (context, box, _) {
                final transactions = _filterTransactions(box.values.toList());

                if (transactions.isEmpty) return _buildEmptyState();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Spend Trend"),
                      _buildLineChartCard(transactions),
                      const SizedBox(height: 32),
                      _buildSectionTitle("Category Breakdown"),
                      _buildCategoryPieCard(transactions),
                      const SizedBox(height: 32),
                      _buildSectionTitle("Income Sources"),
                      _buildIncomeSourceList(transactions),
                      const SizedBox(height: 32),
                      _buildSectionTitle("Current Liabilities"),
                      _buildDebtCard(),
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtCard() {
    final totalDebt = _calculateTotalDebt();
    final creditSources = Boxes.getSources().values
        .where((s) => s.isCreditCard)
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Credit Card Debt",
                style: TextStyle(color: Colors.grey[600]),
              ),
              const Icon(Icons.credit_card, color: Colors.redAccent, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "₹${format.format(totalDebt)}",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          ...creditSources
              .map(
                (source) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Color(source.colorValue),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              source.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (source.creditLimit != null)
                              Text(
                                "Limit: ₹${format.format(source.creditLimit)}",
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        "₹${format.format(source.balance.abs())}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  // 🔥 FILTER
  List<Transaction> _filterTransactions(List<Transaction> all) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (_selectedFilter) {
      case ReportFilter.today:
        start = DateTime(
          now.year,
          now.month,
          now.subtract(const Duration(seconds: 1)).day,
        );
        break;
      case ReportFilter.week:
        start = now.subtract(Duration(days: now.weekday));
        break;
      case ReportFilter.month:
        start = DateTime(now.year, now.month, 1);
        break;
      case ReportFilter.custom:
        start = _customRange.start.subtract(const Duration(seconds: 1));
        end = _customRange.end;
        break;
    }

    return all
        .where(
          (tx) =>
              tx.createdDate.isAfter(
                start.subtract(const Duration(seconds: 1)),
              ) &&
              tx.createdDate.isBefore(end.add(const Duration(days: 1))),
        )
        .toList();
  }

  // 🔥 GRAPH FIXED HERE
  List<FlSpot> _generateTrendData(List<Transaction> txs) {
    final expenses = txs
        .where((t) => t.type == TransactionType.expense)
        .toList();

    if (expenses.isEmpty) return [const FlSpot(0, 0)];

    // Group by full date
    final Map<DateTime, double> daily = {};

    for (var tx in expenses) {
      final date = DateTime(
        tx.createdDate.year,
        tx.createdDate.month,
        tx.createdDate.day,
      );

      daily.update(date, (v) => v + tx.amount, ifAbsent: () => tx.amount);
    }

    final sortedDates = daily.keys.toList()..sort();

    // 🔥 Fill missing days (VERY IMPORTANT)
    final start = sortedDates.first;
    final end = sortedDates.last;

    final List<DateTime> allDays = [];
    for (int i = 0; i <= end.difference(start).inDays; i++) {
      allDays.add(start.add(Duration(days: i)));
    }

    return List.generate(allDays.length, (index) {
      final date = allDays[index];
      return FlSpot(index.toDouble(), daily[date] ?? 0);
    });
  }

  // 📈 LINE CHART
  Widget _buildLineChartCard(List<Transaction> txs) {
    final totalSpend = txs
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Total Spending", style: TextStyle(color: Colors.grey[600])),
          Text(
            "₹${format.format(totalSpend)}",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                gridData: FlGridData(show: true),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateTrendData(txs),
                    isCurved: true,
                    color: Colors.blueAccent,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🥧 PIE
  Widget _buildCategoryPieCard(List<Transaction> txs) {
    final expenseTxs = txs
        .where((t) => t.type == TransactionType.expense)
        .toList();

    final Map<String, double> map = {};
    final Map<String, Color> colors = {};

    for (var tx in expenseTxs) {
      map.update(
        tx.category.name,
        (v) => v + tx.amount,
        ifAbsent: () => tx.amount,
      );

      colors.putIfAbsent(
        tx.category.name,
        () => Color(tx.category.colorValue ?? Colors.blue.toARGB32()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: PieChart(
              PieChartData(
                sections: map.entries
                    .map(
                      (e) => PieChartSectionData(
                        value: e.value,
                        color: colors[e.key],
                        title: '',
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: map.entries
                  .map((e) => _legend(e.key, e.value, colors[e.key]!))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeSourceList(List<Transaction> txs) {
    final incomeTxs = txs
        .where((t) => t.type == TransactionType.income)
        .toList();

    final Map<String, double> map = {};

    for (var tx in incomeTxs) {
      map.update(
        tx.source.name,
        (v) => v + tx.amount,
        ifAbsent: () => tx.amount,
      );
    }

    return Column(
      children: map.entries
          .map(
            (e) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: _cardDecoration(),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 10, color: Colors.green),
                  const SizedBox(width: 10),
                  Text(e.key),
                  const Spacer(),
                  Text("₹${format.format(e.value)}"),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // UI helpers
  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
  );

  Widget _buildSectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      t,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  );

  Widget _legend(String l, double v, Color c) => Row(
    children: [
      Container(width: 8, height: 8, color: c),
      const SizedBox(width: 6),
      Expanded(child: Text(l)),
      Text("₹${format.format(v)}"),
    ],
  );

  Widget _buildEmptyState() => const Center(child: Text("No data"));

  // --- 🎨 UI: Filter Row ---
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ReportFilter.values.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                filter.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              selected: isSelected,
              selectedColor: Colors.blueAccent,
              onSelected: (val) async {
                if (filter == ReportFilter.custom) {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (range != null) {
                    setState(() {
                      _customRange = range;
                      _selectedFilter = filter;
                    });
                  }
                } else {
                  setState(() => _selectedFilter = filter);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
