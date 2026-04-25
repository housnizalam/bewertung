import 'frequency_type.dart';

/// A positive behavior the user wants to complete.
///
/// Example: praying, reading, or exercising.
class PositiveTask {
  const PositiveTask({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.weight,
    required this.targetCount,
    required this.frequencyType,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String categoryId;
  final double weight;
  final int targetCount;
  final FrequencyType frequencyType;
  final bool isActive;
  final DateTime createdAt;

  /// Returns a copy with updated values.
  PositiveTask copyWith({
    String? id,
    String? name,
    String? categoryId,
    double? weight,
    int? targetCount,
    FrequencyType? frequencyType,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return PositiveTask(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      weight: weight ?? this.weight,
      targetCount: targetCount ?? this.targetCount,
      frequencyType: frequencyType ?? this.frequencyType,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Serializes this task to a map for Hive storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'weight': weight,
      'targetCount': targetCount,
      'frequencyType': frequencyType.name,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Deserializes a task from a persisted map.
  factory PositiveTask.fromMap(Map<String, dynamic> map) {
    return PositiveTask(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      weight: (map['weight'] as num?)?.toDouble() ?? 0,
      targetCount: map['targetCount'] as int? ?? 0,
      frequencyType: FrequencyType.fromName(
        map['frequencyType'] as String? ?? 'daily',
      ),
      isActive: map['isActive'] as bool? ?? true,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
