import 'package:flutter/material.dart';

class AmountField extends StatelessWidget {
  final TextEditingController controller;

  const AmountField({
    super.key,
    required this.controller,
  });

  double _calculateTotal(String input) {
    final parts = input.split(',');

    double sum = 0;

    for (var p in parts) {
      final value = double.tryParse(p.trim());
      if (value != null) {
        sum += value;
      }
    }

    return sum;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,

      keyboardType: const TextInputType.numberWithOptions(decimal: true),

      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return "Enter amount";
        }

        final parts = val.split(',');

        for (var p in parts) {
          if (double.tryParse(p.trim()) == null) {
            return "Invalid amount";
          }
        }

        return null;
      },

      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: InputBorder.none,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 40,
        ),

        hintText: "0",
        hintStyle: TextStyle(color: Colors.grey.shade400),

        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 24),
          child: Text(
            "₹",
            style: TextStyle(
              fontSize: 40,
              color: Colors.black54,
            ),
          ),
        ),
      ),

      style: const TextStyle(
        fontSize: 60,
        fontWeight: FontWeight.w500,
      ),

      cursorHeight: 60,
      textAlign: TextAlign.end,

      onEditingComplete: () {
        final total = _calculateTotal(controller.text);

        controller.text = total.toString();
      },
    );
  }
}