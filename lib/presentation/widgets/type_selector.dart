import 'package:flutter/material.dart';
import 'package:wallet/data/models/transaction_type.dart';

class TypeSelector extends StatelessWidget {
  final TransactionType selectedType;
  final ValueChanged<TransactionType> onChanged;

  const TypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Row(
          children: [
            _TypeButton(
              label: "Income",
              type: TransactionType.income,
              selectedType: selectedType,
              activeColor: Colors.green,
              onTap: onChanged,
            ),
            const SizedBox(width: 8),
            _TypeButton(
              label: "Transfer",
              type: TransactionType.transfer,
              selectedType: selectedType,
              activeColor: Colors.blue,
              onTap: onChanged,
            ),
            const SizedBox(width: 8),
            _TypeButton(
              label: "Expense",
              type: TransactionType.expense,
              selectedType: selectedType,
              activeColor: Colors.red,
              onTap: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final TransactionType type;
  final TransactionType selectedType;
  final Color activeColor;
  final ValueChanged<TransactionType> onTap;

  const _TypeButton({
    required this.label,
    required this.type,
    required this.selectedType,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = selectedType == type;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 45,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
