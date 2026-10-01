import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/locale_cubit.dart';
import '../../../app/role_label.dart';
import '../../../app/router.dart';
import '../../../core/rbac/permission.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/session_cubit.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final session = context.watch<SessionCubit>().state;
    final locale = context.watch<LocaleCubit>().state;
    final membership = session is SignedIn ? session.membership : null;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabMore)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (membership != null)
            Text(
              l10n.signedInAs(membership.shopName, membership.role.label(l10n)),
              style: theme.textTheme.titleMedium,
            ),
          if (membership?.role.can(Permission.memberInvite) ?? false) ...[
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(FluentIcons.people_team_24_regular),
              title: Text(l10n.membersTitle),
              trailing: const Icon(FluentIcons.chevron_right_24_regular),
              onTap: () => context.go(Routes.members),
            ),
          ],
          const SizedBox(height: 24),
          Text(l10n.language, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ToggleSwitch(
            minHeight: 48,
            minWidth: 120,
            totalSwitches: 2,
            labels: const ['தமிழ்', 'English'],
            initialLabelIndex: locale == LocaleCubit.tamil ? 0 : 1,
            activeBgColor: [theme.colorScheme.primary],
            activeFgColor: theme.colorScheme.onPrimary,
            inactiveBgColor: theme.colorScheme.surfaceContainerHighest,
            inactiveFgColor: theme.colorScheme.onSurface,
            onToggle: (index) => context.read<LocaleCubit>().select(
              index == 1 ? LocaleCubit.english : LocaleCubit.tamil,
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () => context.read<SessionCubit>().signOut(),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }
}
