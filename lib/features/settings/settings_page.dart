import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/categories_provider.dart';
import '../../providers/day_entries_provider.dart';
import '../../providers/negative_habits_provider.dart';
import '../../providers/positive_tasks_provider.dart';
import '../../storage/backup_service.dart';
import 'user_guide_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.strings;

    return Scaffold(
      appBar: AppBar(title: Text(strings.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
}
