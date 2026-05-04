# 📊 Bewertung – Daily Self-Evaluation & Discipline Tracker

> *"What gets measured, gets managed."*

---

## 🚀 Overview

**Bewertung** (German for *evaluation*) is a personal discipline tracker built with Flutter. Each day you rate yourself: what good habits did you follow, and which negative behaviors did you fall into? The app calculates a weighted score so you can see — in hard numbers — how well you lived up to your own standards.

This is **not** a to-do list. You won't find projects, due dates, or team collaboration here. Bewertung is a private mirror: a system for honest self-assessment that rewards consistent good behavior and penalizes avoidable slip-ups.

---

## 🧠 The Idea Behind It

Most productivity apps reward completion. Bewertung rewards *character*.

The core insight is simple: real self-improvement requires tracking two sides of the coin simultaneously — the things you intend to do and the things you intend to *stop* doing. Checking off tasks is easy; confronting your negative patterns honestly is harder, and far more valuable.

Every task and habit carries a **weight** you define yourself. Skipping prayer or exercise might cost you more points than missing a minor habit — because you decide what matters. At the end of each day, the app computes a transparent score:

```
Score = (completed positive tasks × their weights) − (negative habit occurrences × their weights)
Percentage = (score / max possible positive score) × 100
```

Over time, the calendar and statistics screens paint a clear picture of your consistency. Green days become the goal, and the streaks — or the gaps — speak for themselves.

This feedback loop promotes **awareness before judgment**. You are not graded by anyone else. You are graded by your own declared values.

---

## ✨ Features

### Core Tracking
- **Positive tasks** — define habits and behaviors you want to perform (e.g., exercise, reading, prayer)
- **Negative habits** — define forbidden or undesired actions you want to avoid
- **Custom weight per item** — assign importance so not all habits carry equal impact on your score
- **Target count per item** — set how many times a task should be done in a given period
- **Frequency modes** — track items on a **daily**, **weekly**, or **monthly** cycle
- **Active / inactive toggle** — pause items without deleting them

### Daily Evaluation
- Open any past or present day from the calendar to log your counts
- Live score preview updates instantly as you enter data (positive points, negative points, raw score, percentage)
- Save or update any day's evaluation at any time

### Calendar View
- Full interactive calendar showing every rated day with a color-coded dot
  - 🟢 **≥ 80%** — Excellent
  - 🟠 **≥ 50%** — Medium
  - 🔴 **≥ 0%** — Weak
  - 🔴 **< 0%** — Negative (negative habits outweighed the positives)
- Tap any past day to open its detail page

### Statistics
- Selectable date range for trend analysis
- **Daily score chart** — raw score line across the chosen period
- **Per-item count chart** — filter by specific tasks, habits, or categories
- **Category statistics** — aggregate performance grouped by category

### Categories
- Create color-coded categories to organize tasks and habits (e.g., Health, Worship, Learning)
- Filter statistics by category

### Settings & Data
- **Language support** — English and Arabic (with full RTL layout)
- **JSON backup & restore** — export all your data to a file and import it on any device
- Backup includes full rollback on import failure to protect existing data
- Built-in **User Guide** accessible from settings

---

## ⚡ What Makes This Different

| Feature | Generic To-Do App | Bewertung |
|---|---|---|
| Task completion | ✅ | ✅ |
| Negative behavior tracking | ❌ | ✅ |
| Weighted importance | ❌ | ✅ |
| Daily percentage score | ❌ | ✅ |
| Calendar color heatmap | ❌ | ✅ |
| Discipline-focused design | ❌ | ✅ |

The decisive difference is the **negative habit system**. A day where you completed every task but also indulged in several forbidden behaviors is *not* a great day — and Bewertung's score will reflect that. This honest accounting is what separates a self-evaluation tool from a simple checklist.

---

## 🛠️ Tech Stack

| Technology | Role |
|---|---|
| **Flutter / Dart** | Cross-platform UI framework — one codebase for Android, iOS, Windows, Linux, macOS, and Web |
| **Flutter Riverpod** | State management — providers expose reactive streams of tasks, habits, and entries; UI rebuilds only when data changes |
| **Hive + hive_flutter** | Local key-value storage — fast, lightweight, no SQL overhead; all data lives on-device |
| **table_calendar** | Interactive calendar widget with custom day builders for color-coded rating dots |
| **fl_chart** | Line and bar charts in the statistics screen |
| **flutter_localizations + intl** | Full English / Arabic localization including RTL support |
| **file_picker + share_plus** | JSON backup export and cross-platform file sharing |
| **path_provider** | Platform-aware temporary directory for backup files |
| **uuid** | Collision-resistant IDs for all persisted entities |

---

## 📱 Screenshots

> *Screenshots coming soon.*

| Calendar View | Day Evaluation | Statistics |
|---|---|---|
| *(placeholder)* | *(placeholder)* | *(placeholder)* |

---

## 📦 Installation

**Prerequisites:** Flutter SDK ≥ 3.9.2, Dart SDK ≥ 3.9.2

```bash
# 1. Clone the repository
git clone https://github.com/housnizalam/bewertung.git
cd bewertung

# 2. Install dependencies
flutter pub get

# 3. Run on a connected device or emulator
flutter run

# 4. Build a release APK
flutter build apk --release
```

---

## 📥 Download

> *Pre-built binaries will be available in [Releases](../../releases) once the first stable version is tagged.*

---

## 🧩 Project Structure

```
lib/
├── core/               # App-wide constants, theme, and helpers
├── features/
│   ├── calendar/       # Monthly calendar with color-coded score dots
│   ├── categories/     # Category management screen
│   ├── day/            # Day detail page — log counts, preview score
│   ├── manage/         # Create and edit tasks and habits
│   ├── settings/       # Language, backup/restore, user guide
│   └── statistics/     # Trend charts and date-range analysis
├── l10n/               # English and Arabic localization strings
├── models/             # Pure data classes (PositiveTask, NegativeHabit, DayEntry, etc.)
├── navigation/         # Bottom navigation and routing
├── providers/          # Riverpod providers for state and business logic
├── shared/             # Reusable widgets (e.g., Pressable3DButton)
└── storage/            # Hive service and JSON backup/restore logic
```

---

## 🎯 Future Improvements

- **Reminders & notifications** — daily prompt at a chosen time to complete the evaluation
- **Streak tracking** — visualize consecutive days above a score threshold
- **Cloud sync** — optional backup to a personal cloud drive (Google Drive, iCloud)
- **Advanced analytics** — rolling averages, weekly/monthly summaries, trend detection
- **Custom scoring formulas** — allow percentage caps or bonus multipliers per habit
- **Widgets** — home-screen widget showing today's current score
- **Export to CSV / PDF** — for users who want to analyze data in spreadsheets

---

## 👨‍💻 About the Developer

This app was built by **Housni Zalam** as a personal project to solve a real problem: the lack of tools that take *negative behavior* as seriously as positive habits in daily self-evaluation. Rather than another habit tracker that only rewards streaks, Bewertung treats discipline as a two-sided ledger — rewarding good actions and honestly penalizing failures. The result is a cleaner, more honest picture of how you actually live each day.
