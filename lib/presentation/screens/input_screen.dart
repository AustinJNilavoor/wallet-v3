import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
import 'package:wallet/services/transaction/transaction_service.dart';

class InputScreen extends StatefulWidget {
  final Transaction? editTransaction;

  const InputScreen({super.key, this.editTransaction});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final formKey = GlobalKey<FormState>();
  final DateFormat _dateFormat = DateFormat('EEE, dd MMM yyyy');
  final TransactionService _transactionService = TransactionService();
  bool _isSaving = false;

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

  Future<void> _saveTransaction() async {
    if (!formKey.currentState!.validate()) return;
    if (_isSaving) return;

    // Calculate total amount from potential comma-separated entries
    final double amount = amountController.text
        .split(',')
        .map((e) => double.tryParse(e.trim()) ?? 0)
        .fold(0, (a, b) => a + b);

    if (amount <= 0) {
      _showSnackBar("Enter a valid amount");
      return;
    }

    final String note = notesController.text.trim();

    setState(() => _isSaving = true);

    try {
      // 1. REVERT OLD BALANCE FIRST (If Editing)
      // We must undo the old transaction's impact before applying the new one.
      if (isEditing && widget.editTransaction != null) {
        await _transactionService.revert(widget.editTransaction!);
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

        await _transactionService.createTransfer(
          id: isEditing ? widget.editTransaction!.id : null,
          amount: amount,
          date: selectedDate,
          note: note,
          fromSourceId: selectedSource!.id,
          toSourceId: transferDestSource!.id,
        );
      } else {
        // NORMAL TRANSACTION (Income or Expense)
        if (selectedCategory == null || selectedSource == null) {
          _showSnackBar("Select category & source");
          return;
        }

        await _transactionService.createSimpleTransaction(
          id: isEditing ? widget.editTransaction!.id : null,
          amount: amount,
          date: selectedDate,
          note: note,
          category: selectedCategory!,
          sourceId: selectedSource!.id,
          type: selectedType,
        );
      }

      if (!mounted) return;
      _showSnackBar(isEditing ? "Transaction Updated!" : "Transaction Saved!");
      Navigator.pop(context);
    } on TransactionServiceException catch (e) {
      _showSnackBar(e.message);
    } catch (e) {
      _showSnackBar("Failed to save transaction");
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
        title: Text(isEditing ? "Edit Transaction" : "Add Transaction"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveTransaction,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check),
        label: Text(isEditing ? "Update" : "Save"),
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
