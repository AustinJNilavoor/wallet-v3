import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:wallet/core/app_colors.dart';
import 'package:wallet/core/boxes.dart';
import 'package:wallet/core/category_icons.dart';
import 'package:wallet/data/models/category.dart';
import 'package:wallet/presentation/widgets/value_listenable_builder2.dart';

class AddCategoryScreen extends StatefulWidget {
  final Category? editCategory;

  const AddCategoryScreen({super.key, this.editCategory});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  final ValueNotifier<int> _selectedIndex = ValueNotifier(0);
  final ValueNotifier<int> _selectedColor = ValueNotifier(
    AppColors.palette.first.toARGB32(),
  );

  final Uuid _uuid = const Uuid();

  bool get isEditing => widget.editCategory != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final c = widget.editCategory!;
      _nameController.text = c.name;
      _selectedIndex.value = c.iconIndex;
      _selectedColor.value = c.colorValue ?? AppColors.palette.first.toARGB32();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _selectedIndex.dispose();
    _selectedColor.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError("Enter category name");
      return;
    }

    final box = Boxes.getCategories();
    final exists = box.values.any(
      (c) =>
          c.name.toLowerCase() == name.toLowerCase() &&
          c.id != widget.editCategory?.id,
    );

    if (exists) {
      _showError("Category already exists");
      return;
    }

    try {
      if (isEditing) {
        final c = widget.editCategory!;
        c.name = name;
        c.iconIndex = _selectedIndex.value;
        c.colorValue = _selectedColor.value;
        await c.save();
      } else {
        final category = Category(
          id: _uuid.v4(),
          name: name,
          iconIndex: _selectedIndex.value,
          colorValue: _selectedColor.value,
        );
        await box.put(category.id, category);
      }
      Navigator.pop(context);
    } catch (e) {
      _showError("Failed to save");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          isEditing ? "Edit Category" : "New Category",
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      bottomNavigationBar: _buildBottomButton(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeaderPreview(),
              const SizedBox(height: 30),
              _buildCustomizationCard(),
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
          first: _selectedIndex,
          second: _selectedColor,
          builder: (_, index, colorVal, __) {
            final themeColor = Color(colorVal);
            return Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: themeColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                CategoryIcons.icons[index],
                size: 42,
                color: Colors.white,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          textCapitalization: TextCapitalization.sentences,
          controller: _nameController,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: "Category Name",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          onFieldSubmitted: (_) => _saveCategory(),
        ),
      ],
    );
  }

  Widget _buildCustomizationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Theme Color",
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
      valueListenable: _selectedIndex,
      builder: (_, selectedIdx, __) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: CategoryIcons.icons.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (_, index) {
            final isSelected = selectedIdx == index;
            return GestureDetector(
              onTap: () => _selectedIndex.value = index,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                 color: isSelected ? Colors.blueAccent : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CategoryIcons.icons[index],
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

  Widget _buildBottomButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _saveCategory,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            elevation: 0,
          ),
          child: Text(
            isEditing ? "Update Category" : "Create Category",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

/// 🔧 Helper for listening to two Notifiers

