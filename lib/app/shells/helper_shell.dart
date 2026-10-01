import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';

/// Helper shell (PRD 9.3): three labelled tabs, no profit, no settings.
class HelperShell extends StatelessWidget {
  const HelperShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    BottomNavyBarItem item(IconData icon, String title) => BottomNavyBarItem(
      icon: Icon(icon),
      title: Text(title),
      activeColor: scheme.primary,
      inactiveColor: scheme.onSurfaceVariant,
    );
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavyBar(
        selectedIndex: navigationShell.currentIndex,
        showInactiveTitle: true,
        containerHeight: 64,
        backgroundColor: scheme.surfaceContainer,
        onItemSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: [
          item(FluentIcons.receipt_add_24_regular, l10n.tabEntry),
          item(FluentIcons.people_24_regular, l10n.tabCustomers),
          item(FluentIcons.calendar_checkmark_24_regular, l10n.tabCloseDay),
        ],
      ),
    );
  }
}
