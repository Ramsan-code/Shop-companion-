import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../voice/presentation/voice_entry_sheet.dart';

/// Helper home: quick credit/payment/sale entry (built in Phases 2–3).
class EntryScreen extends StatelessWidget {
  const EntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabEntry)),
      body: Center(
        child: FilledButton.icon(
          onPressed: () => VoiceEntrySheet.show(context),
          icon: const Icon(FluentIcons.mic_24_filled),
          label: Text(l10n.micTitle),
        ),
      ),
    );
  }
}
