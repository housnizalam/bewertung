import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_score.dart';
import '../models/day_entry.dart';
import '../models/frequency_type.dart';
import '../models/negative_habit.dart';
import '../models/positive_task.dart';
import '../storage/hive_service.dart';

/// Riverpod state for all saved day evaluations.
///
/// This provider also exposes score calculation helpers so UI pages can reuse
/// one source of truth and avoid duplicating scoring logic.
final dayEntriesProvider =
    StateNotifierProvider<DayEntriesNotifier, List<DayEntry>>(
      (ref) => DayEntriesNotifier(),
    );

/// Manages day-entry CRUD and score calculations.
class DayEntriesNotifier extends StateNotifier<List<DayEntry>> {
  DayEntriesNotifier() : super(const []) {
    loadEntries();
  }

  /// Reloads all day entries from local storage.
  Future<void> loadEntries() async {
    state = HiveService.loadAllDayEntries();
  }

  /// Saves one day entry for its normalized date.
  Future<void> saveEntry(DayEntry entry) async {
    final normalized = entry.copyWith(date: DayEntry.normalizeDate(entry.date));
    await HiveService.saveDayEntry(normalized);
    await loadEntries();
  }

  /// Deletes one day entry by date.
  Future<void> deleteEntry(DateTime date) async {
    await HiveService.deleteDayEntry(date);
    await loadEntries();
  }

  /// Returns an existing entry for [date], or `null` when not rated yet.
  DayEntry? getEntryForDate(DateTime date) {
    final key = DayEntry.toDateKey(date);
    try {
      return state.firstWhere((entry) => DayEntry.toDateKey(entry.date) == key);
    } catch (_) {
      return null;
    }
  }

  /// Calculates the score for a persisted day.
  ///
  /// Returns `isRated = false` when no entry exists.
  DailyScore getScoreForDate(
    DateTime date,
    List<PositiveTask> tasks,
    List<NegativeHabit> habits,
    Locale locale,
  ) {
    final normalizedDate = DayEntry.normalizeDate(date);
    final entry = getEntryForDate(date);

    if (isFutureDate(normalizedDate)) {
      return const DailyScore(
        positivePoints: 0,
        negativePoints: 0,
        rawScore: 0,
        percentage: 0,
        isRated: false,
      );
    }

    if (isToday(normalizedDate) && entry == null) {
      return const DailyScore(
        positivePoints: 0,
        negativePoints: 0,
        rawScore: 0,
        percentage: 0,
        isRated: false,
      );
    }

    final applicableTasks = getApplicableTasksForDate(normalizedDate, tasks);
    final isCalculable = isDateCalculable(normalizedDate, tasks, entry);

    if (!isCalculable) {
      return const DailyScore(
        positivePoints: 0,
        negativePoints: 0,
        rawScore: 0,
        percentage: 0,
        isRated: false,
      );
    }

    return calculateDailyScoreWithPeriodicTasks(
      selectedDate: normalizedDate,
      positiveLogs: entry?.positiveLogs ?? const <String, int>{},
      negativeLogs: entry?.negativeLogs ?? const <String, int>{},
      tasks: applicableTasks,
      habits: habits,
      locale: locale,
      isRated: isCalculable,
    );
  }

  /// Calculates one day's score for a single category.
  ///
  /// This method filters tasks/habits by [categoryId] and then reuses the
  /// existing shared scoring flow, including today/future guards and all
  /// frequency-specific rules.
  DailyScore getScoreForDateByCategory(
    DateTime date,
    String categoryId,
    List<PositiveTask> allTasks,
    List<NegativeHabit> allHabits,
    Locale locale,
  ) {
    final categoryTasks = allTasks
        .where((task) => task.categoryId == categoryId)
        .toList();
    final categoryHabits = allHabits
        .where((habit) => habit.categoryId == categoryId)
        .toList();

    return getScoreForDate(date, categoryTasks, categoryHabits, locale);
  }

  /// Calculates a score preview from in-memory logs (before save).
  ///
  /// Used by Day Detail for instant score updates while editing counts.
  DailyScore getScoreForLogs(
    DateTime date,
    Map<String, int> positiveLogs,
    Map<String, int> negativeLogs,
    List<PositiveTask> tasks,
    List<NegativeHabit> habits,
    Locale locale,
  ) {
    final normalizedDate = DayEntry.normalizeDate(date);

    if (isFutureDate(normalizedDate)) {
      return const DailyScore(
        positivePoints: 0,
        negativePoints: 0,
        rawScore: 0,
        percentage: 0,
        isRated: false,
      );
    }

    final applicableTasks = getApplicableTasksForDate(normalizedDate, tasks);
    final isCalculable =
        applicableTasks.isNotEmpty ||
        positiveLogs.values.any((value) => value > 0) ||
        negativeLogs.values.any((value) => value > 0);

    return calculateDailyScoreWithPeriodicTasks(
      selectedDate: normalizedDate,
      positiveLogs: positiveLogs,
      negativeLogs: negativeLogs,
      tasks: applicableTasks,
      habits: habits,
      locale: locale,
      isRated: isCalculable,
    );
  }

  /// Returns `true` when [task] is active and already existed on [date].
  bool taskExistsOnDate(PositiveTask task, DateTime date) {
    if (!task.isActive) return false;
    final normalizedDate = DayEntry.normalizeDate(date);
    final createdDate = DayEntry.normalizeDate(task.createdAt);
    return !createdDate.isAfter(normalizedDate);
  }

  /// Returns active tasks that existed on [date].
  List<PositiveTask> getApplicableTasksForDate(
    DateTime date,
    List<PositiveTask> tasks,
  ) {
    final normalizedDate = DayEntry.normalizeDate(date);
    return tasks
        .where((task) => taskExistsOnDate(task, normalizedDate))
        .toList();
  }

  /// A date is calculable when there is an entry or at least one applicable
  /// positive task.
  bool isDateCalculable(
    DateTime date,
    List<PositiveTask> tasks,
    DayEntry? entry,
  ) {
    if (isFutureDate(date)) return false;
    if (isToday(date) && entry == null) return false;
    if (entry != null) return true;
    return getApplicableTasksForDate(date, tasks).isNotEmpty;
  }

  /// Returns true when [date] is after today.
  bool isFutureDate(DateTime date) {
    final normalizedDate = DayEntry.normalizeDate(date);
    final today = DayEntry.normalizeDate(DateTime.now());
    return normalizedDate.isAfter(today);
  }

  /// Returns true when [date] equals today.
  bool isToday(DateTime date) {
    final normalizedDate = DayEntry.normalizeDate(date);
    final today = DayEntry.normalizeDate(DateTime.now());
    return DayEntry.toDateKey(normalizedDate) == DayEntry.toDateKey(today);
  }

  /// Returns the start date of the week for [date].
  ///
  /// Weekly tasks start on Saturday for Arabic locale and on Monday for
  /// English locale.
  DateTime getWeekStart(DateTime date, Locale locale) {
    final normalized = DayEntry.normalizeDate(date);
    final weekStartDay = locale.languageCode == 'ar'
        ? DateTime.saturday
        : DateTime.monday;
    final delta = (normalized.weekday - weekStartDay + 7) % 7;
    return normalized.subtract(Duration(days: delta));
  }

  /// Returns the first day of the month for [date].
  ///
  /// Monthly tasks always start on day 1.
  DateTime getMonthStart(DateTime date) {
    final normalized = DayEntry.normalizeDate(date);
    return DateTime(normalized.year, normalized.month, 1);
  }

  /// Returns the last day of the month for [date].
  DateTime getMonthEnd(DateTime date) {
    final normalized = DayEntry.normalizeDate(date);
    return DateTime(normalized.year, normalized.month + 1, 0);
  }

  /// Builds an inclusive date-only list from [start] to [end].
  List<DateTime> getDaysInRange(DateTime start, DateTime end) {
    final normalizedStart = DayEntry.normalizeDate(start);
    final normalizedEnd = DayEntry.normalizeDate(end);
    if (normalizedStart.isAfter(normalizedEnd)) return const <DateTime>[];

    final days = <DateTime>[];
    var cursor = normalizedStart;
    while (!cursor.isAfter(normalizedEnd)) {
      days.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return days;
  }

  /// Sums completed count for one task between [start] and [end] (inclusive).
  int getTaskCompletedInRange(String taskId, DateTime start, DateTime end) {
    var total = 0;
    for (final day in getDaysInRange(start, end)) {
      final entry = getEntryForDate(day);
      total += max(0, entry?.positiveLogs[taskId] ?? 0);
    }
    return total;
  }

  /// Returns progress ratio for [task] in its period up to [selectedDate].
  ///
  /// Daily: current-day completion ratio.
  /// Weekly/Monthly: completed count from period start until selected day.
  double getTaskProgressForDate(
    PositiveTask task,
    DateTime selectedDate,
    Locale locale, {
    Map<String, int>? previewPositiveLogsForSelectedDate,
  }) {
    if (task.targetCount <= 0) return 0;

    final normalizedSelectedDate = DayEntry.normalizeDate(selectedDate);
    if (!taskExistsOnDate(task, normalizedSelectedDate)) return 0;

    final period = _periodBoundsForTask(task, normalizedSelectedDate, locale);
    final effectiveStart = _effectiveTaskRangeStart(task, period.start);
    if (effectiveStart.isAfter(normalizedSelectedDate)) return 0;

    final completedInRange = _getTaskCompletedInRangeWithPreview(
      task.id,
      effectiveStart,
      normalizedSelectedDate,
      previewDate: normalizedSelectedDate,
      previewPositiveLogsForSelectedDate: previewPositiveLogsForSelectedDate,
    );

    final progress = completedInRange / task.targetCount;
    return progress < 0 ? 0.0 : progress;
  }

  /// Returns the maximum allowed count for [task] on [selectedDate].
  ///
  /// Daily tasks keep per-day cap by target count. Weekly/monthly tasks cap
  /// by remaining target count in the whole period.
  int getMaxAllowedCountForTaskOnDate(
    PositiveTask task,
    DateTime selectedDate,
    Locale locale, {
    Map<String, int>? previewPositiveLogsForSelectedDate,
  }) {
    if (task.targetCount <= 0) return 0;
    final normalizedSelectedDate = DayEntry.normalizeDate(selectedDate);
    if (!taskExistsOnDate(task, normalizedSelectedDate)) return 0;

    if (task.frequencyType == FrequencyType.daily) {
      return task.targetCount;
    }

    final period = _periodBoundsForTask(task, normalizedSelectedDate, locale);
    final effectiveStart = _effectiveTaskRangeStart(task, period.start);
    if (effectiveStart.isAfter(period.end)) return 0;

    final totalWithPreview = _getTaskCompletedInRangeWithPreview(
      task.id,
      effectiveStart,
      period.end,
      previewDate: normalizedSelectedDate,
      previewPositiveLogsForSelectedDate: previewPositiveLogsForSelectedDate,
    );

    final currentForSelectedDate = max(
      0,
      previewPositiveLogsForSelectedDate?[task.id] ??
          (getEntryForDate(normalizedSelectedDate)?.positiveLogs[task.id] ?? 0),
    );

    final completedWithoutSelectedDate = max(
      0,
      totalWithPreview - currentForSelectedDate,
    );
    final remainingForSelectedDate = max(
      0,
      task.targetCount - completedWithoutSelectedDate,
    );
    return remainingForSelectedDate;
  }

  /// Shared score formula used by persisted and preview calculations.
  ///
  /// Weekly tasks:
  /// - period starts on Saturday for Arabic locale, Monday for English locale
  /// - missing penalty is applied only after the week ends
  /// - penalty is distributed equally across 7 days
  ///
  /// Monthly tasks:
  /// - period starts on day 1 and ends on the month's last day
  /// - missing penalty is applied only after the month ends
  /// - penalty is distributed across all days in that month
  DailyScore calculateDailyScoreWithPeriodicTasks({
    required DateTime selectedDate,
    required Map<String, int> positiveLogs,
    required Map<String, int> negativeLogs,
    required List<PositiveTask> tasks,
    required List<NegativeHabit> habits,
    required Locale locale,
    required bool isRated,
  }) {
    final normalizedSelectedDate = DayEntry.normalizeDate(selectedDate);
    final activeTasks = tasks.where((task) => task.isActive).toList();
    final activeHabits = habits.where((habit) => habit.isActive).toList();

    var positivePoints = 0.0;
    var negativePoints = 0.0;
    var totalPossiblePositivePoints = 0.0;

    for (final task in activeTasks) {
      if (task.targetCount <= 0) continue;
      if (!taskExistsOnDate(task, normalizedSelectedDate)) continue;

      totalPossiblePositivePoints += task.weight;
      final todayCompleted = max(0, positiveLogs[task.id] ?? 0);

      switch (task.frequencyType) {
        case FrequencyType.daily:
          final completionRatio = todayCompleted / task.targetCount;
          final taskScore =
              (completionRatio * task.weight) -
              ((1 - completionRatio) * task.weight);
          positivePoints += max(0.0, taskScore);
          negativePoints += max(0.0, -taskScore);
          break;
        case FrequencyType.weekly:
        case FrequencyType.monthly:
          final period = _periodBoundsForTask(
            task,
            normalizedSelectedDate,
            locale,
          );
          final effectiveStart = _effectiveTaskRangeStart(task, period.start);
          if (effectiveStart.isAfter(normalizedSelectedDate)) {
            break;
          }

          positivePoints += (todayCompleted / task.targetCount) * task.weight;

          final periodPenalty = _getDistributedPenaltyForCompletedPeriod(
            task: task,
            periodStart: effectiveStart,
            periodEnd: period.end,
            periodLengthDays: period.lengthDays,
            selectedDate: normalizedSelectedDate,
            previewPositiveLogsForSelectedDate: positiveLogs,
          );
          negativePoints += periodPenalty;
          break;
      }
    }

    for (final habit in activeHabits) {
      final actualCount = max(0, negativeLogs[habit.id] ?? 0);
      negativePoints += actualCount * habit.weight;
    }

    final rawScore = positivePoints - negativePoints;
    final percentage = totalPossiblePositivePoints == 0
        ? 0.0
        : (rawScore / totalPossiblePositivePoints) * 100;

    return DailyScore(
      positivePoints: positivePoints,
      negativePoints: negativePoints,
      rawScore: rawScore,
      percentage: percentage,
      isRated: isRated,
    );
  }

  _PeriodBounds _periodBoundsForTask(
    PositiveTask task,
    DateTime date,
    Locale locale,
  ) {
    final normalizedDate = DayEntry.normalizeDate(date);

    switch (task.frequencyType) {
      case FrequencyType.daily:
        return _PeriodBounds(
          start: normalizedDate,
          end: normalizedDate,
          lengthDays: 1,
        );
      case FrequencyType.weekly:
        final start = getWeekStart(normalizedDate, locale);
        final end = start.add(const Duration(days: 6));
        return _PeriodBounds(start: start, end: end, lengthDays: 7);
      case FrequencyType.monthly:
        final start = getMonthStart(normalizedDate);
        final end = getMonthEnd(normalizedDate);
        final length = getDaysInRange(start, end).length;
        return _PeriodBounds(start: start, end: end, lengthDays: length);
    }
  }

  int _getTaskCompletedInRangeWithPreview(
    String taskId,
    DateTime start,
    DateTime end, {
    DateTime? previewDate,
    Map<String, int>? previewPositiveLogsForSelectedDate,
  }) {
    final normalizedStart = DayEntry.normalizeDate(start);
    final normalizedEnd = DayEntry.normalizeDate(end);
    if (normalizedStart.isAfter(normalizedEnd)) return 0;

    var total = 0;
    final normalizedPreviewDate = previewDate == null
        ? null
        : DayEntry.normalizeDate(previewDate);

    for (final day in getDaysInRange(normalizedStart, normalizedEnd)) {
      if (normalizedPreviewDate != null &&
          previewPositiveLogsForSelectedDate != null &&
          DayEntry.toDateKey(day) ==
              DayEntry.toDateKey(normalizedPreviewDate)) {
        total += max(0, previewPositiveLogsForSelectedDate[taskId] ?? 0);
      } else {
        total += max(0, getEntryForDate(day)?.positiveLogs[taskId] ?? 0);
      }
    }

    return total;
  }

  double _getDistributedPenaltyForCompletedPeriod({
    required PositiveTask task,
    required DateTime periodStart,
    required DateTime periodEnd,
    required int periodLengthDays,
    required DateTime selectedDate,
    required Map<String, int> previewPositiveLogsForSelectedDate,
  }) {
    final today = DayEntry.normalizeDate(DateTime.now());

    // Penalties are applied only when the whole period is complete.
    if (!periodEnd.isBefore(today)) return 0.0;

    final totalCompleted = _getTaskCompletedInRangeWithPreview(
      task.id,
      periodStart,
      periodEnd,
      previewDate: selectedDate,
      previewPositiveLogsForSelectedDate: previewPositiveLogsForSelectedDate,
    );

    if (totalCompleted >= task.targetCount) return 0.0;

    final missingCount = task.targetCount - totalCompleted;
    final missingRatio = (missingCount / task.targetCount).clamp(0.0, 1.0);
    final totalPenalty = missingRatio * task.weight;
    return totalPenalty / max(1, periodLengthDays);
  }

  DateTime _effectiveTaskRangeStart(PositiveTask task, DateTime start) {
    final createdDate = DayEntry.normalizeDate(task.createdAt);
    final normalizedStart = DayEntry.normalizeDate(start);
    return createdDate.isAfter(normalizedStart) ? createdDate : normalizedStart;
  }
}

class _PeriodBounds {
  const _PeriodBounds({
    required this.start,
    required this.end,
    required this.lengthDays,
  });

  final DateTime start;
  final DateTime end;
  final int lengthDays;
}
