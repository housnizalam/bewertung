import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/category_name_localizer.dart';
import '../../l10n/app_localizations.dart';
import '../../models/app_category.dart';
import '../../models/frequency_type.dart';
import '../../models/negative_habit.dart';
import '../../models/positive_task.dart';
import '../../providers/categories_provider.dart';
import '../../providers/negative_habits_provider.dart';
import '../../providers/positive_tasks_provider.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.strings;
    final categories = ref.watch(categoriesProvider);
    final tasks = ref.watch(positiveTasksProvider);
    final habits = ref.watch(negativeHabitsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.categories)),
      body: categories.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  strings.noCategoriesYet,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final categoryTasks = tasks
                    .where((task) => task.categoryId == category.id)
                    .toList();
                final categoryHabits = habits
                    .where((habit) => habit.categoryId == category.id)
                    .toList();

                return _CategoryCard(
                  category: category,
                  tasks: categoryTasks,
                  habits: categoryHabits,
                  onEdit: category.isDefault
                      ? null
                      : () => _showEditCategoryDialog(context, ref, category),
                  onDelete: category.isDefault
                      ? null
                      : () => _confirmDeleteCategory(context, ref, category),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'categories_add_fab',
        onPressed: () => _showAddCategoryDialog(context, ref),
        icon: const Icon(Icons.add),
        label: Text(strings.addCategory),
      ),
    );
  }

  Future<void> _showAddCategoryDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final strings = context.strings;
    final controller = TextEditingController();
    String? errorText;

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(strings.addCategory),
              content: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: strings.categoryName,
                  errorText: errorText,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) async {
                  final result = _validateCategoryName(
                    context,
                    ref,
                    controller.text,
                  );

                  if (result == null) {
                    await ref
                        .read(categoriesProvider.notifier)
                        .addCategory(
                          _newCategory(context, controller.text.trim()),
                        );
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop(true);
                  } else {
                    setState(() => errorText = result);
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(strings.cancel),
                ),
                FilledButton(
                  onPressed: () async {
                    final result = _validateCategoryName(
                      context,
                      ref,
                      controller.text,
                    );

                    if (result != null) {
                      setState(() => errorText = result);
                      return;
                    }

                    await ref
                        .read(categoriesProvider.notifier)
                        .addCategory(
                          _newCategory(context, controller.text.trim()),
                        );
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: Text(strings.save),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (created != true || !context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.savedSuccessfully)));
  }

  Future<void> _showEditCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    AppCategory category,
  ) async {
    final strings = context.strings;
    final controller = TextEditingController(text: category.name);
    String? errorText;

    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(strings.edit),
              content: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: strings.categoryName,
                  errorText: errorText,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) async {
                  final result = _validateCategoryName(
                    context,
                    ref,
                    controller.text,
                    excludingCategoryId: category.id,
                  );

                  if (result == null) {
                    await ref
                        .read(categoriesProvider.notifier)
                        .updateCategory(
                          category.copyWith(name: controller.text.trim()),
                        );
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop(true);
                    }
                  } else {
                    setState(() => errorText = result);
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(strings.cancel),
                ),
                FilledButton(
                  onPressed: () async {
                    final result = _validateCategoryName(
                      context,
                      ref,
                      controller.text,
                      excludingCategoryId: category.id,
                    );

                    if (result != null) {
                      setState(() => errorText = result);
                      return;
                    }

                    await ref
                        .read(categoriesProvider.notifier)
                        .updateCategory(
                          category.copyWith(name: controller.text.trim()),
                        );
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: Text(strings.save),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (updated != true || !context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.savedSuccessfully)));
  }

  Future<void> _confirmDeleteCategory(
    BuildContext context,
    WidgetRef ref,
    AppCategory category,
  ) async {
    final strings = context.strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.delete),
          content: Text(strings.confirmDelete),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(strings.delete),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    await ref.read(categoriesProvider.notifier).deleteCategory(category.id);

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.savedSuccessfully)));
  }

  String? _validateCategoryName(
    BuildContext context,
    WidgetRef ref,
    String rawName, {
    String? excludingCategoryId,
  }) {
    final strings = context.strings;
    final name = rawName.trim();
    if (name.isEmpty) return strings.validationError;

    final exists = ref
        .read(categoriesProvider)
        .any(
          (item) =>
              item.id != excludingCategoryId &&
              item.name.trim().toLowerCase() == name.toLowerCase(),
        );
    if (exists) return strings.categoryNameExists;

    return null;
  }

  AppCategory _newCategory(BuildContext context, String name) {
    final color = Theme.of(context).colorScheme.primary.toARGB32();
    return AppCategory(
      id: '',
      name: name,
      colorValue: color,
      isDefault: false,
      createdAt: DateTime.now(),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.tasks,
    required this.habits,
    required this.onEdit,
    required this.onDelete,
  });

  final AppCategory category;
  final List<PositiveTask> tasks;
  final List<NegativeHabit> habits;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Color(category.colorValue),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                localizedCategoryName(
                  context,
                  category.name,
                  isDefault: category.isDefault,
                ),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${strings.tasks}: ${tasks.length}  •  ${strings.forbidden}: ${habits.length}',
        ),
        trailing: onEdit == null && onDelete == null
            ? null
            : PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit?.call();
                  } else if (value == 'delete') {
                    onDelete?.call();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Text(strings.edit),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(strings.delete),
                  ),
                ],
              ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          if (tasks.isEmpty && habits.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                strings.noItemsInCategory,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else ...[
            if (tasks.isNotEmpty) ...[
              _SectionTitle(title: strings.tasks),
              ...tasks.map(
                (task) => _ItemRow(
                  name: task.name,
                  trailing:
                      '${strings.weight}: ${task.weight} • ${_frequencyLabel(task.frequencyType, strings)}',
                ),
              ),
            ],
            if (habits.isNotEmpty) ...[
              if (tasks.isNotEmpty) const SizedBox(height: 10),
              _SectionTitle(title: strings.forbidden),
              ...habits.map(
                (habit) => _ItemRow(
                  name: habit.name,
                  trailing: '${strings.weight}: ${habit.weight}',
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _frequencyLabel(FrequencyType type, AppStrings strings) {
    switch (type) {
      case FrequencyType.daily:
        return strings.daily;
      case FrequencyType.weekly:
        return strings.weekly;
      case FrequencyType.monthly:
        return strings.monthly;
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.name, required this.trailing});

  final String name;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.circle, size: 8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.bodyLarge),
                Text(trailing, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
