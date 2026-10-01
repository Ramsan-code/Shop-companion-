import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/widgets/phase_placeholder.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context) => PhasePlaceholder(
    title: AppLocalizations.of(context).tabStock,
    icon: FluentIcons.box_24_regular,
    phase: 6,
  );
}
