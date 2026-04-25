import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/negative_habit.dart';
import '../storage/hive_service.dart';

/// Riverpod state for negative habits.
///
/// UI should use this provider so storage logic stays centralized.
final negativeHabitsProvider =
    StateNotifierProvider<NegativeHabitsNotifier, List<NegativeHabit>>(
      (ref) => NegativeHabitsNotifier(),
    );

/// Handles negative habit CRUD and validation.
class NegativeHabitsNotifier extends StateNotifier<List<NegativeHabit>> {
  NegativeHabitsNotifier() : super(const []) {
    loadHabits();
  }

  static const _uuid = Uuid();

  /// Convenience getter for active habits only.
  List<NegativeHabit> get activeHabits =>
      state.where((habit) => habit.isActive).toList();

  /// Reloads habits from local storage.
  Future<void> loadHabits() async {
    state = HiveService.loadAllNegativeHabits();
  }

  /// Adds a habit after basic validation.
  Future<void> addHabit(NegativeHabit habit) async {
    final name = habit.name.trim();
    if (name.isEmpty || habit.weight < 0) return;

    final id = habit.id.trim().isEmpty ? _uuid.v4() : habit.id;
    final safeTarget = habit.targetCount <= 0 ? 1 : habit.targetCount;
    final toSave = habit.copyWith(id: id, name: name, targetCount: safeTarget);

    await HiveService.saveNegativeHabit(toSave);
    await loadHabits();
  }

  /// Updates a habit after validation.
  Future<void> updateHabit(NegativeHabit habit) async {
    final name = habit.name.trim();
    if (habit.id.trim().isEmpty || name.isEmpty || habit.weight < 0) {
      return;
    }

    final safeTarget = habit.targetCount <= 0 ? 1 : habit.targetCount;
    await HiveService.saveNegativeHabit(
      habit.copyWith(name: name, targetCount: safeTarget),
    );
    await loadHabits();
  }

  /// Deletes a habit by id.
  Future<void> deleteHabit(String id) async {
    if (id.trim().isEmpty) return;

    await HiveService.deleteNegativeHabit(id);
    await loadHabits();
  }
}
