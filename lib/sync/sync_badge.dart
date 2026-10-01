import 'package:clock/clock.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../app/l10n/app_localizations.dart';
import 'sync_state.dart';

/// App-bar badge: offline, N waiting to sync, or a stale warning (PRD C8).
class SyncBadge extends StatelessWidget {
  const SyncBadge({super.key});

  @override
  Widget build(BuildContext context) => StoreConnector<SyncState, SyncState>(
    converter: (store) => store.state,
    distinct: true,
    builder: (context, state) {
      final l10n = AppLocalizations.of(context);
      final scheme = Theme.of(context).colorScheme;
      final stale = isStale(state, clock.now());
      final (IconData icon, String label, Color color) = switch (state) {
        _ when stale => (
          FluentIcons.warning_24_filled,
          l10n.syncStale(state.waiting),
          scheme.error,
        ),
        SyncState(waiting: > 0) => (
          FluentIcons.cloud_arrow_up_24_regular,
          l10n.syncPending(state.waiting),
          scheme.tertiary,
        ),
        SyncState(online: false) => (
          FluentIcons.cloud_off_24_regular,
          l10n.syncOffline,
          scheme.onSurfaceVariant,
        ),
        _ => (
          FluentIcons.cloud_checkmark_24_regular,
          l10n.syncDone,
          scheme.primary,
        ),
      };
      // Icon and count only: the full sentence (often long in Tamil) is in
      // the tooltip and the screen-reader label, not in the app bar.
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Tooltip(
          message: label,
          child: Semantics(
            label: label,
            excludeSemantics: true,
            child: state.waiting == 0
                ? Icon(icon, color: color)
                : Chip(
                    avatar: Icon(icon, color: color, size: 18),
                    label: Text('${state.waiting}'),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: color),
                  ),
          ),
        ),
      );
    },
  );
}
