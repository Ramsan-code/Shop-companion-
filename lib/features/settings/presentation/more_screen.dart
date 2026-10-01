import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/locale_cubit.dart';
import '../../../app/role_label.dart';
import '../../../app/router.dart';
import '../../../app/simple_mode_cubit.dart';
import '../../../core/di/providers.dart';
import '../../../core/rbac/permission.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/session_cubit.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.read(telemetryProvider);
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
          if (membership?.role.can(Permission.reminderSend) ?? false)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(FluentIcons.chat_24_regular),
              title: Text(l10n.remindersTitle),
              trailing: const Icon(FluentIcons.chevron_right_24_regular),
              onTap: () => context.go(Routes.reminders),
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
          ListTile(
            key: const ValueKey('more-data'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(FluentIcons.shield_lock_24_regular),
            title: Text(l10n.dataTitle),
            trailing: const Icon(FluentIcons.chevron_right_24_regular),
            onTap: () => context.go(Routes.data),
          ),
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
          const SizedBox(height: 16),
          SwitchListTile(
            key: const ValueKey('simple-mode'),
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(FluentIcons.grid_24_regular),
            title: Text(l10n.simpleMode),
            subtitle: Text(l10n.simpleModeHelp),
            value: context.watch<SimpleModeCubit>().state,
            onChanged: (on) {
              context.read<SimpleModeCubit>().set(on);
              telemetry.simpleModeChanged(on);
            },
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
