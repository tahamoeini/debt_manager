// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:debt_manager/core/categories/category_service.dart';
import 'package:debt_manager/core/utils/category_colors.dart';
import 'package:debt_manager/features/budget/budgets_repository.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final _categoryService = CategoryService();
  List<String> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await _categoryService.getAllCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
        _loading = false;
      });
    }
  }

  Future<void> _showAddCategoryDialog() async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('افزودن دسته‌بندی جدید'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'نام دسته‌بندی',
            hintText: 'مثال: سلامت، آموزش',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('لغو'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              try {
                await _categoryService.addCategory(name);
                Navigator.of(ctx).pop();
                await _loadCategories();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('دسته‌بندی اضافه شد')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('خطا: $e')));
              }
            },
            child: const Text('افزودن'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRenameCategoryDialog(String category) async {
    if (_categoryService.isDefaultCategory(category)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('دسته‌بندی‌های پیش‌فرض قابل تغییر نام نیستند'),
        ),
      );
      return;
    }

    final controller = TextEditingController(text: category);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تغییر نام دسته‌بندی'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'نام جدید'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('لغو'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;

              try {
                await _categoryService.renameCategory(category, newName);
                Navigator.of(ctx).pop();
                await _loadCategories();
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('نام تغییر کرد')));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('خطا: $e')));
              }
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteCategory(String category) async {
    if (_categoryService.isDefaultCategory(category)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('دسته‌بندی‌های پیش‌فرض قابل حذف نیستند')),
      );
      return;
    }

    // Check if any budgets use this category
    final budgetsRepo = BudgetsRepository();
    final allBudgets = await budgetsRepo.getAllBudgets();
    final categoryBudgets = allBudgets
        .where((b) => b.category?.toLowerCase() == category.toLowerCase())
        .toList();

    String warningText =
        'آیا مطمئن هستید که می‌خواهید "$category" را حذف کنید؟';
    if (categoryBudgets.isNotEmpty) {
      warningText =
          'هشدار: ${categoryBudgets.length} بودجه از این دسته‌بندی استفاده می‌کند.\n\n'
          'حذف این دسته‌بندی باعث نمی‌شود بودجه‌ها حذف شوند، اما آنها با دسته‌بندی حذف‌شده نمایش داده خواهند شد.\n\n'
          'آیا مطمئن هستید که می‌خواهید ادامه دهید؟';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف دسته‌بندی'),
        content: Text(warningText),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('لغو'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _categoryService.deleteCategory(category);
      await _loadCategories();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('دسته‌بندی حذف شد')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    Widget bodyContent;

    if (_loading) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (_categories.isEmpty) {
      bodyContent = const Center(child: Text('هیچ دسته‌بندی وجود ندارد'));
    } else {
      bodyContent = ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isDefault = _categoryService.isDefaultCategory(category);
          final color = colorForCategory(category, brightness: brightness);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.2),
                child: Icon(Icons.label_outlined, color: color),
              ),
              title: Text(
                category,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: isDefault
                  ? const Text('پیش‌فرض')
                  : const Text('سفارشی'),
              trailing: isDefault
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Rename category',
                          onPressed: () => _showRenameCategoryDialog(category),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outlined),
                          tooltip: 'Delete category',
                          onPressed: () => _confirmDeleteCategory(category),
                        ),
                      ],
                    ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('مدیریت دسته‌بندی‌ها')),
      body: SafeArea(child: bodyContent),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategoryDialog,
        tooltip: 'Add new category',
        icon: const Icon(Icons.add),
        label: const Text('افزودن دسته‌بندی'),
      ),
    );
  }
}
