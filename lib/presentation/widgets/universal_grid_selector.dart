import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wallet/data/models/source.dart';
import 'package:wallet/presentation/widgets/delete_dialog.dart';
import 'package:wallet/presentation/widgets/selector_item.dart';

class UniversalGridSelector<T> extends StatefulWidget {
  final ValueListenable<Box<T>> listenable;
  final T? selectedItem;

  final String Function(T) labelBuilder;
  final IconData Function(T) iconBuilder;
  final String Function(T) idBuilder;
  final Color Function(T)? colorBuilder;

  final ValueChanged<T> onSelect;
  final VoidCallback onAdd;

  final Color activeColor;
  final bool enableMoreButton;

  const UniversalGridSelector({
    super.key,
    required this.listenable,
    required this.selectedItem,
    required this.labelBuilder,
    required this.iconBuilder,
    required this.idBuilder,
    required this.colorBuilder,
    required this.onSelect,
    required this.onAdd,
    required this.activeColor,
    this.enableMoreButton = true,
  });

  @override
  State<UniversalGridSelector<T>> createState() =>
      _UniversalGridSelectorState<T>();
}

class _UniversalGridSelectorState<T> extends State<UniversalGridSelector<T>> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<T>>(
      valueListenable: widget.listenable,
      builder: (context, box, _) {
        final items = box.values.toList();

        items.sort((a, b) {
          // 1. Primary: Check for the Selected Item
          if (widget.selectedItem != null) {
            final selectedId = widget.idBuilder(widget.selectedItem as T);
            bool isASelected = widget.idBuilder(a) == selectedId;
            bool isBSelected = widget.idBuilder(b) == selectedId;

            if (isASelected && !isBSelected) return -1;
            if (!isASelected && isBSelected) return 1;
          }

          // 2. Secondary: If both are Sources, sort by their 'order' property
          if (a is Source && b is Source) {
            return a.order.compareTo(b.order);
          }

          return 0;
        });
        const int crossAxisCount = 4;

        final bool showMore =
            widget.enableMoreButton &&
            !isExpanded &&
            items.length > (crossAxisCount - 1);

        final int itemCount = showMore ? crossAxisCount : items.length + 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (showMore && index == (crossAxisCount - 1)) {
              return SelectorActionItem(
                icon: Icons.arrow_downward_rounded,
                label: "More",
                onTap: () => setState(() => isExpanded = true),
              );
            }

            if (index == items.length) {
              return SelectorActionItem(
                icon: Icons.add,
                label: "Add",
                onTap: widget.onAdd,
              );
            }

            if (index >= items.length) {
              return const SizedBox();
            }

            final item = items[index];
            final color = widget.colorBuilder?.call(item) ?? Colors.grey;
            final bg = color.withValues(alpha: 0.15);
            final fg = color;
            final bool isSelected =
                widget.selectedItem != null &&
                widget.idBuilder(widget.selectedItem as T) ==
                    widget.idBuilder(item);

            return GestureDetector(
              onLongPress: () async {
                HapticFeedback.mediumImpact();

                final confirm = await DeleteDialog.show(
                  context,
                  title: "Delete Item",
                  message: "This will remove the item permanently.",
                );
                if (confirm) {
                  box.delete(widget.idBuilder(item));
                }
              },
              child: SelectorItem(
                icon: widget.iconBuilder(item),
                label: widget.labelBuilder(item),
                isSelected: isSelected,
                activeColor: widget.activeColor,
                bgColor: bg,
                iconColor: fg,
                onTap: () {
                  widget.onSelect(item);
                  setState(() => isExpanded = false);
                },
              ),
            );
          },
        );
      },
    );
  }
}
