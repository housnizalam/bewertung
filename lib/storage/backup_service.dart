import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/app_category.dart';
import '../models/day_entry.dart';
import '../models/negative_habit.dart';
import '../models/positive_task.dart';
import 'hive_service.dart';

class BackupService {
  BackupService._();

  static const int _backupVersion = 1;

  static Future<String> exportToJsonFile() async {
    final now = DateTime.now();
    final timestamp =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    final fileName = 'daily_evaluation_backup_$timestamp.json';
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');

    final payload = <String, dynamic>{
      'version': _backupVersion,
      'exportedAt': now.toIso8601String(),
      'categories': HiveService.loadAllCategories()
          .map((e) => e.toMap())
          .toList(),
      'positiveTasks': HiveService.loadAllPositiveTasks()
          .map((e) => e.toMap())
          .toList(),
      'negativeHabits': HiveService.loadAllNegativeHabits()
          .map((e) => e.toMap())
          .toList(),
      'dayEntries': HiveService.loadAllDayEntries()
          .map((e) => e.toMap())
          .toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(payload);
    await file.writeAsString(jsonString);
    return file.path;
  }

  static bool validateBackupJson(Map<String, dynamic> jsonMap) {
    final version = jsonMap['version'];
    final exportedAt = jsonMap['exportedAt'];
    final categories = jsonMap['categories'];
    final positiveTasks = jsonMap['positiveTasks'];
    final negativeHabits = jsonMap['negativeHabits'];
    final dayEntries = jsonMap['dayEntries'];

    return version is int &&
        exportedAt is String &&
        categories is List &&
        positiveTasks is List &&
        negativeHabits is List &&
        dayEntries is List;
  }

  static Future<void> importFromJsonFile(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    final decoded = jsonDecode(content);

    if (decoded is! Map) {
      throw const FormatException('Invalid backup JSON.');
    }

    final jsonMap = _safeStringDynamicMap(decoded);
    if (jsonMap == null || !validateBackupJson(jsonMap)) {
      throw const FormatException('Invalid backup structure.');
    }

    final categories = _parseCategoriesStrict(jsonMap['categories'] as List);
    final positiveTasks = _parsePositiveTasksStrict(
      jsonMap['positiveTasks'] as List,
    );
    final negativeHabits = _parseNegativeHabitsStrict(
      jsonMap['negativeHabits'] as List,
    );
    final dayEntries = _parseDayEntriesStrict(jsonMap['dayEntries'] as List);

    final rollbackCategories = HiveService.loadAllCategories();
    final rollbackTasks = HiveService.loadAllPositiveTasks();
    final rollbackHabits = HiveService.loadAllNegativeHabits();
    final rollbackEntries = HiveService.loadAllDayEntries();

    try {
      await HiveService.clearAllData();

      for (final item in categories) {
        await HiveService.saveCategory(item);
      }
      for (final item in positiveTasks) {
        await HiveService.savePositiveTask(item);
      }
      for (final item in negativeHabits) {
        await HiveService.saveNegativeHabit(item);
      }
      for (final item in dayEntries) {
        await HiveService.saveDayEntry(item);
      }
    } catch (_) {
      await HiveService.clearAllData();
      for (final item in rollbackCategories) {
        await HiveService.saveCategory(item);
      }
      for (final item in rollbackTasks) {
        await HiveService.savePositiveTask(item);
      }
      for (final item in rollbackHabits) {
        await HiveService.saveNegativeHabit(item);
      }
      for (final item in rollbackEntries) {
        await HiveService.saveDayEntry(item);
      }
      rethrow;
    }
  }

  static Map<String, dynamic>? _safeStringDynamicMap(dynamic raw) {
    if (raw is! Map) return null;

    final map = <String, dynamic>{};
    raw.forEach((key, value) {
      map[key.toString()] = value;
    });
    return map;
  }

  static List<AppCategory> _parseCategoriesStrict(List rawList) {
    final parsed = <AppCategory>[];
    final ids = <String>{};

    for (final raw in rawList) {
      final map = _safeStringDynamicMap(raw);
      if (map == null) {
        throw const FormatException('Invalid category item.');
      }

      final item = AppCategory.fromMap(map);
      if (item.id.trim().isEmpty) {
        throw const FormatException('Category id is missing.');
      }
      if (!ids.add(item.id)) {
        throw const FormatException('Duplicate category id in backup.');
      }
      parsed.add(item);
    }

    return parsed;
  }

  static List<PositiveTask> _parsePositiveTasksStrict(List rawList) {
    final parsed = <PositiveTask>[];
    final ids = <String>{};

    for (final raw in rawList) {
      final map = _safeStringDynamicMap(raw);
      if (map == null) {
        throw const FormatException('Invalid positive task item.');
      }

      final item = PositiveTask.fromMap(map);
      if (item.id.trim().isEmpty) {
        throw const FormatException('Positive task id is missing.');
      }
      if (!ids.add(item.id)) {
        throw const FormatException('Duplicate positive task id in backup.');
      }
      parsed.add(item);
    }

    return parsed;
  }

  static List<NegativeHabit> _parseNegativeHabitsStrict(List rawList) {
    final parsed = <NegativeHabit>[];
    final ids = <String>{};

    for (final raw in rawList) {
      final map = _safeStringDynamicMap(raw);
      if (map == null) {
        throw const FormatException('Invalid negative habit item.');
      }

      final item = NegativeHabit.fromMap(map);
      if (item.id.trim().isEmpty) {
        throw const FormatException('Negative habit id is missing.');
      }
      if (!ids.add(item.id)) {
        throw const FormatException('Duplicate negative habit id in backup.');
      }
      parsed.add(item);
    }

    return parsed;
  }

  static List<DayEntry> _parseDayEntriesStrict(List rawList) {
    final parsed = <DayEntry>[];
    final dateKeys = <String>{};

    for (final raw in rawList) {
      final map = _safeStringDynamicMap(raw);
      if (map == null) {
        throw const FormatException('Invalid day entry item.');
      }

      final item = DayEntry.fromMap(map);
      final dateKey = DayEntry.toDateKey(item.date);
      if (!dateKeys.add(dateKey)) {
        throw const FormatException('Duplicate day entry date in backup.');
      }
      parsed.add(item);
    }

    return parsed;
  }
}
