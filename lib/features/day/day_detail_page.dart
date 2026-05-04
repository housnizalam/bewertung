import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/day_entry.dart';
import '../../models/frequency_type.dart';
import '../../models/negative_habit.dart';
import '../../models/positive_task.dart';
import '../../providers/day_entries_provider.dart';
import '../../providers/negative_habits_provider.dart';
import '../../providers/positive_tasks_provider.dart';
import '../../shared/widgets/pressable_3d_button.dart';

String getFrequencyLabel(FrequencyType type, AppStrings strings) {
  switch (type) {
    case FrequencyType.daily:
      return strings.daily;
    case FrequencyType.weekly:
      return strings.weekly;
    case FrequencyType.monthly:
      return strings.monthly;
  }
}

/// Daily evaluation screen for one selected date.
///
/// The page loads any existing [DayEntry], lets the user edit counts locally,
/// previews score instantly, and saves back through [dayEntriesProvider].
class DayDetailPage extends ConsumerStatefulWidget {
  const DayDetailPage({super.key, required this.selectedDate});

  final DateTime selectedDate;

  @override
  ConsumerState<DayDetailPage> createState() => _DayDetailPageState();
}

class _DayDetailPageState extends ConsumerState<DayDetailPage> {
  /// Local editable copies of counts for this screen session.
  ///
  /// These are intentionally local UI state so score can update instantly
  /// before saving to storage.
  Map<String, int> _positiveLogs = <String, int>{};
  Map<String, int> _negativeLogs = <String, int>{};

  bool _initialized = false;
  bool _loadedFromEntry = false;
  bool _hasUserChanges = false;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final locale = Localizations.localeOf(context);
    final formattedDate = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    final dayEntriesNotifier = ref.read(dayEntriesProvider.notifier);

    final allActiveTasks = ref
        .watch(positiveTasksProvider)
        .where((task) => task.isActive)
        .toList();
    final tasks = dayEntriesNotifier.getApplicableTasksForDate(
      widget.selectedDate,
      allActiveTasks,
    );
    final habits = ref
        .watch(negativeHabitsProvider)
        .where((habit) => habit.isActive)
        .toList();
    final entry = ref
        .watch(dayEntriesProvider.notifier)
        .getEntryForDate(widget.selectedDate);

    _syncLocalLogs(tasks, habits, entry);

    final score = dayEntriesNotifier.getScoreForLogs(
      widget.selectedDate,
      _positiveLogs,
      _negativeLogs,
      tasks,
      habits,
      locale,
    );

    return Scaffold(
      appBar: AppBar(title: Text('${strings.dayEvaluation} - $formattedDate')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _ScoreCard(score: score),
          const SizedBox(height: 12),
          _SectionCard(
            title: strings.tasks,
            icon: Icons.check_circle_rounded,
            emptyMessage: strings.noTasksYet,
            children: tasks.map((task) {
              return _CountItemTile(
                icon: Icons.task_alt_rounded,
                title: task.name,
                frequencyType: task.frequencyType,
                frequencyLabel: getFrequencyLabel(task.frequencyType, strings),
                subtitle:
                    '${strings.targetCount}: ${task.targetCount}   |   ${strings.weight}: ${task.weight}',
                progressText: _taskProgressText(
                  task,
                  locale,
                  dayEntriesNotifier,
                ),
                countLabel: strings.completedCount,
                count: _positiveLogs[task.id] ?? 0,
                onChanged: (value) => _updatePositive(task.id, value),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: strings.forbidden,
            icon: Icons.warning_amber_rounded,
            emptyMessage: strings.noForbiddenYet,
            children: habits
                .map(
                  (habit) => _CountItemTile(
                    icon: Icons.block_rounded,
                    title: habit.name,
                    subtitle: '${strings.weight}: ${habit.weight}',
                    countLabel: strings.actualCount,
                    count: _negativeLogs[habit.id] ?? 0,
                    onChanged: (value) => _updateNegative(habit.id, value),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: Pressable3DButton(
            onPressed: _save,
            width: double.infinity,
            height: 52,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save_outlined),
                const SizedBox(width: 8),
                Text(strings.saveEvaluation),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Initializes local maps from existing entry (if any) and ensures every
  /// active task/habit has a default value of 0.
  void _syncLocalLogs(
    List<PositiveTask> tasks,
    List<NegativeHabit> habits,
    DayEntry? entry,
  ) {
    if (!_initialized) {
      _positiveLogs = <String, int>{};
      _negativeLogs = <String, int>{};
      _initialized = true;
    }

    if (entry != null && !_loadedFromEntry && !_hasUserChanges) {
      _positiveLogs = _sanitizePositiveLogs(entry.positiveLogs);
      _negativeLogs = _sanitizeLogs(entry.negativeLogs);
      _loadedFromEntry = true;
    }

    for (final task in tasks) {
      _positiveLogs.putIfAbsent(task.id, () => 0);
      final current = _positiveLogs[task.id] ?? 0;
      _positiveLogs[task.id] = max(0, current);
    }

    for (final habit in habits) {
      _negativeLogs.putIfAbsent(habit.id, () => 0);
    }
  }

  /// Updates one positive-task count.
  void _updatePositive(String taskId, int nextValue) {
    setState(() {
      _hasUserChanges = true;
      _positiveLogs[taskId] = max(0, nextValue);
    });
  }

  /// Updates one negative-habit count.
  void _updateNegative(String habitId, int nextValue) {
    setState(() {
      _hasUserChanges = true;
      _negativeLogs[habitId] = max(0, nextValue);
    });
  }

  /// Persists current logs for [widget.selectedDate].
  ///
  /// Date normalization happens in provider/storage layer.
  Future<void> _save() async {
    final entry = DayEntry(
      date: widget.selectedDate,
      positiveLogs: Map<String, int>.from(_positiveLogs),
      negativeLogs: Map<String, int>.from(_negativeLogs),
      note: '',
    );

    await ref.read(dayEntriesProvider.notifier).saveEntry(entry);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.strings.savedSuccessfully)));
  }

  /// Guards local logs from negative values.
  Map<String, int> _sanitizeLogs(Map<String, int> source) {
    final sanitized = <String, int>{};
    source.forEach((key, value) {
      sanitized[key] = max(0, value);
    });
    return sanitized;
  }

  Map<String, int> _sanitizePositiveLogs(Map<String, int> source) {
    final sanitized = <String, int>{};
    source.forEach((key, value) {
      sanitized[key] = max(0, value);
    });
    return sanitized;
  }

  String? _taskProgressText(
    PositiveTask task,
    Locale locale,
    DayEntriesNotifier dayEntriesNotifier,
  ) {
    if (task.frequencyType == FrequencyType.daily) {
      return null;
    }

    final progress = dayEntriesNotifier.getTaskProgressForDate(
      task,
      widget.selectedDate,
      locale,
      previewPositiveLogsForSelectedDate: _positiveLogs,
    );
    final percent = (progress * 100).round();
    final template = task.frequencyType == FrequencyType.weekly
        ? context.strings.weeklyTaskProgressTemplate
        : context.strings.monthlyTaskProgressTemplate;
    return template.replaceFirst('{percent}', '$percent');
  }
}

/// Generic section card for tasks/habits blocks.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.emptyMessage,
    required this.children,
  });

  final String title;
  final IconData icon;
  final String emptyMessage;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            if (children.isEmpty)
              Text(emptyMessage, style: theme.textTheme.bodyMedium)
            else
              ...children,
          ],
        ),
      ),
    );
  }
}

/// Row widget for one task/habit counter item.
class _CountItemTile extends StatelessWidget {
  const _CountItemTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.frequencyType,
    this.frequencyLabel,
    this.progressText,
    required this.countLabel,
    required this.count,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final FrequencyType? frequencyType;
  final String? frequencyLabel;
  final String? progressText;
  final String countLabel;
  final int count;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (frequencyType != null && frequencyLabel != null) ...[
                      const SizedBox(width: 8),
                      _FrequencyChip(
                        type: frequencyType!,
                        label: frequencyLabel!,
                      ),
                    ],
                  ],
                ),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                if (progressText != null)
                  Text(
                    progressText!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          _CounterControl(
            label: countLabel,
            value: count,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _FrequencyChip extends StatelessWidget {
  const _FrequencyChip({required this.type, required this.label});

  final FrequencyType type;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Color background;
    final Color foreground;

    switch (type) {
      case FrequencyType.daily:
        background = scheme.tertiaryContainer.withValues(alpha: 0.7);
        foreground = scheme.onTertiaryContainer;
        break;
      case FrequencyType.weekly:
        background = scheme.secondaryContainer.withValues(alpha: 0.7);
        foreground = scheme.onSecondaryContainer;
        break;
      case FrequencyType.monthly:
        background = scheme.primaryContainer.withValues(alpha: 0.7);
        foreground = scheme.onPrimaryContainer;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Numeric control used for count editing.
class _CounterControl extends StatelessWidget {
  const _CounterControl({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: '$value');
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        SizedBox(
          width: 92,
          height: 40,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            onChanged: (text) {
              final nextValue = int.tryParse(text) ?? 0;
              onChanged(nextValue);
            },
          ),
        ),
      ],
    );
  }
}

/// Card showing live score preview values.
class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score});

  final dynamic score;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.dayEvaluation,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            _ScoreRow(
              label: strings.positivePoints,
              value: score.positivePoints,
            ),
            _ScoreRow(
              label: strings.negativePoints,
              value: score.negativePoints,
            ),
            _ScoreRow(label: strings.rawScore, value: score.rawScore),
            _ScoreRow(
              label: strings.percentage,
              value: score.percentage,
              isPercent: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable labeled score value row.
class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.label,
    required this.value,
    this.isPercent = false,
  });

  final String label;
  final double value;
  final bool isPercent;

  @override
  Widget build(BuildContext context) {
    final text = isPercent
        ? '${value.toStringAsFixed(1)}%'
        : value.toStringAsFixed(2);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(text),
        ],
      ),
    );
  }
}
