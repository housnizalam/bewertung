# Daily Self Evaluation (MVP)

Beginner-friendly Flutter MVP for daily self-evaluation.

The app helps users:
- define positive tasks and negative habits
- record daily counts
- view calendar ratings
- review simple statistics

This repository intentionally keeps architecture simple and explicit.

## MVP Features

1. Manage categories, positive tasks, and negative habits.
2. Evaluate any day by entering completed/actual counts.
3. Auto-calculate daily score and percentage.
4. Calendar with rating markers by score quality.
5. Statistics page with date range filters and line charts.
6. Arabic default language with English support.
7. Local offline persistence using Hive.

## Tech Stack

- Flutter (Material 3)
- Dart
- Riverpod (state management)
- Hive + hive_flutter (local persistence)
- table_calendar (calendar UI)
- fl_chart (line charts)
- intl (date formatting)
- uuid (id generation)

## Project Structure

```text
lib/
	core/
		app_constants.dart
		app_theme.dart
	l10n/
		app_localizations.dart
		app_ar.dart
		app_en.dart
	models/
		frequency_type.dart
		app_category.dart
		positive_task.dart
		negative_habit.dart
		day_entry.dart
		daily_score.dart
	providers/
		categories_provider.dart
		positive_tasks_provider.dart
		negative_habits_provider.dart
		day_entries_provider.dart
	storage/
		hive_service.dart
	navigation/
		main_navigation.dart
	features/
		manage/
		day/
		calendar/
		statistics/
		categories/
	main.dart
```

## Data Flow (UI -> Provider -> Hive)

The app follows a clear flow:

1. UI page reads and writes through Riverpod providers.
2. Provider validates and prepares data.
3. Provider calls `HiveService` methods.
4. `HiveService` serializes models with `toMap`/`fromMap`.
5. Provider reloads state so UI updates automatically.

Important: UI pages do not call Hive directly.

## Scoring Formula

The score is calculated in `day_entries_provider.dart`.

For each active positive task:

```text
positivePoints += min(completedCount / targetCount, 1.0) * weight
```

For each active negative habit:

```text
negativePoints += actualCount * weight
```

Then:

```text
rawScore = positivePoints - negativePoints
totalPossiblePositivePoints = sum(weights of active positive tasks)
percentage = (rawScore / totalPossiblePositivePoints) * 100
```

Notes:
- Percentage is intentionally not clamped.
- Positive completion ratio is capped per task.

## Localization

This MVP uses a simple manual localization system:

- `app_localizations.dart` defines typed string fields.
- `app_ar.dart` contains Arabic values.
- `app_en.dart` contains English values.

Current status:
- Arabic is default locale.
- English is available.
- No ARB/code generation yet (kept simple for MVP stage).

## How Calendar Uses Saved Data

Calendar markers are derived from day entries:

1. For each day, page asks provider for `getScoreForDate(...)`.
2. If `isRated` is false, no marker is shown.
3. If rated, marker color is based on score threshold.

Tapping a day opens Day Detail page for that exact date.

## How Statistics Uses Saved Data

Statistics page:

1. Builds an inclusive day list from selected start/end dates.
2. Daily score chart uses provider `getScoreForDate(...)`.
3. Selected-item chart reads `positiveLogs` and `negativeLogs` per day.
4. Empty-state guards prevent chart crashes when no data exists.

## Run the App

1. Install Flutter SDK.
2. In project root, run:

```bash
flutter pub get
flutter run
```

## Next Planned Improvements

1. Better chart legends and filtering UX.
2. Export/share report summaries.
3. Calendar month statistics overlays.
4. Optional cloud sync and backup.
5. Replace manual l10n with ARB workflow when project grows.

## MVP Note

This codebase is intentionally MVP-first:
- simple architecture
- explicit logic
- minimal abstraction

The goal is clarity and fast iteration before advanced refactoring.
