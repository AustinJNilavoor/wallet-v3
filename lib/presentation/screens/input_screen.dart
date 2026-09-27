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

/// Pure UI screen for creating/editing a transaction by hand.
///
/// This screen does not know how balances are calculated — it just
/// collects the fields and hands them to [TransactionService]. That's
/// what lets an SMS-import flow (or anything else) reuse the exact
/// same create/edit logic without going through this widget.
class InputScreen extends StatefulWidget {
  final Transaction? editTransaction;

  const InputScreen({super.key, this.editTransaction});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('EEE, dd MMM yyyy');
  final _transactionService = TransactionService();

  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  TransactionType _selectedType = TransactionType.expense;
  Category? _selectedCategory;
  Source? _selectedSource;
  Source? _transferDestSource;
  DateTime _selectedDate = DateTime.now();

  bool _isSaving = false;

  bool get _isEditing => widget.editTransaction != null;

  @override
  void initState() {
    super.initState();

    final tx = widget.editTransaction;

    _amountController = TextEditingController(text: tx?.amount.toString() ?? '');
    _notesController = TextEditingController(text: tx?.note ?? '');

    if (tx != null) {
      _selectedDate = tx.createdDate;
      _selectedType = tx.type;
      _selectedCategory = tx.category;
      _selectedSource = tx.source;
      _transferDestSource = tx.destinationSource;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    final amount = _amountController.text
        .split(',')
        .map((e) => double.tryParse(e.trim()) ?? 0)
        .fold(0.0, (a, b) => a + b);

    final note = _notesController.text.trim();
    final isTransfer = _selectedType == TransactionType.transfer;

    if (isTransfer && (_selectedSource == null || _transferDestSource == null)) {
      _showSnackBar('Select both sources');
      return;
    }
    if (!isTransfer && (_selectedCategory == null || _selectedSource == null)) {
      _showSnackBar('Select category & source');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Undo the old transaction's balance effect before applying the
      // new one, when editing.
      if (_isEditing) {
        await _transactionService.revert(widget.editTransaction!);
      }

      if (isTransfer) {
        await _transactionService.createTransfer(
          id: _isEditing ? widget.editTransaction!.id : null,
          amount: amount,
          date: _selectedDate,
          note: note,
          fromSourceId: _selectedSource!.id,
          toSourceId: _transferDestSource!.id,
        );
      } else {
        await _transactionService.createSimpleTransaction(
          id: _isEditing ? widget.editTransaction!.id : null,
          amount: amount,
          date: _selectedDate,
          note: note,
          category: _selectedCategory!,
          sourceId: _selectedSource!.id,
          type: _selectedType,
        );
      }

      if (!mounted) return;
      _showSnackBar(_isEditing ? 'Transaction Updated!' : 'Transaction Saved!');
      Navigator.pop(context);
    } on TransactionServiceException catch (e) {
      _showSnackBar(e.message);
    } catch (_) {
      _showSnackBar('Failed to save transaction');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isTransfer = _selectedType == TransactionType.transfer;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _save,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check),
        label: Text(_isEditing ? 'Update' : 'Save'),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              AmountField(controller: _amountController),
              _buildDateTile(),
              _buildTypeSelector(),
              const SizedBox(height: 24),
              if (isTransfer) ..._buildTransferSection() else ..._buildCategorySourceSection(),
              _buildNotesField(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTile() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                  const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.blue),
                  const SizedBox(width: 12),
                  Text(
                    _dateFormat.format(_selectedDate),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TypeSelector(
        selectedType: _selectedType,
        onChanged: (t) {
          if (_isEditing && widget.editTransaction?.type == TransactionType.transfer) {
            _showSnackBar('Transfer cannot be edited');
            return;
          }
          setState(() {
            _selectedType = t;
            if (t == TransactionType.transfer) _selectedCategory = null;
          });
        },
      ),
    );
  }

  List<Widget> _buildTransferSection() {
    return [
      _sectionLabel('From Source'),
      const SizedBox(height: 8),
      UniversalGridSelector<Source>(
        listenable: Boxes.getSources().listenable(),
        selectedItem: _selectedSource,
        labelBuilder: (s) => s.name,
        idBuilder: (s) => s.id,
        iconBuilder: (s) => SourceIcons.icons[s.iconIndex],
        colorBuilder: (s) => Color(s.colorValue),
        activeColor: Colors.black87,
        enableMoreButton: true,
        onSelect: (s) => setState(() => _selectedSource = s),
        onAdd: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddSourceScreen()),
        ),
      ),
      const SizedBox(height: 24),
      _sectionLabel('To Source'),
      const SizedBox(height: 8),
      UniversalGridSelector<Source>(
        listenable: Boxes.getSources().listenable(),
        selectedItem: _transferDestSource,
        labelBuilder: (s) => s.name,
        idBuilder: (s) => s.id,
        iconBuilder: (s) => SourceIcons.icons[s.iconIndex],
        colorBuilder: (s) => Color(s.colorValue),
        activeColor: Colors.black87,
        enableMoreButton: true,
        onSelect: (s) => setState(() => _transferDestSource = s),
        onAdd: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddSourceScreen()),
        ),
      ),
    ];
  }

  List<Widget> _buildCategorySourceSection() {
    return [
      _sectionLabel('Category'),
      const SizedBox(height: 8),
      UniversalGridSelector<Category>(
        listenable: Boxes.getCategories().listenable(),
        selectedItem: _selectedCategory,
        labelBuilder: (c) => c.name,
        idBuilder: (c) => c.id,
        iconBuilder: (c) => CategoryIcons.icons[c.iconIndex],
        colorBuilder: (c) => Color(c.colorValue ?? 0xFF2196F3),
        activeColor: Colors.blue.shade700,
        onSelect: (c) => setState(() => _selectedCategory = c),
        onAdd: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddCategoryScreen()),
        ),
      ),
      const SizedBox(height: 24),
      _sectionLabel('Source'),
      const SizedBox(height: 8),
      UniversalGridSelector<Source>(
        listenable: Boxes.getSources().listenable(),
        selectedItem: _selectedSource,
        labelBuilder: (s) => s.name,
        idBuilder: (s) => s.id,
        iconBuilder: (s) => SourceIcons.icons[s.iconIndex],
        colorBuilder: (s) => Color(s.colorValue),
        activeColor: Colors.black87,
        onSelect: (s) => setState(() => _selectedSource = s),
        onAdd: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddSourceScreen()),
        ),
      ),
    ];
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildNotesField() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextFormField(
        textCapitalization: TextCapitalization.sentences,
        controller: _notesController,
        decoration: InputDecoration(
          labelText: 'Notes (Optional)',
          filled: true,
          fillColor: Colors.grey.shade200.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blueGrey.shade100),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blueGrey.shade300, width: 2),
          ),
        ),
      ),
    );
  }
}