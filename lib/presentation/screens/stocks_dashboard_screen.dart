import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:wallet/core/boxes.dart';
import 'package:wallet/data/models/stock.dart';
import 'package:wallet/presentation/screens/stocks_input_screen.dart';
import 'package:wallet/presentation/widgets/delete_dialog.dart';

class StocksDashboardScreen extends StatefulWidget {
  const StocksDashboardScreen({super.key});

  @override
  State<StocksDashboardScreen> createState() => _StocksDashboardScreenState();
}

class _StocksDashboardScreenState extends State<StocksDashboardScreen> {
  final format = NumberFormat('##,##,##0.00');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StocksInputScreen()),
          );
        },
        child: Icon(Icons.add),
      ),
      appBar: AppBar(
        title: const Text(
          "Stocks",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(children: [_buildHeader(), _buildStockList()]),
    );
  }

  // 🔷 HEADER
  Widget _buildHeader() {
    return ValueListenableBuilder<Box<Stock>>(
      valueListenable: Boxes.getStocks().listenable(),
      builder: (context, box, _) {
        final stocks = box.values.toList();

        double totalInvested = stocks.fold(
          0,
          (sum, s) => sum + s.totalInvestedMoney,
        );

        double totalReturned = stocks.fold(
          0,
          (sum, s) => sum + s.totalReturnedMoney,
        );

        double totalProfit = stocks.fold(0, (sum, s) => sum + s.realizedProfit);

        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade800],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Total Invested",
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                "₹ ${format.format(totalInvested)}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 12),
              const Divider(color: Colors.white24),

              const SizedBox(height: 10),
              Text(
                "Total Returned",
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                "₹ ${format.format(totalReturned)}",
                style: const TextStyle(color: Colors.white),
              ),

              const SizedBox(height: 10),
              Text("Profit", style: const TextStyle(color: Colors.white70)),
              Text(
                "₹ ${format.format(totalProfit)}",
                style: TextStyle(
                  color: totalProfit >= 0
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔷 STOCK LIST
  Widget _buildStockList() {
    return ValueListenableBuilder<Box<Stock>>(
      valueListenable: Boxes.getStocks().listenable(),
      builder: (context, box, _) {
        final stocks = box.values.toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        if (stocks.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                "No stocks yet. Tap + to add one.",
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(stocks.length, (index) {
              final stock = stocks[index];

              return SizedBox(
                key: ValueKey(stock.id),
                width: MediaQuery.of(context).size.width / 2 - 20,
                height: 150,
                child: _buildStockCard(stock),
              );
            }),
          ),
        );
      },
    );
  }

  Future<void> _deleteStock(Stock stock) async {
    final confirm = await DeleteDialog.show(
      context,
      title: "Delete Stock",
      message:
          "Delete \"${stock.name}\"? This does not affect past wallet transactions.",
    );

    if (confirm) {
      await Boxes.getStocks().delete(stock.id);
    }
  }

  // 🔷 STOCK CARD
  Widget _buildStockCard(Stock stock) {
    final isProfit = stock.realizedProfit >= 0;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StocksInputScreen(initialStock: stock),
          ),
        );
      },
      onLongPress: () => _deleteStock(stock),
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🏷️ Name
          Text(
            stock.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          // 💰 Invested
          Text(
            "₹ ${format.format(stock.totalInvestedMoney)}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          // 📦 Qty + Avg
          Text("Qty: ${stock.totalQty}", style: const TextStyle(fontSize: 12)),
          Text(
            "Avg: ₹ ${format.format(stock.avgPrice)}",
            style: const TextStyle(fontSize: 12),
          ),

          const Spacer(),

          // 📊 Profit
          Text(
            "P/L: ₹ ${format.format(stock.realizedProfit)}",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isProfit ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
