import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:wallet/core/boxes.dart';
import 'package:wallet/data/models/stock.dart';
import 'package:wallet/presentation/widgets/universal_grid_selector.dart';

enum StockAction { buy, sell }

class StocksInputScreen extends StatefulWidget {
  final Stock? initialStock;

  const StocksInputScreen({super.key, this.initialStock});

  @override
  State<StocksInputScreen> createState() => _StocksInputScreenState();
}

class _StocksInputScreenState extends State<StocksInputScreen> {
  final formKey = GlobalKey<FormState>();

  Stock? selectedStock;
  StockAction selectedAction = StockAction.buy;

  final qtyController = TextEditingController();
  final priceController = TextEditingController();
  final chargesController = TextEditingController();

  final format = NumberFormat('##,##,##0.00');

  @override
  void initState() {
    super.initState();
    selectedStock = widget.initialStock;
  }

  @override
  void dispose() {
    qtyController.dispose();
    priceController.dispose();
    chargesController.dispose();
    super.dispose();
  }

  void _applyTransaction() {
    if (selectedStock == null) {
      _showSnackBar("Select stock");
      return;
    }

    final qty = double.tryParse(qtyController.text) ?? 0;
    final price = double.tryParse(priceController.text) ?? 0;
    final charges = double.tryParse(chargesController.text) ?? 0;

    if (qty <= 0 || price <= 0) {
      _showSnackBar("Enter valid values");
      return;
    }

    final stock = selectedStock!;
    final now = DateTime.now();
    if (selectedAction == StockAction.buy) {
      final buyCost = qty * price;
      final totalCost = buyCost + charges;

      final oldQty = stock.totalQty;
      final oldValue = stock.avgPrice * oldQty;

      stock.totalQty += qty;

      stock.avgPrice = stock.totalQty > 0
          ? (oldValue + totalCost) / stock.totalQty
          : 0;

      stock.totalInvestedMoney += totalCost;
      stock.totalCharges += charges;
    } else {
      if (qty > stock.totalQty) {
        _showSnackBar("Not enough quantity");
        return;
      }

      final sellValue = (qty * price) - charges;

      final costRemoved = stock.avgPrice * qty;

      stock.totalQty -= qty;

      stock.totalReturnedMoney += sellValue;
      stock.totalCharges += charges;

      stock.totalInvestedMoney -= costRemoved;

      stock.realizedProfit += (sellValue - costRemoved);
    }
    stock.lastUpdated = now;
    stock.save();

    _showSnackBar("Updated successfully");
    Navigator.pop(context);
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showAddStockDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Stock"),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: "Stock Name / Symbol"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) return;

                final stock = Stock(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  totalQty: 0,
                  totalInvestedMoney: 0,
                  totalReturnedMoney: 0,
                  totalCharges: 0,
                  avgPrice: 0,
                  realizedProfit: 0,
                  lastUpdated: DateTime.now(),
                );

                Boxes.getStocks().put(stock.id, stock);

                Navigator.pop(context);
                _showSnackBar("Stock added");
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stock Entry"), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _applyTransaction,
        icon: const Icon(Icons.check),
        label: const Text("Apply"),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              const SizedBox(height: 12),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Stock",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),

              UniversalGridSelector<Stock>(
                onAdd: _showAddStockDialog,
                listenable: Boxes.getStocks().listenable(),
                selectedItem: selectedStock,
                labelBuilder: (s) => s.name,
                idBuilder: (s) => s.id,
                iconBuilder: (_) => Icons.show_chart,
                colorBuilder: (_) => Colors.teal,
                activeColor: Colors.black87,
                onSelect: (s) => setState(() => selectedStock = s),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTypeButton(
                        "BUY",
                        selectedAction == StockAction.buy,
                        Colors.green,
                        () => setState(() => selectedAction = StockAction.buy),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTypeButton(
                        "SELL",
                        selectedAction == StockAction.sell,
                        Colors.red,
                        () => setState(() => selectedAction = StockAction.sell),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _buildInputField("Quantity", qtyController),

              _buildInputField("Price per Qty", priceController),

              _buildInputField("Tax + Brokerage", chargesController),

              const SizedBox(height: 12),

              if (selectedStock != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Current Avg: ₹ ${format.format(selectedStock!.avgPrice)}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(
    String text,
    bool isSelected,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? color : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade200,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
