import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_score.dart';
import '../models/day_entry.dart';
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
  ) {
    final entry = getEntryForDate(date);
    if (entry == null) {
      return const DailyScore(
        positivePoints: 0,
        negativePoints: 0,
        rawScore: 0,
        percentage: 0,
        isRated: false,
      );
    }

    return _calculateScore(entry, tasks, habits, isRated: true);
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
  ) {
    final entry = DayEntry(
      date: DayEntry.normalizeDate(date),
      positiveLogs: Map<String, int>.from(positiveLogs),
      negativeLogs: Map<String, int>.from(negativeLogs),
      note: '',
    );

    return _calculateScore(entry, tasks, habits, isRated: true);
  }

  /// Shared score formula used by both persisted and preview calculations.
  ///
  /// Formula:
  /// - positivePoints += min(completed/target, 1.0) * weight
  /// - negativePoints += actual * weight
  /// - rawScore = positivePoints - negativePoints
  /// - percentage = (rawScore / totalPossiblePositivePoints) * 100
  ///
  /// Note: percentage is intentionally not clamped.
  DailyScore _calculateScore(
    DayEntry entry,
    List<PositiveTask> tasks,
    List<NegativeHabit> habits, {
    required bool isRated,
  }) {
    final activeTasks = tasks.where((task) => task.isActive).toList();
    final activeHabits = habits.where((habit) => habit.isActive).toList();

    var positivePoints = 0.0;
    var negativePoints = 0.0;
    var totalPossiblePositivePoints = 0.0;

    for (final task in activeTasks) {
      if (task.targetCount <= 0) continue;

      totalPossiblePositivePoints += task.weight;
      final completedCount = max(0, entry.positiveLogs[task.id] ?? 0);
      final completionRatio = (completedCount / task.targetCount).clamp(
        0.0,
        1.0,
      );
      positivePoints += completionRatio * task.weight;
    }

    for (final habit in activeHabits) {
      final actualCount = max(0, entry.negativeLogs[habit.id] ?? 0);
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
}
