import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:wallet/core/boxes.dart';
import 'package:wallet/core/category_icons.dart';
import 'package:wallet/core/source_icons.dart';
import 'package:wallet/data/models/category.dart';
import 'package:wallet/data/models/source.dart';
import 'package:wallet/data/models/transaction.dart';
import 'package:wallet/data/models/transaction_type.dart';
import 'package:wallet/presentation/screens/add_category.dart';
import 'package:wallet/presentation/screens/add_source_screen.dart';
import 'package:wallet/presentation/widgets/amount_feild.dart';
import 'package:wallet/presentation/widgets/type_selector.dart';
import 'package:wallet/presentation/widgets/universal_grid_selector.dart';

class InputScreen extends StatefulWidget {
  final bool isSmsTransaction;
  final Transaction? editTransaction;

  const InputScreen({
    super.key,
    this.editTransaction,
    this.isSmsTransaction = false,
  });

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final formKey = GlobalKey<FormState>();
  final DateFormat _dateFormat = DateFormat('EEE, dd MMM yyyy');

  late TextEditingController amountController;
  late TextEditingController notesController;

  TransactionType selectedType = TransactionType.expense;

  Category? selectedCategory;
  Source? selectedSource;
  Source? transferDestSource;

  DateTime selectedDate = DateTime.now();

  bool get isEditing => widget.editTransaction != null;

  @override
  void initState() {
    super.initState();

    amountController = TextEditingController();
    notesController = TextEditingController();

    if (widget.editTransaction != null) {
      final tx = widget.editTransaction!;

      amountController.text = tx.amount.toString();
      notesController.text = tx.note;
      selectedDate = tx.createdDate;
      selectedType = tx.type;

      selectedCategory = tx.category;
      selectedSource = tx.source;
      transferDestSource = tx.destinationSource;
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  void _saveTransaction() {
    if (!formKey.currentState!.validate()) return;
    final now = DateTime.now();

    // Calculate total amount from potential comma-separated entries
    final double amount = amountController.text
        .split(',')
        .map((e) => double.tryParse(e.trim()) ?? 0)
        .fold(0, (a, b) => a + b);

    final String note = notesController.text.trim();

    // 1. REVERT OLD BALANCE FIRST (If Editing)
    // We must undo the old transaction's impact before applying the new one.
    if (isEditing &&
        widget.editTransaction != null &&
        !widget.isSmsTransaction) {
      _revertOldBalance(widget.editTransaction!);
    }

    // 2. APPLY NEW TRANSACTION LOGIC
    if (selectedType == TransactionType.transfer) {
      if (selectedSource == null || transferDestSource == null) {
        _showSnackBar("Select both sources");
        return;
      }

      if (selectedSource!.id == transferDestSource!.id) {
        _showSnackBar("Cannot transfer to same source");
        return;
      }

      final tx = Transaction(
        id: isEditing ? widget.editTransaction!.id : const Uuid().v4(),
        amount: amount,
        createdDate: selectedDate,
        note: note,
        category: Category(
          id: 'transfer',
          name: 'Transfer',
          iconIndex: 0,
          colorValue: Colors.blue.toARGB32(),
        ),
        source: selectedSource!,
        destinationSource: transferDestSource!,
        type: TransactionType.transfer,
        smsHash: widget.isSmsTransaction ? widget.editTransaction?.smsHash : null,
      );

      // Update balances for both accounts in a transfer

      final sourceBox = Boxes.getSources();

      final from = sourceBox.get(selectedSource!.id);
      final to = sourceBox.get(transferDestSource!.id);

      if (from == null || to == null) return;

      from.balance -= amount;
      to.balance += amount;

      from.lastUpdated = now;
      to.lastUpdated = now;

      from.save();
      to.save();
      Boxes.getTransactions().put(tx.id, tx);
    } else {
      // NORMAL TRANSACTION (Income or Expense)
      if (selectedCategory == null || selectedSource == null) {
        _showSnackBar("Select category & source");
        return;
      }

      final tx = Transaction(
        id: isEditing ? widget.editTransaction!.id : const Uuid().v4(),
        amount: amount,
        createdDate: selectedDate,
        note: note,
        category: selectedCategory!,
        source: selectedSource!,
        type: selectedType,
        smsHash: widget.isSmsTransaction ? widget.editTransaction?.smsHash : null,
      );

      final sourceBox = Boxes.getSources();
      final source = sourceBox.get(selectedSource!.id);

      if (source == null) {
        _showSnackBar("Source not found");
        return;
      }
      if (selectedType == TransactionType.income) {
        source.balance += amount;
      } else {
        source.balance -= amount;
      }

      source.lastUpdated = now;
      source.save();
      Boxes.getTransactions().put(tx.id, tx);
    }

    _showSnackBar(
      isEditing && !widget.isSmsTransaction
          ? "Transaction Updated!"
          : "Transaction Saved!",
    );
    Navigator.pop(context);
  }

  void _revertOldBalance(Transaction oldTx) {
    final sourceBox = Boxes.getSources();
    final now = DateTime.now();

    // Fetch fresh instances to ensure we aren't using stale memory references.
    final source = sourceBox.get(oldTx.source.id);
    if (source == null) return;

    if (oldTx.type == TransactionType.transfer) {
      final dest = sourceBox.get(oldTx.destinationSource?.id);
      if (dest == null) return;

      // Undo the transfer: Add back to sender, subtract from receiver.
      source.balance += oldTx.amount;
      dest.balance -= oldTx.amount;

      source.lastUpdated = now;
      dest.lastUpdated = now;
      source.save();
      dest.save();
    } else {
      // Undo normal transaction
      if (oldTx.type == TransactionType.income) {
        source.balance -= oldTx.amount;
      } else {
        source.balance += oldTx.amount;
      }
      source.lastUpdated = now;
      source.save();
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final bool isTransfer = selectedType == TransactionType.transfer;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing && !widget.isSmsTransaction
              ? "Edit Transaction"
              : "Add Transaction",
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveTransaction,
        icon: const Icon(Icons.check),
        label: Text(isEditing && !widget.isSmsTransaction ? "Update" : "Save"),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              // const SizedBox(height: 30),
              AmountField(controller: amountController),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 20,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _dateFormat.format(selectedDate),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TypeSelector(
                  selectedType: selectedType,
                  onChanged: (t) {
                    if (isEditing &&
                        widget.editTransaction?.type ==
                            TransactionType.transfer) {
                      _showSnackBar("Transfer cannot be edited");
                      return;
                    }

                    setState(() {
                      selectedType = t;
                      if (t == TransactionType.transfer) {
                        selectedCategory = null;
                      }
                    });
                  },
                ),
              ),

              const SizedBox(height: 24),

              if (isTransfer) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "From Source",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                UniversalGridSelector<Source>(
                  listenable: Boxes.getSources().listenable(),
                  selectedItem: selectedSource,
                  labelBuilder: (s) => s.name,
                  idBuilder: (s) => s.id,
                  iconBuilder: (s) => SourceIcons.icons[s.iconIndex],
                  colorBuilder: (s) => Color(s.colorValue),
                  activeColor: Colors.black87,
                  enableMoreButton: true,
                  onSelect: (s) => setState(() => selectedSource = s),
                  onAdd: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddSourceScreen()),
                  ),
                ),

                const SizedBox(height: 24),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "To Source",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                UniversalGridSelector<Source>(
                  listenable: Boxes.getSources().listenable(),
                  selectedItem: transferDestSource,
                  labelBuilder: (s) => s.name,
                  idBuilder: (s) => s.id,
                  iconBuilder: (s) => SourceIcons.icons[s.iconIndex],
                  colorBuilder: (s) => Color(s.colorValue),
                  activeColor: Colors.black87,
                  enableMoreButton: true,
                  onSelect: (s) => setState(() => transferDestSource = s),
                  onAdd: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddSourceScreen()),
                  ),
                ),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Category",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                UniversalGridSelector<Category>(
                  listenable: Boxes.getCategories().listenable(),
                  selectedItem: selectedCategory,
                  labelBuilder: (c) => c.name,
                  idBuilder: (c) => c.id,
                  iconBuilder: (c) => CategoryIcons.icons[c.iconIndex],
                  colorBuilder: (c) => Color(c.colorValue ?? 0xFF2196F3),
                  activeColor: Colors.blue.shade700,
                  onSelect: (c) => setState(() => selectedCategory = c),
                  onAdd: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddCategoryScreen(),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Source",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                UniversalGridSelector<Source>(
                  listenable: Boxes.getSources().listenable(),
                  selectedItem: selectedSource,
                  labelBuilder: (s) => s.name,
                  idBuilder: (s) => s.id,
                  iconBuilder: (s) => SourceIcons.icons[s.iconIndex],
                  colorBuilder: (s) => Color(s.colorValue),
                  activeColor: Colors.black87,
                  onSelect: (s) => setState(() => selectedSource = s),
                  onAdd: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddSourceScreen()),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  textCapitalization: TextCapitalization.sentences,
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: "Notes (Optional)",

                    filled: true,
                    fillColor: Colors.grey.shade200.withValues(alpha: 0.5),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300.withValues(alpha: 1.0),
                      ),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blueGrey.shade100),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blueGrey.shade300,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
