import 'dart:io';

const List<String> _knownBoxPrefixes = <String>[
  'categoriesBox',
  'positiveTasksBox',
  'negativeHabitsBox',
  'dayEntriesBox',
  'appSettingsBox',
];

final Set<String> _knownBoxPrefixesLower = _knownBoxPrefixes
    .map((name) => name.toLowerCase())
    .toSet();

const List<String> _knownCompanyNames = <String>['com.example'];

void main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  if (!Platform.isWindows) {
    stderr.writeln('This cleanup script is intended for Windows only.');
    exitCode = 64;
    return;
  }

  final requiresConfirmation = !args.contains('--yes');
  final projectRoot = Directory.current.absolute.path;

  final packageName = _readPackageName() ?? 'bewertung';
  final appFolderNames = <String>{
    packageName,
    packageName.toLowerCase(),
    'bewertung',
    'Daily Self Evaluation',
    'daily_self_evaluation',
    'com.example.bewertung',
  };

  final appDataRoots = <String>[
    Platform.environment['APPDATA'] ?? '',
    Platform.environment['LOCALAPPDATA'] ?? '',
    _windowsDocumentsPath(),
  ].where((root) => root.trim().isNotEmpty).toSet().toList();

  if (appDataRoots.isEmpty) {
    stderr.writeln('Unable to read APPDATA/LOCALAPPDATA environment paths.');
    exitCode = 1;
    return;
  }

  final targets = <Directory>[];

  for (final root in appDataRoots) {
    for (final dir in _buildCandidateDirectories(
      root: root,
      appFolderNames: appFolderNames,
    )) {
      if (!dir.existsSync()) {
        continue;
      }

      if (!_isSafeDeletionTarget(
        targetPath: dir.absolute.path,
        projectRootPath: projectRoot,
        allowedRoots: appDataRoots,
      )) {
        continue;
      }

      if (_looksLikeThisAppData(dir)) {
        targets.add(dir);
      }
    }
  }

  if (targets.isEmpty) {
    stdout.writeln('No app-specific Hive data folder was found to delete.');
    stdout.writeln('Checked under:');
    for (final root in appDataRoots) {
      stdout.writeln('  - $root');
    }
    return;
  }

  stdout.writeln('The following local app data folder(s) will be deleted:');
  for (final target in targets) {
    stdout.writeln('  - ${target.absolute.path}');
  }

  if (requiresConfirmation) {
    stdout.writeln('');
    stdout.writeln('Refusing to delete without explicit confirmation.');
    stdout.writeln('Run again with: dart run tool/clear_local_data.dart --yes');
    exitCode = 2;
    return;
  }

  var deletedCount = 0;
  for (final target in targets) {
    try {
      await target.delete(recursive: true);
      deletedCount++;
      stdout.writeln('Deleted: ${target.absolute.path}');
    } catch (error) {
      stderr.writeln('Failed to delete ${target.absolute.path}: $error');
      exitCode = 1;
    }
  }

  if (deletedCount > 0 && exitCode == 0) {
    stdout.writeln('Done. Local development data cleanup completed.');
  }
}

bool _looksLikeThisAppData(Directory dir) {
  try {
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;

      final name = entity.uri.pathSegments.isNotEmpty
          ? entity.uri.pathSegments.last
          : entity.path;

      final lower = name.toLowerCase();
      final hasKnownPrefix = _knownBoxPrefixesLower.any(
        (prefix) => lower.startsWith(prefix),
      );

      if (!hasKnownPrefix) continue;

      if (lower.endsWith('.hive') || lower.endsWith('.lock')) {
        return true;
      }
    }
  } catch (_) {
    return false;
  }

  return false;
}

List<Directory> _buildCandidateDirectories({
  required String root,
  required Set<String> appFolderNames,
}) {
  final candidates = <Directory>[];

  for (final appName in appFolderNames) {
    candidates.add(Directory(_joinWindowsPath(root, appName)));
  }

  for (final company in _knownCompanyNames) {
    for (final appName in appFolderNames) {
      final nested = _joinWindowsPath(_joinWindowsPath(root, company), appName);
      candidates.add(Directory(nested));
    }
  }

  return candidates;
}

bool _isSafeDeletionTarget({
  required String targetPath,
  required String projectRootPath,
  required List<String> allowedRoots,
}) {
  final normalizedTarget = _normalizePath(targetPath);
  final normalizedProjectRoot = _normalizePath(projectRootPath);

  if (normalizedTarget.isEmpty || normalizedTarget.length < 10) {
    return false;
  }

  if (normalizedTarget == normalizedProjectRoot) {
    return false;
  }

  if (normalizedTarget.startsWith('$normalizedProjectRoot/')) {
    return false;
  }

  final isInsideAllowedRoot = allowedRoots.any((root) {
    final normalizedRoot = _normalizePath(root);
    return normalizedTarget == normalizedRoot ||
        normalizedTarget.startsWith('$normalizedRoot/');
  });

  return isInsideAllowedRoot;
}

String _normalizePath(String path) {
  var normalized = path.replaceAll('\\', '/').trim();
  while (normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized.toLowerCase();
}

String _joinWindowsPath(String left, String right) {
  final separator = Platform.pathSeparator;
  if (left.endsWith(separator)) {
    return '$left$right';
  }
  return '$left$separator$right';
}

String? _readPackageName() {
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    return null;
  }

  final lines = pubspec.readAsLinesSync();
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('name:')) {
      final value = trimmed.substring('name:'.length).trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
  }
  return null;
}

void _printUsage() {
  stdout.writeln('Development local-data cleanup for Windows.');
  stdout.writeln('');
  stdout.writeln('Usage:');
  stdout.writeln('  dart run tool/clear_local_data.dart --yes');
  stdout.writeln('');
  stdout.writeln('Safety:');
  stdout.writeln('  - Deletes only detected app-specific Hive data folders.');
  stdout.writeln('  - Never deletes project source files.');
  stdout.writeln('  - Requires --yes to execute deletion.');
}

String _windowsDocumentsPath() {
  final userProfile = Platform.environment['USERPROFILE'] ?? '';
  if (userProfile.isEmpty) return '';
  return _joinWindowsPath(userProfile, 'Documents');
}
