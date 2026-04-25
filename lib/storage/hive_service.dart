import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/app_constants.dart';
import '../models/app_category.dart';
import '../models/day_entry.dart';
import '../models/negative_habit.dart';
import '../models/positive_task.dart';

/// Central local-storage gateway for this MVP.
///
/// Why Hive:
/// - offline-first local database
/// - fast key-value operations
/// - simple setup for Flutter beginners
///
/// Why maps (instead of Hive TypeAdapters):
/// - no code generation (`build_runner`) needed
/// - easier to inspect and debug stored records
/// - model classes control serialization via `toMap`/`fromMap`
class HiveService {
  HiveService._();

  static bool _initialized = false;
  static const _uuid = Uuid();

  /// Opens all required boxes and seeds default categories once.
  ///
  /// Boxes:
  /// - `categoriesBox` -> category metadata
  /// - `positiveTasksBox` -> positive tasks
  /// - `negativeHabitsBox` -> negative habits
  /// - `dayEntriesBox` -> one entry per normalized day key (`yyyy-MM-dd`)
  static Future<void> init() async {
    if (_initialized) return;

    await Hive.openBox(AppConstants.categoriesBox);
    await Hive.openBox(AppConstants.positiveTasksBox);
    await Hive.openBox(AppConstants.negativeHabitsBox);
    await Hive.openBox(AppConstants.dayEntriesBox);

    await _seedDefaultCategoriesIfNeeded();
    await _migrateDefaultCategoryNamesToArabic();

    _initialized = true;
  }

  static Box<dynamic> get _categoriesBox =>
      Hive.box(AppConstants.categoriesBox);
  static Box<dynamic> get _positiveTasksBox =>
      Hive.box(AppConstants.positiveTasksBox);
  static Box<dynamic> get _negativeHabitsBox =>
      Hive.box(AppConstants.negativeHabitsBox);
  static Box<dynamic> get _dayEntriesBox =>
      Hive.box(AppConstants.dayEntriesBox);

  /// Returns all categories sorted by creation time.
  static List<AppCategory> loadAllCategories() {
    return _categoriesBox.values
        .whereType<Map>()
        .map(_safeStringDynamicMap)
        .whereType<Map<String, dynamic>>()
        .map(AppCategory.fromMap)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Saves (creates or updates) one category by id.
  static Future<void> saveCategory(AppCategory category) async {
    await _categoriesBox.put(category.id, category.toMap());
  }

  /// Deletes one category by id.
  static Future<void> deleteCategory(String id) async {
    await _categoriesBox.delete(id);
  }

  /// Returns all positive tasks sorted by creation time.
  static List<PositiveTask> loadAllPositiveTasks() {
    return _positiveTasksBox.values
        .whereType<Map>()
        .map(_safeStringDynamicMap)
        .whereType<Map<String, dynamic>>()
        .map(PositiveTask.fromMap)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Saves (creates or updates) one positive task by id.
  static Future<void> savePositiveTask(PositiveTask task) async {
    await _positiveTasksBox.put(task.id, task.toMap());
  }

  /// Deletes one positive task by id.
  static Future<void> deletePositiveTask(String id) async {
    await _positiveTasksBox.delete(id);
  }

  /// Returns all negative habits sorted by creation time.
  static List<NegativeHabit> loadAllNegativeHabits() {
    return _negativeHabitsBox.values
        .whereType<Map>()
        .map(_safeStringDynamicMap)
        .whereType<Map<String, dynamic>>()
        .map(NegativeHabit.fromMap)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Saves (creates or updates) one negative habit by id.
  static Future<void> saveNegativeHabit(NegativeHabit habit) async {
    await _negativeHabitsBox.put(habit.id, habit.toMap());
  }

  /// Deletes one negative habit by id.
  static Future<void> deleteNegativeHabit(String id) async {
    await _negativeHabitsBox.delete(id);
  }

  /// Returns all saved day entries sorted by date.
  static List<DayEntry> loadAllDayEntries() {
    return _dayEntriesBox.values
        .whereType<Map>()
        .map(_safeStringDynamicMap)
        .whereType<Map<String, dynamic>>()
        .map(DayEntry.fromMap)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Loads one day entry using the normalized day key.
  static DayEntry? loadDayEntryByDate(DateTime date) {
    final dateKey = DayEntry.toDateKey(date);
    final raw = _dayEntriesBox.get(dateKey);
    if (raw is! Map) return null;

    final map = _safeStringDynamicMap(raw);
    if (map == null) return null;
    return DayEntry.fromMap(map);
  }

  /// Saves one day entry under a normalized key (`yyyy-MM-dd`).
  ///
  /// Saving the same date again replaces the existing entry for that date,
  /// which prevents duplicates.
  static Future<void> saveDayEntry(DayEntry entry) async {
    final dateKey = DayEntry.toDateKey(entry.date);
    await _dayEntriesBox.put(
      dateKey,
      entry.copyWith(date: DayEntry.normalizeDate(entry.date)).toMap(),
    );
  }

  /// Deletes one day entry by normalized date key.
  static Future<void> deleteDayEntry(DateTime date) async {
    final dateKey = DayEntry.toDateKey(date);
    await _dayEntriesBox.delete(dateKey);
  }

  /// Clears all persisted app data.
  ///
  /// Used by restore flow where backup import should replace current data.
  static Future<void> clearAllData() async {
    await _categoriesBox.clear();
    await _positiveTasksBox.clear();
    await _negativeHabitsBox.clear();
    await _dayEntriesBox.clear();
  }

  /// Seeds default categories only when category storage is empty.
  ///
  /// This method runs during initialization so first-time users see useful
  /// starter categories immediately.
  static Future<void> _seedDefaultCategoriesIfNeeded() async {
    if (_categoriesBox.isNotEmpty) return;

    const defaults = <Map<String, dynamic>>[
      {'name': 'ديني', 'colorValue': Colors.indigo},
      {'name': 'أخلاقي', 'colorValue': Colors.teal},
      {'name': 'عائلة', 'colorValue': Colors.pink},
      {'name': 'عمل', 'colorValue': Colors.blue},
      {'name': 'صحة', 'colorValue': Colors.green},
      {'name': 'تعلّم', 'colorValue': Colors.orange},
      {'name': 'رياضة', 'colorValue': Colors.red},
      {'name': 'أخرى', 'colorValue': Colors.grey},
    ];

    for (final item in defaults) {
      final category = AppCategory(
        id: _uuid.v4(),
        name: item['name'] as String,
        colorValue: (item['colorValue'] as MaterialColor).toARGB32(),
        isDefault: true,
        createdAt: DateTime.now(),
      );
      await saveCategory(category);
    }
  }

  /// Migrates legacy seeded English default category names to Arabic.
  ///
  /// This keeps existing ids and avoids duplicates by removing legacy English
  /// defaults when an Arabic counterpart already exists.
  static Future<void> _migrateDefaultCategoryNamesToArabic() async {
    if (_categoriesBox.isEmpty) return;

    const englishToArabic = <String, String>{
      'Religion': 'ديني',
      'Ethics': 'أخلاقي',
      'Family': 'عائلة',
      'Work': 'عمل',
      'Health': 'صحة',
      'Learning': 'تعلّم',
      'Sport': 'رياضة',
      'Other': 'أخرى',
    };

    final categories = loadAllCategories();
    for (final category in categories) {
      if (!category.isDefault) continue;

      final arabicName = englishToArabic[category.name];
      if (arabicName == null) continue;

      final hasArabicDuplicate = categories.any(
        (other) =>
            other.id != category.id &&
            other.name == arabicName &&
            other.isDefault,
      );

      if (hasArabicDuplicate) {
        await deleteCategory(category.id);
        continue;
      }

      await saveCategory(category.copyWith(name: arabicName));
    }
  }

  /// Safely converts loosely typed Hive map data to `Map<String, dynamic>`.
  ///
  /// Hive values can be dynamic, so this helper avoids runtime cast errors
  /// when reading legacy or malformed records.
  static Map<String, dynamic>? _safeStringDynamicMap(dynamic raw) {
    if (raw is! Map) return null;

    final map = <String, dynamic>{};
    raw.forEach((key, value) {
      map[key.toString()] = value;
    });
    return map;
  }
}
