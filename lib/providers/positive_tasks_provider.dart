import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/positive_task.dart';
import '../storage/hive_service.dart';

/// Riverpod state for positive tasks.
///
/// This provider is the write/read boundary between UI and local storage.
final positiveTasksProvider =
    StateNotifierProvider<PositiveTasksNotifier, List<PositiveTask>>(
      (ref) => PositiveTasksNotifier(),
    );

/// Handles positive task list operations and validation.
class PositiveTasksNotifier extends StateNotifier<List<PositiveTask>> {
  PositiveTasksNotifier() : super(const []) {
    loadTasks();
  }

  static const _uuid = Uuid();

  /// Convenience getter for active tasks only.
  List<PositiveTask> get activeTasks =>
      state.where((task) => task.isActive).toList();

  /// Reloads tasks from local storage.
  Future<void> loadTasks() async {
    state = HiveService.loadAllPositiveTasks();
  }

  /// Adds a task after basic validation.
  ///
  /// Validation:
  /// - name is not empty
  /// - weight >= 0
  /// - targetCount > 0
  /// - id auto-generated when missing
  Future<void> addTask(PositiveTask task) async {
    final name = task.name.trim();
    if (name.isEmpty || task.weight < 0 || task.targetCount <= 0) return;

    final id = task.id.trim().isEmpty ? _uuid.v4() : task.id;
    final toSave = task.copyWith(id: id, name: name);

    await HiveService.savePositiveTask(toSave);
    await loadTasks();
  }

  /// Updates a task after validation.
  Future<void> updateTask(PositiveTask task) async {
    final name = task.name.trim();
    if (task.id.trim().isEmpty ||
        name.isEmpty ||
        task.weight < 0 ||
        task.targetCount <= 0) {
      return;
    }

    await HiveService.savePositiveTask(task.copyWith(name: name));
    await loadTasks();
  }

  /// Deletes a task by id.
  Future<void> deleteTask(String id) async {
    if (id.trim().isEmpty) return;

    await HiveService.deletePositiveTask(id);
    await loadTasks();
  }
}
