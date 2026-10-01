import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/widgets/phase_placeholder.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) => PhasePlaceholder(
    title: AppLocalizations.of(context).tabCustomers,
    icon: FluentIcons.people_24_regular,
    phase: 2,
  );
}
