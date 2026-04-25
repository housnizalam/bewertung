import 'frequency_type.dart';

/// A negative behavior the user tries to reduce/avoid.
///
/// Example: procrastination or other forbidden/undesired actions.
class NegativeHabit {
  const NegativeHabit({
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

  /// Returns a copy with selected fields changed.
  NegativeHabit copyWith({
    String? id,
    String? name,
    String? categoryId,
    double? weight,
    int? targetCount,
    FrequencyType? frequencyType,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return NegativeHabit(
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

  /// Serializes this habit into a map for Hive.
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

  /// Restores a habit from a persisted map.
  factory NegativeHabit.fromMap(Map<String, dynamic> map) {
    final rawTargetCount = map['targetCount'] as int? ?? 1;

    return NegativeHabit(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      weight: (map['weight'] as num?)?.toDouble() ?? 0,
      targetCount: rawTargetCount <= 0 ? 1 : rawTargetCount,
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
