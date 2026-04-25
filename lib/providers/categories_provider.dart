import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/app_category.dart';
import '../storage/hive_service.dart';

/// Riverpod state for categories.
///
/// UI reads this provider and sends mutations here instead of calling Hive
/// directly, keeping storage details in one place.
final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<AppCategory>>(
      (ref) => CategoriesNotifier(),
    );

/// Manages category list lifecycle and CRUD actions.
class CategoriesNotifier extends StateNotifier<List<AppCategory>> {
  CategoriesNotifier() : super(const []) {
    loadCategories();
  }

  static const _uuid = Uuid();

  /// Reloads categories from local storage.
  Future<void> loadCategories() async {
    state = HiveService.loadAllCategories();
  }

  /// Adds a category after basic validation.
  ///
  /// Validation:
  /// - name must not be empty
  /// - id is auto-generated when missing
  Future<void> addCategory(AppCategory category) async {
    final name = category.name.trim();
    if (name.isEmpty) return;

    final id = category.id.trim().isEmpty ? _uuid.v4() : category.id;
    final toSave = category.copyWith(id: id, name: name);

    await HiveService.saveCategory(toSave);
    await loadCategories();
  }

  /// Updates an existing category after basic validation.
  Future<void> updateCategory(AppCategory category) async {
    final name = category.name.trim();
    if (name.isEmpty || category.id.trim().isEmpty) return;

    await HiveService.saveCategory(category.copyWith(name: name));
    await loadCategories();
  }

  /// Deletes a category by id.
  Future<void> deleteCategory(String id) async {
    if (id.trim().isEmpty) return;

    await HiveService.deleteCategory(id);
    await loadCategories();
  }
}
