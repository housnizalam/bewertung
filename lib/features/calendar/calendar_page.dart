import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/daily_score.dart';
import '../../providers/day_entries_provider.dart';
import '../../providers/negative_habits_provider.dart';
import '../../providers/positive_tasks_provider.dart';
import '../../shared/widgets/pressable_3d_button.dart';
import '../day/day_detail_page.dart';
import '../../l10n/app_localizations.dart';

/// Calendar screen that visualizes saved day ratings.
///
/// It reads day entries from providers, colors rated days by score, and opens
/// [DayDetailPage] for editing when a day is tapped.
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = DateTime(now.year, now.month, now.day);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final localeCode = locale.languageCode;

    // Watching entries means returning from DayDetailPage automatically
    // rebuilds markers and selected-day summary.
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

    final selectedScore = dayEntriesNotifier.getScoreForDate(
      _selectedDay,
      activeTasks,
      activeHabits,
      locale,
    );

    return Scaffold(
      appBar: AppBar(title: Text(strings.calendar)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final rawButtonSize = (constraints.maxWidth / 7) - 8;
                  final dayButtonSize = rawButtonSize.clamp(36.0, 44.0);

                  return TableCalendar<void>(
                    firstDay: DateTime(2020, 1, 1),
                    lastDay: DateTime(2035, 12, 31),
                    focusedDay: _focusedDay,
                    locale: localeCode,
                    rowHeight: dayButtonSize + 4,
                    daysOfWeekHeight: 34,
                    selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                    onDaySelected: (selectedDay, focusedDay) async {
                      final navigator = Navigator.of(context);
                      final tapped = DateTime(
                        selectedDay.year,
                        selectedDay.month,
                        selectedDay.day,
                      );
                      final canOpenDetails = !ref
                          .read(dayEntriesProvider.notifier)
                          .isFutureDate(tapped);

                      setState(() {
                        _selectedDay = tapped;
                        _focusedDay = focusedDay;
                      });

                      if (!canOpenDetails) return;

                      // Open detail page for the tapped day.
                      await navigator.push(
                        MaterialPageRoute(
                          builder: (_) =>
                              DayDetailPage(selectedDate: _selectedDay),
                        ),
                      );
                    },
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                      });
                    },
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle:
                          (theme.textTheme.bodySmall ?? const TextStyle())
                              .copyWith(fontWeight: FontWeight.w600),
                      weekendStyle:
                          (theme.textTheme.bodySmall ?? const TextStyle())
                              .copyWith(fontWeight: FontWeight.w600),
                    ),
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: true,
                      cellMargin: EdgeInsets.zero,
                      defaultDecoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      dowBuilder: (context, day) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Center(
                            child: Text(
                              DateFormat.E(localeCode).format(day),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                      defaultBuilder: (context, day, focusedDay) {
                        final score = dayEntriesNotifier.getScoreForDate(
                          day,
                          activeTasks,
                          activeHabits,
                          locale,
                        );
                        return _buildDayButton(
                          context: context,
                          day: day,
                          isSelected: false,
                          isToday: false,
                          isOutside: false,
                          ratingColor: _scoreColor(score),
                          size: dayButtonSize,
                        );
                      },
                      selectedBuilder: (context, day, focusedDay) {
                        final score = dayEntriesNotifier.getScoreForDate(
                          day,
                          activeTasks,
                          activeHabits,
                          locale,
                        );
                        return _buildDayButton(
                          context: context,
                          day: day,
                          isSelected: true,
                          isToday: false,
                          isOutside: false,
                          ratingColor: _scoreColor(score),
                          size: dayButtonSize,
                        );
                      },
                      todayBuilder: (context, day, focusedDay) {
                        final score = dayEntriesNotifier.getScoreForDate(
                          day,
                          activeTasks,
                          activeHabits,
                          locale,
                        );
                        return _buildDayButton(
                          context: context,
                          day: day,
                          isSelected: false,
                          isToday: true,
                          isOutside: false,
                          ratingColor: _scoreColor(score),
                          size: dayButtonSize,
                        );
                      },
                      outsideBuilder: (context, day, focusedDay) {
                        final score = dayEntriesNotifier.getScoreForDate(
                          day,
                          activeTasks,
                          activeHabits,
                          locale,
                        );
                        return _buildDayButton(
                          context: context,
                          day: day,
                          isSelected: false,
                          isToday: false,
                          isOutside: true,
                          ratingColor: _scoreColor(score),
                          size: dayButtonSize,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          _LegendCard(
            excellent: strings.excellent,
            medium: strings.medium,
            weak: strings.weak,
            negative: strings.negative,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.selectedDayEvaluation,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (!selectedScore.isRated)
                    Text(strings.noEvaluationForDay)
                  else ...[
                    Text(
                      '${strings.score}: ${selectedScore.rawScore.toStringAsFixed(2)}',
                    ),
                    Text(
                      '${strings.percentage}: ${selectedScore.percentage.toStringAsFixed(1)}%',
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: Pressable3DButton(
                      onPressed: () async {
                        if (ref
                            .read(dayEntriesProvider.notifier)
                            .isFutureDate(_selectedDay)) {
                          return;
                        }
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                DayDetailPage(selectedDate: _selectedDay),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.edit_calendar_outlined),
                          const SizedBox(width: 8),
                          Flexible(child: Text(strings.evaluateThisDay)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color? _scoreColor(DailyScore score) {
    // Unrated days intentionally have no marker.
    if (!score.isRated) return null;

    // Threshold colors:
    // >=80 excellent, >=50 medium, >=0 weak, <0 negative.
    if (score.percentage >= 80) {
      return Colors.green;
    }
    if (score.percentage >= 50) {
      return Colors.orange;
    }
    if (score.percentage >= 0) {
      return Colors.red;
    }
    return Colors.red.shade900;
  }

  Widget _buildDayButton({
    required BuildContext context,
    required DateTime day,
    required bool isSelected,
    required bool isToday,
    required bool isOutside,
    required Color? ratingColor,
    required double size,
  }) {
    final theme = Theme.of(context);

    final baseColor = isSelected
        ? theme.colorScheme.primary
        : isToday
        ? theme.colorScheme.secondaryContainer
        : theme.colorScheme.surfaceContainerHighest;

    final borderColor = isSelected
        ? theme.colorScheme.primary
        : isToday
        ? theme.colorScheme.secondary
        : theme.colorScheme.outlineVariant;

    final textColor = isSelected
        ? theme.colorScheme.onPrimary
        : isToday
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onSurface;

    final topColor = Color.alphaBlend(
      Colors.white.withValues(alpha: isSelected ? 0.10 : 0.14),
      baseColor,
    );

    final bottomLayerColor = Color.alphaBlend(
      Colors.black.withValues(alpha: isSelected ? 0.22 : 0.16),
      baseColor,
    );

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              Positioned.fill(
                top: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    color: bottomLayerColor,
                    border: Border.all(
                      color: borderColor.withValues(alpha: 0.55),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isSelected ? 0.20 : 0.14,
                        ),
                        blurRadius: isSelected ? 7 : 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [topColor, baseColor],
                  ),
                  border: Border.all(
                    color: borderColor,
                    width: isToday ? 1.4 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isOutside
                          ? textColor.withValues(alpha: 0.55)
                          : textColor,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (ratingColor != null)
                Positioned(
                  right: 3,
                  top: 3,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: ratingColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 0.8,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple legend card explaining day marker colors.
class _LegendCard extends StatelessWidget {
  const _LegendCard({
    required this.excellent,
    required this.medium,
    required this.weak,
    required this.negative,
  });

  final String excellent;
  final String medium;
  final String weak;
  final String negative;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _LegendItem(label: excellent, color: Colors.green),
            _LegendItem(label: medium, color: Colors.orange),
            _LegendItem(label: weak, color: Colors.red),
            _LegendItem(label: negative, color: Colors.red.shade900),
          ],
        ),
      ),
    );
  }
}

/// One legend item with color dot and label.
class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
