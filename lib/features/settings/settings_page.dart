import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/categories_provider.dart';
import '../../providers/day_entries_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/negative_habits_provider.dart';
import '../../providers/positive_tasks_provider.dart';
import '../../storage/backup_service.dart';
import 'user_guide_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.strings;
    final selectedLocale = ref.watch(localeProvider);
    final selectedLanguageLabel = selectedLocale.languageCode == 'ar'
        ? strings.arabicLanguage
        : strings.englishLanguage;

    return Scaffold(
      appBar: AppBar(title: Text(strings.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text(strings.language),
              subtitle: Text(selectedLanguageLabel),
              onTap: () => _showLanguageDialog(context, ref, selectedLocale),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.download_rounded),
              title: Text(strings.downloadMemory),
              subtitle: Text(strings.downloadMemorySubtitle),
              onTap: () async {
                try {
                  final filePath = await BackupService.exportToJsonFile();
                  await Share.shareXFiles([XFile(filePath)]);

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(strings.backupCreatedSuccessfully)),
                  );
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(strings.backupCreateFailed)),
                  );
                }
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.upload_file_rounded),
              title: Text(strings.uploadMemory),
              subtitle: Text(strings.uploadMemorySubtitle),
              onTap: () async {
                final picked = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['json'],
                );

                final path = picked?.files.single.path;
                if (path == null) return;

                if (!context.mounted) return;
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: Text(strings.confirmImport),
                      content: Text(strings.importReplaceConfirmation),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: Text(strings.cancel),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: Text(strings.continueAction),
                        ),
                      ],
                    );
                  },
                );

                if (confirmed != true) return;

                try {
                  await BackupService.importFromJsonFile(path);

                  await ref.read(categoriesProvider.notifier).loadCategories();
                  await ref.read(positiveTasksProvider.notifier).loadTasks();
                  await ref.read(negativeHabitsProvider.notifier).loadHabits();
                  await ref.read(dayEntriesProvider.notifier).loadEntries();

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(strings.dataImportedSuccessfully)),
                  );
                } on FormatException {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(strings.invalidBackupFile)),
                  );
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(strings.dataImportFailed)),
                  );
                }
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book),
              title: Text(strings.userGuide),
              subtitle: Text(strings.userGuideSubtitle),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const UserGuidePage()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLanguageDialog(
    BuildContext context,
    WidgetRef ref,
    Locale selectedLocale,
  ) async {
    final strings = context.strings;

    final picked = await showDialog<Locale>(
      context: context,
      builder: (dialogContext) {
        final selectedCode = selectedLocale.languageCode;
        return AlertDialog(
          title: Text(strings.language),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.language),
                title: Text(strings.englishLanguage),
                trailing: selectedCode == 'en' ? const Icon(Icons.check) : null,
                onTap: () =>
                    Navigator.of(dialogContext).pop(const Locale('en')),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.language),
                title: Text(strings.arabicLanguage),
                trailing: selectedCode == 'ar' ? const Icon(Icons.check) : null,
                onTap: () =>
                    Navigator.of(dialogContext).pop(const Locale('ar')),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(strings.cancel),
            ),
          ],
        );
      },
    );

    if (picked == null) return;
    await ref.read(localeProvider.notifier).setLocale(picked);
  }
}
