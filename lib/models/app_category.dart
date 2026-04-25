/// Represents a user category used to group tasks and habits.
///
/// Categories are lightweight and stored as maps in Hive, so they can be
/// created and edited without code generation.
class AppCategory {
  const AppCategory({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.isDefault,
    required this.createdAt,
  });

  final String id;
  final String name;
  final int colorValue;
  final bool isDefault;
  final DateTime createdAt;

  /// Returns a modified copy while keeping unchanged fields.
  ///
  /// This is useful in provider update flows where only one or two fields
  /// change.
  AppCategory copyWith({
    String? id,
    String? name,
    int? colorValue,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return AppCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts this category to a map for Hive storage.
  ///
  /// Dates are stored as ISO strings for portability.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Restores a category from a Hive map.
  ///
  /// Safe defaults protect the app from malformed/legacy data.
  factory AppCategory.fromMap(Map<String, dynamic> map) {
    return AppCategory(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      colorValue: map['colorValue'] as int? ?? 0,
      isDefault: map['isDefault'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
