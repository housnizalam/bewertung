import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../l10n/app_localizations.dart';

class UserGuidePage extends StatefulWidget {
  const UserGuidePage({super.key});

  @override
  State<UserGuidePage> createState() => _UserGuidePageState();
}

class _UserGuidePageState extends State<UserGuidePage> {
  late Future<String> _guideContent;

  @override
  void initState() {
    super.initState();
    _guideContent = rootBundle.loadString('assets/docs/USER_GUIDE_AR.md');
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Scaffold(
      appBar: AppBar(title: Text(strings.userGuide)),
      body: FutureBuilder<String>(
        future: _guideContent,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          /// Handle error cases: file not found, null data, or empty content
          if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  strings.userGuideNotAvailable,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }

          final markdown = snapshot.data!;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Markdown(
              data: markdown,
              padding: const EdgeInsets.all(16),
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                  .copyWith(
                    p: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7),
                    h1: Theme.of(context).textTheme.headlineSmall?.copyWith(height: 1.5),
                    h2: Theme.of(context).textTheme.titleLarge?.copyWith(height: 1.5),
                    h3: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.5),
                  ),
            ),
          );
        },
      ),
    );
  }
}
