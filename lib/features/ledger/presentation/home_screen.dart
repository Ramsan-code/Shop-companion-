import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/widgets/phase_placeholder.dart';

/// Owner/Partner home. Phase 4 puts Who To Ask Today here.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => PhasePlaceholder(
    title: AppLocalizations.of(context).tabHome,
    icon: FluentIcons.home_24_regular,
    phase: 4,
  );
}
