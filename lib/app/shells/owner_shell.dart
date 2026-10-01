import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/voice/presentation/voice_entry_sheet.dart';
import '../l10n/app_localizations.dart';

/// Owner and Partner shell (PRD 9.3): Home, Customers, Mic (raised centre),
/// Stock, More. The mic opens the voice sheet instead of switching tabs.
class OwnerShell extends StatelessWidget {
  const OwnerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const micTab = 2;

  /// Bar position → shell branch. The mic slot has no branch.
  static int? branchForTab(int tab) => switch (tab) {
    0 => 0,
    1 => 1,
    3 => 2,
    4 => 3,
    _ => null,
  };

  static int tabForBranch(int branch) => branch < micTab ? branch : branch + 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: navigationShell,
      // The bar's labels inherit the ambient text style; keep them compact so
      // tall Tamil glyphs fit under the icons.
      bottomNavigationBar: DefaultTextStyle.merge(
        style: const TextStyle(fontSize: 13, height: 1.2),
        child: ConvexAppBar(
          style: TabStyle.fixedCircle,
          height: 64,
          backgroundColor: scheme.surfaceContainer,
          color: scheme.onSurfaceVariant,
          activeColor: scheme.primary,
          initialActiveIndex: tabForBranch(navigationShell.currentIndex),
          items: [
            TabItem(icon: FluentIcons.home_24_regular, title: l10n.tabHome),
            TabItem(
              icon: FluentIcons.people_24_regular,
              title: l10n.tabCustomers,
            ),
            TabItem(icon: FluentIcons.mic_24_filled, title: l10n.tabMic),
            TabItem(icon: FluentIcons.box_24_regular, title: l10n.tabStock),
            TabItem(
              icon: FluentIcons.more_horizontal_24_regular,
              title: l10n.tabMore,
            ),
          ],
          onTabNotify: (tab) {
            if (tab != micTab) return true;
            VoiceEntrySheet.show(context);
            return false;
          },
          onTap: (tab) {
            final branch = branchForTab(tab);
            if (branch == null) return;
            navigationShell.goBranch(
              branch,
              initialLocation: branch == navigationShell.currentIndex,
            );
          },
        ),
      ),
    );
  }
}
