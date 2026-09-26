import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:wallet/core/app_colors.dart';
import 'package:wallet/core/boxes.dart';
import 'package:wallet/core/source_icons.dart';
import 'package:wallet/data/models/source.dart';

class AddSourceScreen extends StatefulWidget {
  final Source? editSource;

  const AddSourceScreen({super.key, this.editSource});

  @override
  State<AddSourceScreen> createState() => _AddSourceScreenState();
}

class _AddSourceScreenState extends State<AddSourceScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController balanceController = TextEditingController();
  final TextEditingController creditLimitController = TextEditingController();

  final ValueNotifier<int> _selectedIcon = ValueNotifier(0);
  final ValueNotifier<int> _selectedColor = ValueNotifier(
    AppColors.palette.first.toARGB32(),
  );

  final Uuid _uuid = const Uuid();

  bool isIncludedInTotal = true;
  bool isCreditCard = false;

  bool get isEditing => widget.editSource != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final s = widget.editSource!;
      nameController.text = s.name;
      balanceController.text = s.balance.toString();
      creditLimitController.text = (s.creditLimit ?? 0).toString();
      _selectedIcon.value = s.iconIndex;
      _selectedColor.value = s.colorValue;
      isIncludedInTotal = s.isIncludedInTotal;
      isCreditCard = s.isCreditCard;
    } else {
      balanceController.text = "0.00";
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    balanceController.dispose();
    creditLimitController.dispose();
    _selectedIcon.dispose();
    _selectedColor.dispose();
    super.dispose();
  }

  Future<void> _saveSource() async {
    if (!_formKey.currentState!.validate()) return;

    final name = nameController.text.trim();
    final balance = double.tryParse(balanceController.text.trim()) ?? 0.0;
    double creditLimit = 0.0;
    if (isCreditCard) {
      final limitValue = double.tryParse(creditLimitController.text.trim());
      if (limitValue == null || limitValue <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid credit limit")),
        );
        return;
      }
      creditLimit = limitValue;
    }
    try {
      if (isEditing) {
        final s = widget.editSource!;
        s.name = name;
        s.balance = balance;
        s.iconIndex = _selectedIcon.value;
        s.colorValue = _selectedColor.value;
        s.isIncludedInTotal = isIncludedInTotal;
        s.isCreditCard = isCreditCard;
        s.creditLimit = creditLimit;
        s.lastUpdated = DateTime.now();
        await s.save();
      } else {
        final id = _uuid.v4();
        final newSource = Source(
          id: id,
          name: name,
          iconIndex: _selectedIcon.value,
          colorValue: _selectedColor.value,
          balance: balance,
          isIncludedInTotal: isIncludedInTotal,
          order: DateTime.now().millisecondsSinceEpoch,
          lastUpdated: DateTime.now(),
          isCreditCard: isCreditCard,
          creditLimit: creditLimit,
          isArchived: false,
          isBalanceHidden: false,
        );
        await Boxes.getSources().put(id, newSource);
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to save")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          isEditing ? "Edit Source" : "New Source",
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _saveSource,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: Text(
              isEditing ? "Update Source" : "Create Source",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeaderPreview(),
              const SizedBox(height: 30),
              _buildFormSection(),
              const SizedBox(height: 20),
              _buildCustomizationSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderPreview() {
    return Column(
      children: [
        ValueListenableBuilder2<int, int>(
          first: _selectedIcon,
          second: _selectedColor,
          builder: (_, iconIdx, colorVal, __) {
            final themeColor = Color(colorVal);
            return Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: themeColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                SourceIcons.icons[iconIdx],
                size: 42,
                color: Colors.white,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          textCapitalization: TextCapitalization.sentences,
          controller: nameController,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: "Source Name",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          validator: (v) => v == null || v.isEmpty ? "Required" : null,
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          TextFormField(
            controller: balanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: "Balance",
              prefixIcon: const Icon(Icons.currency_rupee),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSwitchRow(
            "Include in net worth",
            isIncludedInTotal,
            (v) => setState(() => isIncludedInTotal = v),
          ),
          const Divider(height: 32),
          _buildSwitchRow(
            "Credit Card",
            isCreditCard,
            (v) => setState(() => isCreditCard = v),
          ),
          if (isCreditCard) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: creditLimitController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: "Credit Limit",
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomizationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Theme Color",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildColorPicker(),
          const SizedBox(height: 30),
          const Text(
            "Select Icon",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildIconGrid(),
        ],
      ),
    );
  }

  Widget _buildColorPicker() {
    return SizedBox(
      height: 50,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.9),
        itemCount: (AppColors.palette.length / 5).ceil(),
        itemBuilder: (_, pageIndex) {
          final start = pageIndex * 5;
          final end = (start + 5).clamp(0, AppColors.palette.length);
          final colors = AppColors.palette.sublist(start, end);

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: colors.map((color) {
              return ValueListenableBuilder<int>(
                valueListenable: _selectedColor,
                builder: (_, selected, __) {
                  final isSelected = selected == color.toARGB32();
                  return GestureDetector(
                    onTap: () => _selectedColor.value = color.toARGB32(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isSelected ? 42 : 34,
                      height: isSelected ? 42 : 34,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildIconGrid() {
    return ValueListenableBuilder<int>(
      valueListenable: _selectedIcon,
      builder: (_, selected, __) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: SourceIcons.icons.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (_, index) {
            final isSelected = selected == index;
            return GestureDetector(
              onTap: () => _selectedIcon.value = index,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blueAccent : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  SourceIcons.icons[index],
                  size: 22,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSwitchRow(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
    );
  }
}

/// 🔧 Helper for listening to two Notifiers
class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final Widget Function(BuildContext context, A a, B b, Widget? child) builder;

  const ValueListenableBuilder2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<A>(
    valueListenable: first,
    builder: (context, a, _) => ValueListenableBuilder<B>(
      valueListenable: second,
      builder: (context, b, _) => builder(context, a, b, null),
    ),
  );
}
