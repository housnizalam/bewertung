import 'package:flutter/widgets.dart';

/// Simple localization setup for this MVP.
///
/// This project currently uses handwritten Dart string files (`app_ar.dart`
/// and `app_en.dart`) instead of ARB/code generation to keep onboarding easy.
part 'app_ar.dart';
part 'app_en.dart';

/// Strongly typed localization container used by the UI.
///
/// Add new UI text by adding a field here and values in both language files.
class AppStrings {
  final String appName;
  final String calendar;
  final String manage;
  final String statistics;
  final String categories;

  final String calendarDescription;
  final String manageDescription;
  final String statisticsDescription;
  final String categoriesDescription;

  final String tasks;
  final String forbidden;
  final String addTask;
  final String addForbidden;
  final String edit;
  final String delete;
  final String name;
  final String category;
  final String weight;
  final String targetCount;
  final String frequency;
  final String daily;
  final String weekly;
  final String monthly;
  final String save;
  final String cancel;
  final String active;
  final String inactive;
  final String confirmDelete;
  final String noTasksYet;
  final String noForbiddenYet;
  final String validationError;
  final String missingCategories;
  final String unknownCategory;
  final String dayEvaluation;
  final String saveEvaluation;
  final String savedSuccessfully;
  final String completedCount;
  final String weeklyTaskProgressTemplate;
  final String monthlyTaskProgressTemplate;
  final String actualCount;
  final String positivePoints;
  final String negativePoints;
  final String rawScore;
  final String percentage;
  final String noEvaluationForDay;
  final String evaluateThisDay;
  final String selectedDayEvaluation;
  final String score;
  final String excellent;
  final String medium;
  final String weak;
  final String negative;
  final String fromDate;
  final String toDate;
  final String selectTasksAndForbidden;
  final String dailyScores;
  final String selectedItems;
  final String categoryStatistics;
  final String selectCategories;
  final String noCategorySelected;
  final String noCategoryData;
  final String noData;
  final String chooseValidDate;
  final String noActiveItems;
  final String noCategoriesYet;
  final String noCategoriesWithTasksAvailable;
  final String noItemsInCategory;
  final String addCategory;
  final String categoryName;
  final String categoryNameExists;
  final String settings;
  final String language;
  final String englishLanguage;
  final String arabicLanguage;
  final String userGuide;
  final String userGuideSubtitle;
  final String userGuideNotAvailable;
  final String downloadMemory;
  final String downloadMemorySubtitle;
  final String uploadMemory;
  final String uploadMemorySubtitle;
  final String backupCreatedSuccessfully;
  final String backupCreateFailed;
  final String dataImportedSuccessfully;
  final String dataImportFailed;
  final String invalidBackupFile;
  final String confirmImport;
  final String importReplaceConfirmation;
  final String continueAction;
  final String developerTools;
  final String clearLocalData;
  final String clearLocalDataDescription;
  final String clearLocalDataConfirmation;
  final String clearNow;
  final String localDataClearedRestartHint;

  const AppStrings({
    required this.appName,
    required this.calendar,
    required this.manage,
    required this.statistics,
    required this.categories,
    required this.calendarDescription,
    required this.manageDescription,
    required this.statisticsDescription,
    required this.categoriesDescription,
    required this.tasks,
    required this.forbidden,
    required this.addTask,
    required this.addForbidden,
    required this.edit,
    required this.delete,
    required this.name,
    required this.category,
    required this.weight,
    required this.targetCount,
    required this.frequency,
    required this.daily,
    required this.weekly,
    required this.monthly,
    required this.save,
    required this.cancel,
    required this.active,
    required this.inactive,
    required this.confirmDelete,
    required this.noTasksYet,
    required this.noForbiddenYet,
    required this.validationError,
    required this.missingCategories,
    required this.unknownCategory,
    required this.dayEvaluation,
    required this.saveEvaluation,
    required this.savedSuccessfully,
    required this.completedCount,
    required this.weeklyTaskProgressTemplate,
    required this.monthlyTaskProgressTemplate,
    required this.actualCount,
    required this.positivePoints,
    required this.negativePoints,
    required this.rawScore,
    required this.percentage,
    required this.noEvaluationForDay,
    required this.evaluateThisDay,
    required this.selectedDayEvaluation,
    required this.score,
    required this.excellent,
    required this.medium,
    required this.weak,
    required this.negative,
    required this.fromDate,
    required this.toDate,
    required this.selectTasksAndForbidden,
    required this.dailyScores,
    required this.selectedItems,
    required this.categoryStatistics,
    required this.selectCategories,
    required this.noCategorySelected,
    required this.noCategoryData,
    required this.noData,
    required this.chooseValidDate,
    required this.noActiveItems,
    required this.noCategoriesYet,
    required this.noCategoriesWithTasksAvailable,
    required this.noItemsInCategory,
    required this.addCategory,
    required this.categoryName,
    required this.categoryNameExists,
    required this.settings,
    required this.language,
    required this.englishLanguage,
    required this.arabicLanguage,
    required this.userGuide,
    required this.userGuideSubtitle,
    required this.userGuideNotAvailable,
    required this.downloadMemory,
    required this.downloadMemorySubtitle,
    required this.uploadMemory,
    required this.uploadMemorySubtitle,
    required this.backupCreatedSuccessfully,
    required this.backupCreateFailed,
    required this.dataImportedSuccessfully,
    required this.dataImportFailed,
    required this.invalidBackupFile,
    required this.confirmImport,
    required this.importReplaceConfirmation,
    required this.continueAction,
    required this.developerTools,
    required this.clearLocalData,
    required this.clearLocalDataDescription,
    required this.clearLocalDataConfirmation,
    required this.clearNow,
    required this.localDataClearedRestartHint,
  });

  static const AppStrings ar = _appStringsAr;
  static const AppStrings en = _appStringsEn;
}

/// Provides localized [AppStrings] for the active locale.
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );

    assert(localizations != null, 'AppLocalizations not found in context.');
    return localizations!;
  }

  /// Returns Arabic or English strings based on active language code.
  ///
  /// Arabic is the app default locale in `main.dart`.
  AppStrings get strings {
    switch (locale.languageCode) {
      case 'en':
        return AppStrings.en;
      case 'ar':
      default:
        return AppStrings.ar;
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'ar' || locale.languageCode == 'en';

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}

/// Convenience extension: `context.strings`.
extension AppLocalizationContext on BuildContext {
  AppStrings get strings => AppLocalizations.of(this).strings;
}
