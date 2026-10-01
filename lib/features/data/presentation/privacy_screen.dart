import 'package:flutter/material.dart';

import '../../../app/l10n/app_localizations.dart';

/// PDPA privacy notice (PRD 11): plain words, Tamil first.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sections = [
      (l10n.privacyWhatTitle, l10n.privacyWhat),
      (l10n.privacyWhyTitle, l10n.privacyWhy),
      (l10n.privacyWhoTitle, l10n.privacyWho),
      (l10n.privacyKeepTitle, l10n.privacyKeep),
      (l10n.privacyRightsTitle, l10n.privacyRights),
      (l10n.privacyContactTitle, l10n.privacyContact),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          for (final (title, body) in sections) ...[
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(body, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
