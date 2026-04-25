/// Saved evaluation data for a single calendar day.
///
/// Each map key is a task/habit id, and each value is the count for that day.
class DayEntry {
  const DayEntry({
    required this.date,
    required this.positiveLogs,
    required this.negativeLogs,
    required this.note,
  });

  final DateTime date;
  final Map<String, int> positiveLogs;
  final Map<String, int> negativeLogs;
  final String note;

  /// Creates a copy with optional field updates.
  DayEntry copyWith({
    DateTime? date,
    Map<String, int>? positiveLogs,
    Map<String, int>? negativeLogs,
    String? note,
  }) {
    return DayEntry(
      date: date ?? this.date,
      positiveLogs: positiveLogs ?? this.positiveLogs,
      negativeLogs: negativeLogs ?? this.negativeLogs,
      note: note ?? this.note,
    );
  }

  /// Converts this entry to a storable map.
  ///
  /// The date is persisted as a normalized key (`yyyy-MM-dd`) so one day
  /// always maps to one Hive record.
  Map<String, dynamic> toMap() {
    return {
      'date': toDateKey(date),
      'positiveLogs': positiveLogs,
      'negativeLogs': negativeLogs,
      'note': note,
    };
  }

  /// Restores a [DayEntry] from persisted map data.
  factory DayEntry.fromMap(Map<String, dynamic> map) {
    return DayEntry(
      date: fromDateKey(map['date'] as String? ?? ''),
      positiveLogs: _toIntMap(map['positiveLogs']),
      negativeLogs: _toIntMap(map['negativeLogs']),
      note: map['note'] as String? ?? '',
    );
  }

  /// Removes time parts from a [DateTime].
  ///
  /// This guarantees all reads/writes for the same day use the same key.
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Converts a date to the canonical storage key: `yyyy-MM-dd`.
  static String toDateKey(DateTime date) {
    final normalized = normalizeDate(date);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  /// Parses a canonical date key back to a normalized [DateTime].
  static DateTime fromDateKey(String key) {
    final parsed = DateTime.tryParse(key);
    if (parsed == null) return normalizeDate(DateTime.now());
    return normalizeDate(parsed);
  }

  /// Safely converts dynamic map values to `Map<String, int>`.
  ///
  /// This guards against type mismatches in loosely typed local storage.
  static Map<String, int> _toIntMap(dynamic raw) {
    if (raw is! Map) return const <String, int>{};

    final result = <String, int>{};
    raw.forEach((key, value) {
      final k = key.toString();
      final v = value is int ? value : int.tryParse(value.toString()) ?? 0;
      result[k] = v;
    });
    return result;
  }
}
