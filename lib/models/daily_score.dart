/// Computed score values for one day.
///
/// This model is not persisted directly. It is derived from [DayEntry] and the
/// currently active tasks/habits.
class DailyScore {
  const DailyScore({
    required this.positivePoints,
    required this.negativePoints,
    required this.rawScore,
    required this.percentage,
    required this.isRated,
  });

  final double positivePoints;
  final double negativePoints;
  final double rawScore;

  /// `rawScore / totalPossiblePositivePoints * 100`.
  ///
  /// This value is intentionally not clamped.
  final double percentage;

  /// `true` when a day entry exists for the requested day.
  ///
  /// `false` means "not rated yet".
  final bool isRated;
}
