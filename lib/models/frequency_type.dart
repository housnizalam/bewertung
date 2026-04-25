/// Defines how often a task or habit should be tracked.
///
/// This enum is saved as text in local storage using [name], then restored
/// with [fromName].
enum FrequencyType {
  daily,
  weekly,
  monthly;

  /// Human-readable label used in the UI.
  String get label {
    switch (this) {
      case FrequencyType.daily:
        return 'Daily';
      case FrequencyType.weekly:
        return 'Weekly';
      case FrequencyType.monthly:
        return 'Monthly';
    }
  }

  /// Parses a persisted string value back into [FrequencyType].
  ///
  /// Defaults to [FrequencyType.daily] for unknown values to keep the app
  /// resilient against invalid/old data.
  static FrequencyType fromName(String name) {
    switch (name.toLowerCase()) {
      case 'daily':
        return FrequencyType.daily;
      case 'weekly':
        return FrequencyType.weekly;
      case 'monthly':
        return FrequencyType.monthly;
      default:
        return FrequencyType.daily;
    }
  }
}
