import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/negative_habit.dart';
import '../../models/positive_task.dart';
import '../../providers/day_entries_provider.dart';
import '../../providers/negative_habits_provider.dart';
import '../../providers/positive_tasks_provider.dart';

/// Statistics screen for trends across a selectable date range.
///
/// It offers two chart groups:
/// - daily total raw score
/// - selected task/habit counts per day
///
/// All data comes from providers; this UI never calls Hive directly.
class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});

  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  late DateTime _startDate;
  late DateTime _endDate;

  final Set<String> _selectedPositiveTaskIds = <String>{};
  final Set<String> _selectedNegativeHabitIds = <String>{};

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    _endDate = normalizedToday;
    _startDate = normalizedToday.subtract(const Duration(days: 7));
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final dateFormat = DateFormat('yyyy-MM-dd');
    final theme = Theme.of(context);

    // Watch entries so charts refresh when data changes.
    ref.watch(dayEntriesProvider);
    final dayEntriesNotifier = ref.read(dayEntriesProvider.notifier);

    final activeTasks = ref
        .watch(positiveTasksProvider)
        .where((task) => task.isActive)
        .toList();
    final activeHabits = ref
        .watch(negativeHabitsProvider)
        .where((habit) => habit.isActive)
        .toList();

    // Invalid ranges are handled in UI (message + empty charts).
    final hasValidRange = !_startDate.isAfter(_endDate);
    final days = hasValidRange
        ? _daysInRange(_startDate, _endDate)
        : <DateTime>[];

    final selectedTasks = activeTasks
        .where((task) => _selectedPositiveTaskIds.contains(task.id))
        .toList();
    final selectedHabits = activeHabits
        .where((habit) => _selectedNegativeHabitIds.contains(habit.id))
        .toList();

    // Used to avoid drawing charts when no persisted data exists.
    final hasAnyEntryInRange = days.any(
      (day) => dayEntriesNotifier.getEntryForDate(day) != null,
    );

    final dailyScoreSeries = _buildDailyScoreSeries(
      days: days,
      activeTasks: activeTasks,
      activeHabits: activeHabits,
      dayEntriesNotifier: dayEntriesNotifier,
      label: strings.score,
    );

    final selectedItemSeries = _buildSelectedItemsSeries(
      days: days,
      selectedTasks: selectedTasks,
      selectedHabits: selectedHabits,
      dayEntriesNotifier: dayEntriesNotifier,
    );

    final selectionWidgets = <Widget>[
      Text(strings.selectTasksAndForbidden, style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
    ];

    if (activeTasks.isEmpty && activeHabits.isEmpty) {
      selectionWidgets.add(Text(strings.noActiveItems));
    } else {
      if (activeTasks.isNotEmpty) {
        selectionWidgets.add(
          Text(strings.tasks, style: theme.textTheme.titleSmall),
        );
      }

      for (final task in activeTasks) {
        selectionWidgets.add(
          CheckboxListTile(
            value: _selectedPositiveTaskIds.contains(task.id),
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedPositiveTaskIds.add(task.id);
                } else {
                  _selectedPositiveTaskIds.remove(task.id);
                }
              });
            },
            title: Text(task.name),
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        );
      }

      if (activeHabits.isNotEmpty) {
        selectionWidgets.add(const SizedBox(height: 6));
        selectionWidgets.add(
          Text(strings.forbidden, style: theme.textTheme.titleSmall),
        );
      }

      for (final habit in activeHabits) {
        selectionWidgets.add(
          CheckboxListTile(
            value: _selectedNegativeHabitIds.contains(habit.id),
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedNegativeHabitIds.add(habit.id);
                } else {
                  _selectedNegativeHabitIds.remove(habit.id);
                }
              });
            },
            title: Text(habit.name),
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(strings.statistics)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: Text(strings.fromDate),
                    subtitle: Text(dateFormat.format(_startDate)),
                    onTap: () => _pickDate(isStart: true),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_available_outlined),
                    title: Text(strings.toDate),
                    subtitle: Text(dateFormat.format(_endDate)),
                    onTap: () => _pickDate(isStart: false),
                  ),
                  if (!hasValidRange)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        strings.chooseValidDate,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: selectionWidgets,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ChartCard(
            title: strings.dailyScores,
            noDataText: strings.noData,
            hasValidRange: hasValidRange,
            hasData: hasAnyEntryInRange,
            series: dailyScoreSeries,
            days: days,
          ),
          const SizedBox(height: 12),
          _ChartCard(
            title: strings.selectedItems,
            noDataText: strings.noData,
            hasValidRange: hasValidRange,
            hasData: hasAnyEntryInRange && selectedItemSeries.isNotEmpty,
            series: selectedItemSeries,
            days: days,
          ),
        ],
      ),
    );
  }

  /// Opens date picker for start or end date.
  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2035, 12, 31),
      initialDate: initial,
      locale: Localizations.localeOf(context),
    );

    if (picked == null) return;

    final normalized = DateTime(picked.year, picked.month, picked.day);
    setState(() {
      if (isStart) {
        _startDate = normalized;
      } else {
        _endDate = normalized;
      }
    });
  }

  /// Builds an inclusive day list from start to end (both included).
  List<DateTime> _daysInRange(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var cursor = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);

    while (!cursor.isAfter(last)) {
      days.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }

    return days;
  }

  /// Builds chart series for daily total raw score.
  ///
  /// Score values come from provider scoring (`getScoreForDate`) so business
  /// logic stays centralized.
  List<_ChartSeries> _buildDailyScoreSeries({
    required List<DateTime> days,
    required List<PositiveTask> activeTasks,
    required List<NegativeHabit> activeHabits,
    required DayEntriesNotifier dayEntriesNotifier,
    required String label,
  }) {
    final spots = <FlSpot>[];
    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      final score = dayEntriesNotifier.getScoreForDate(
        day,
        activeTasks,
        activeHabits,
      );
      spots.add(FlSpot(i.toDouble(), score.rawScore));
    }

    return [_ChartSeries(label: label, color: Colors.blue, spots: spots)];
  }

  /// Builds chart series for selected item counts.
  ///
  /// - Positive task line value: `entry.positiveLogs[taskId] ?? 0`
  /// - Negative habit line value: `entry.negativeLogs[habitId] ?? 0`
  List<_ChartSeries> _buildSelectedItemsSeries({
    required List<DateTime> days,
    required List<PositiveTask> selectedTasks,
    required List<NegativeHabit> selectedHabits,
    required DayEntriesNotifier dayEntriesNotifier,
  }) {
    const palette = <Color>[
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
      Colors.indigo,
      Colors.cyan,
      Colors.pink,
    ];

    final series = <_ChartSeries>[];
    var colorIndex = 0;

    for (final task in selectedTasks) {
      final spots = <FlSpot>[];
      for (var i = 0; i < days.length; i++) {
        final entry = dayEntriesNotifier.getEntryForDate(days[i]);
        final value = entry?.positiveLogs[task.id] ?? 0;
        spots.add(FlSpot(i.toDouble(), value.toDouble()));
      }

      series.add(
        _ChartSeries(
          label: task.name,
          color: palette[colorIndex % palette.length],
          spots: spots,
        ),
      );
      colorIndex++;
    }

    for (final habit in selectedHabits) {
      final spots = <FlSpot>[];
      for (var i = 0; i < days.length; i++) {
        final entry = dayEntriesNotifier.getEntryForDate(days[i]);
        final value = entry?.negativeLogs[habit.id] ?? 0;
        spots.add(FlSpot(i.toDouble(), value.toDouble()));
      }

      series.add(
        _ChartSeries(
          label: habit.name,
          color: palette[colorIndex % palette.length],
          spots: spots,
        ),
      );
      colorIndex++;
    }

    return series;
  }
}

/// Generic card wrapper for line chart + empty state + simple legend.
class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.noDataText,
    required this.hasValidRange,
    required this.hasData,
    required this.series,
    required this.days,
  });

  final String title;
  final String noDataText;
  final bool hasValidRange;
  final bool hasData;
  final List<_ChartSeries> series;
  final List<DateTime> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Prevents chart widget from receiving invalid/empty datasets.
    final hasChart = hasValidRange && hasData && series.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (!hasChart)
              Text(noDataText)
            else
              SizedBox(
                height: 240,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                    lineBarsData: series
                        .map(
                          (item) => LineChartBarData(
                            spots: item.spots,
                            color: item.color,
                            isCurved: false,
                            barWidth: 2.2,
                            dotData: const FlDotData(show: false),
                          ),
                        )
                        .toList(),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: _bottomInterval(days.length),
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= days.length) {
                              return const SizedBox.shrink();
                            }
                            final day = days[index];
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text('${day.day}/${day.month}'),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (series.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...series.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item.label)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static double _bottomInterval(int dayCount) {
    if (dayCount <= 8) return 1;
    if (dayCount <= 16) return 2;
    if (dayCount <= 31) return 4;
    return 7;
  }
}

/// Internal chart line definition.
class _ChartSeries {
  const _ChartSeries({
    required this.label,
    required this.color,
    required this.spots,
  });

  final String label;
  final Color color;
  final List<FlSpot> spots;
}
