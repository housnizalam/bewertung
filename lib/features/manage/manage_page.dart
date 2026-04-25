import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../day/day_detail_page.dart';
import '../../models/app_category.dart';
import '../../models/frequency_type.dart';
import '../../models/negative_habit.dart';
import '../../models/positive_task.dart';
import '../../providers/categories_provider.dart';
import '../../providers/negative_habits_provider.dart';
import '../../providers/positive_tasks_provider.dart';
import 'widgets/weight_picker.dart';

/// Manage screen for CRUD operations on positive tasks and negative habits.
///
/// Data flow here follows: UI -> Provider -> HiveService.
/// The page never reads/writes Hive directly.
class ManagePage extends ConsumerStatefulWidget {
  const ManagePage({super.key});

  @override
  ConsumerState<ManagePage> createState() => _ManagePageState();
}

class _ManagePageState extends ConsumerState<ManagePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool get _isTasksTab => _tabController.index == 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final tasks = ref.watch(positiveTasksProvider);
    final habits = ref.watch(negativeHabitsProvider);
    final categories = ref.watch(categoriesProvider);

    final categoriesById = {
      for (final category in categories) category.id: category,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.manage),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DayDetailPage(selectedDate: DateTime.now()),
                ),
              );
            },
            icon: const Icon(Icons.today_rounded),
            tooltip: strings.dayEvaluation,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: strings.tasks, icon: const Icon(Icons.check_circle)),
            Tab(text: strings.forbidden, icon: const Icon(Icons.block)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          tasks.isEmpty
              ? _EmptyState(
                  icon: Icons.checklist_rounded,
                  message: strings.noTasksYet,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final category = categoriesById[task.categoryId];
                    return _ManageItemCard(
                      leadingIcon: Icons.task_alt_rounded,
                      title: task.name,
                      categoryName: _localizedCategoryName(
                        context,
                        category?.name ?? strings.unknownCategory,
                      ),
                      weight: task.weight,
                      targetCount: task.targetCount,
                      showTargetCount: true,
                      frequencyLabel: _frequencyLabel(
                        context,
                        task.frequencyType,
                      ),
                      isActive: task.isActive,
                      onEdit: () => _openTaskForm(categories, task),
                      onDelete: () => _deleteTask(task.id),
                    );
                  },
                ),
          habits.isEmpty
              ? _EmptyState(
                  icon: Icons.shield_moon_rounded,
                  message: strings.noForbiddenYet,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: habits.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final habit = habits[index];
                    final category = categoriesById[habit.categoryId];
                    return _ManageItemCard(
                      leadingIcon: Icons.warning_amber_rounded,
                      title: habit.name,
                      categoryName: _localizedCategoryName(
                        context,
                        category?.name ?? strings.unknownCategory,
                      ),
                      weight: habit.weight,
                      targetCount: null,
                      showTargetCount: false,
                      frequencyLabel: _frequencyLabel(
                        context,
                        habit.frequencyType,
                      ),
                      isActive: habit.isActive,
                      onEdit: () => _openHabitForm(categories, habit),
                      onDelete: () => _deleteHabit(habit.id),
                    );
                  },
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (categories.isEmpty) {
            _showMessage(strings.missingCategories);
            return;
          }

          if (_isTasksTab) {
            await _openTaskForm(categories, null);
          } else {
            await _openHabitForm(categories, null);
          }
        },
        icon: Icon(_isTasksTab ? Icons.add_task : Icons.add_moderator),
        label: Text(_isTasksTab ? strings.addTask : strings.addForbidden),
      ),
    );
  }

  /// Opens add/edit sheet for positive tasks.
  ///
  /// If [initial] is null, this creates a new task; otherwise it updates
  /// the existing one.
  Future<void> _openTaskForm(
    List<AppCategory> categories,
    PositiveTask? initial,
  ) async {
    if (categories.isEmpty) {
      _showMessage(context.strings.missingCategories);
      return;
    }

    final result = await showModalBottomSheet<PositiveTask>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _TaskFormSheet(categories: categories, initial: initial),
    );

    if (result == null) {
      return;
    }
    final notifier = ref.read(positiveTasksProvider.notifier);

    if (initial == null) {
      await notifier.addTask(result);
    } else {
      await notifier.updateTask(result);
    }
  }

  /// Opens add/edit sheet for negative habits.
  Future<void> _openHabitForm(
    List<AppCategory> categories,
    NegativeHabit? initial,
  ) async {
    if (categories.isEmpty) {
      _showMessage(context.strings.missingCategories);
      return;
    }

    final result = await showModalBottomSheet<NegativeHabit>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _HabitFormSheet(categories: categories, initial: initial),
    );

    if (result == null) {
      return;
    }
    final notifier = ref.read(negativeHabitsProvider.notifier);

    if (initial == null) {
      await notifier.addHabit(result);
    } else {
      await notifier.updateHabit(result);
    }
  }

  /// Confirms and deletes a positive task.
  Future<void> _deleteTask(String id) async {
    final approved = await _confirmDelete();
    if (!approved) {
      return;
    }

    await ref.read(positiveTasksProvider.notifier).deleteTask(id);
  }

  /// Confirms and deletes a negative habit.
  Future<void> _deleteHabit(String id) async {
    final approved = await _confirmDelete();
    if (!approved) {
      return;
    }

    await ref.read(negativeHabitsProvider.notifier).deleteHabit(id);
  }

  /// Shared delete confirmation dialog.
  Future<bool> _confirmDelete() async {
    final strings = context.strings;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
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

    return result ?? false;
  }

  /// Shows simple feedback messages.
  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Reusable card used by both tasks and habits lists.
class _ManageItemCard extends StatelessWidget {
  const _ManageItemCard({
    required this.leadingIcon,
    required this.title,
    required this.categoryName,
    required this.weight,
    required this.targetCount,
    required this.showTargetCount,
    required this.frequencyLabel,
    required this.isActive,
    required this.onEdit,
    required this.onDelete,
  });

  final IconData leadingIcon;
  final String title;
  final String categoryName;
  final double weight;
  final int? targetCount;
  final bool showTargetCount;
  final String frequencyLabel;
  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(leadingIcon, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Chip(
                  label: Text(isActive ? strings.active : strings.inactive),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(label: '${strings.category}: $categoryName'),
                _InfoChip(label: '${strings.weight}: $weight'),
                if (showTargetCount && targetCount != null)
                  _InfoChip(label: '${strings.targetCount}: $targetCount'),
                _InfoChip(label: '${strings.frequency}: $frequencyLabel'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: strings.edit,
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: strings.delete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small visual chip for key/value metadata.
class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    );
  }
}

/// Bottom-sheet form for creating/editing [PositiveTask].
///
/// Local form state is kept inside this sheet because inputs are temporary UI
/// state, while app data state is owned by providers.
class _TaskFormSheet extends StatefulWidget {
  const _TaskFormSheet({required this.categories, required this.initial});

  final List<AppCategory> categories;
  final PositiveTask? initial;

  @override
  State<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<_TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetCountController;

  late String? _categoryId;
  late FrequencyType _frequencyType;
  late bool _isActive;
  late double _weightValue;

  @override
  void initState() {
    super.initState();

    final initial = widget.initial;
    final categoryExists = widget.categories.any(
      (c) => c.id == initial?.categoryId,
    );

    _nameController = TextEditingController(text: initial?.name ?? '');
    _weightValue = (initial?.weight ?? 0).round().clamp(0, 99).toDouble();
    _targetCountController = TextEditingController(
      text: initial != null ? initial.targetCount.toString() : '',
    );
    _categoryId = categoryExists
        ? initial?.categoryId
        : (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    _frequencyType = initial?.frequencyType ?? FrequencyType.daily;
    _isActive = initial?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final weightLabel = Localizations.localeOf(context).languageCode == 'ar'
        ? 'التثقيل (%)'
        : 'Weight (%)';

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initial == null ? strings.addTask : strings.edit,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: strings.name),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return strings.validationError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: InputDecoration(labelText: strings.category),
                items: widget.categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(
                          _localizedCategoryName(context, category.name),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _categoryId = value),
                validator: (value) =>
                    value == null ? strings.validationError : null,
              ),
              const SizedBox(height: 12),
              Text(weightLabel, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Center(
                child: WeightPicker(
                  initialValue: _weightValue,
                  onChanged: (value) => setState(() => _weightValue = value),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetCountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: strings.targetCount),
                validator: (value) {
                  final number = int.tryParse((value ?? '').trim());
                  if (number == null || number <= 0) {
                    return strings.validationError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<FrequencyType>(
                initialValue: _frequencyType,
                decoration: InputDecoration(labelText: strings.frequency),
                items: FrequencyType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_frequencyLabel(context, type)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _frequencyType = value);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(strings.active),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(strings.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      // Validation stays in UI so providers receive clean data.
                      if (!_formKey.currentState!.validate()) return;

                      final weight = _weightValue.clamp(0, 99).toDouble();
                      final target = int.tryParse(
                        _targetCountController.text.trim(),
                      );
                      final categoryId = _categoryId;

                      if (target == null || target <= 0 || categoryId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(strings.validationError)),
                        );
                        return;
                      }

                      Navigator.of(context).pop(
                        PositiveTask(
                          id: widget.initial?.id ?? '',
                          name: _nameController.text.trim(),
                          categoryId: categoryId,
                          weight: weight,
                          targetCount: target,
                          frequencyType: _frequencyType,
                          isActive: _isActive,
                          createdAt:
                              widget.initial?.createdAt ?? DateTime.now(),
                        ),
                      );
                    },
                    child: Text(strings.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom-sheet form for creating/editing [NegativeHabit].
class _HabitFormSheet extends StatefulWidget {
  const _HabitFormSheet({required this.categories, required this.initial});

  final List<AppCategory> categories;
  final NegativeHabit? initial;

  @override
  State<_HabitFormSheet> createState() => _HabitFormSheetState();
}

class _HabitFormSheetState extends State<_HabitFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  late String? _categoryId;
  late FrequencyType _frequencyType;
  late bool _isActive;
  late double _weightValue;

  @override
  void initState() {
    super.initState();

    final initial = widget.initial;
    final categoryExists = widget.categories.any(
      (c) => c.id == initial?.categoryId,
    );

    _nameController = TextEditingController(text: initial?.name ?? '');
    _weightValue = (initial?.weight ?? 0).round().clamp(0, 99).toDouble();
    _categoryId = categoryExists
        ? initial?.categoryId
        : (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    _frequencyType = initial?.frequencyType ?? FrequencyType.daily;
    _isActive = initial?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final weightLabel = Localizations.localeOf(context).languageCode == 'ar'
        ? 'التثقيل (%)'
        : 'Weight (%)';

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initial == null ? strings.addForbidden : strings.edit,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: strings.name),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return strings.validationError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: InputDecoration(labelText: strings.category),
                items: widget.categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(
                          _localizedCategoryName(context, category.name),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _categoryId = value),
                validator: (value) =>
                    value == null ? strings.validationError : null,
              ),
              const SizedBox(height: 12),
              Text(weightLabel, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Center(
                child: WeightPicker(
                  initialValue: _weightValue,
                  onChanged: (value) => setState(() => _weightValue = value),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<FrequencyType>(
                initialValue: _frequencyType,
                decoration: InputDecoration(labelText: strings.frequency),
                items: FrequencyType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_frequencyLabel(context, type)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _frequencyType = value);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(strings.active),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(strings.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      // Validation stays in UI so providers receive clean data.
                      if (!_formKey.currentState!.validate()) return;

                      final weight = _weightValue.clamp(0, 99).toDouble();
                      final categoryId = _categoryId;

                      if (categoryId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(strings.validationError)),
                        );
                        return;
                      }

                      Navigator.of(context).pop(
                        NegativeHabit(
                          id: widget.initial?.id ?? '',
                          name: _nameController.text.trim(),
                          categoryId: categoryId,
                          weight: weight,
                          targetCount: widget.initial?.targetCount ?? 1,
                          frequencyType: _frequencyType,
                          isActive: _isActive,
                          createdAt:
                              widget.initial?.createdAt ?? DateTime.now(),
                        ),
                      );
                    },
                    child: Text(strings.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty-state card used when no tasks/habits are available.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 44, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(message, style: theme.textTheme.titleMedium),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Returns localized frequency text for a [FrequencyType] value.
String _frequencyLabel(BuildContext context, FrequencyType type) {
  final strings = context.strings;
  switch (type) {
    case FrequencyType.daily:
      return strings.daily;
    case FrequencyType.weekly:
      return strings.weekly;
    case FrequencyType.monthly:
      return strings.monthly;
  }
}

String _localizedCategoryName(BuildContext context, String name) {
  final languageCode = Localizations.localeOf(context).languageCode;
  if (languageCode != 'ar') return name;

  const englishToArabicDefaults = <String, String>{
    'Religion': 'ديني',
    'Ethics': 'أخلاقي',
    'Family': 'عائلة',
    'Work': 'عمل',
    'Health': 'صحة',
    'Learning': 'تعلّم',
    'Sport': 'رياضة',
    'Other': 'أخرى',
  };

  return englishToArabicDefaults[name] ?? name;
}
