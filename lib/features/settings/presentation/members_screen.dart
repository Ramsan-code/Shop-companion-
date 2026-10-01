import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../../../app/failure_message.dart';
import '../../../app/l10n/app_localizations.dart';
import '../../../app/role_label.dart';
import '../../../core/di/providers.dart';
import '../../../core/rbac/role.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/session_cubit.dart';
import 'members_cubit.dart';

/// Owner-only: who works in the shop, invite a Partner or Helper, remove
/// someone (PRD 6: "Invite or remove members", US9).
class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = context.read<SessionCubit>().state;
    final membership = session is SignedIn ? session.membership : null;
    if (membership == null) return const SizedBox.shrink();
    return BlocProvider(
      create: (_) =>
          MembersCubit(ref.read(membersRepositoryProvider), membership.shopId),
      child: _MembersView(membership: membership),
    );
  }
}

class _MembersView extends StatelessWidget {
  const _MembersView({required this.membership});

  final Membership membership;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<MembersCubit, MembersState>(
      listenWhen: (a, b) => b.failure != null && a.failure != b.failure,
      listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, state.failure!))),
      ),
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(l10n.membersTitle)),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: state.busy ? null : () => _showInvite(context),
          icon: const Icon(FluentIcons.person_add_24_regular),
          label: Text(l10n.inviteMember),
        ),
        body: state.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  for (final member in state.members)
                    ListTile(
                      minVerticalPadding: 12,
                      leading: const Icon(FluentIcons.person_24_regular),
                      title: Text(member.phone),
                      subtitle: Text(member.role.label(l10n)),
                      trailing: member.role == Role.owner
                          ? null
                          : TextButton(
                              onPressed: state.busy
                                  ? null
                                  : () => _confirmRemove(
                                      context,
                                      member.uid,
                                      member.phone,
                                    ),
                              child: Text(l10n.removeMember),
                            ),
                    ),
                  if (state.members.length <= 1)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(l10n.membersEmpty),
                    ),
                ],
              ),
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    String uid,
    String phone,
  ) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<MembersCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.removeConfirm(phone)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.removeMember),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.remove(uid);
  }

  Future<void> _showInvite(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    // Above the shell's bottom bar, not inside the tab.
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: context.read<MembersCubit>(),
      child: _InviteSheet(shopName: membership.shopName),
    ),
  );
}

class _InviteSheet extends StatefulWidget {
  const _InviteSheet({required this.shopName});

  final String shopName;

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  final _phone = TextEditingController();
  Role _role = Role.partner;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final phone = _phone.text.trim();
    final invite = await context.read<MembersCubit>().invite(phone, _role);
    if (invite == null || !mounted) return;
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(l10n.inviteCreated)));
    // The owner sends it by SMS or WhatsApp from the share sheet; automatic
    // SMS arrives with the SMS gateway adapter in Phase 5.
    await SharePlus.instance.share(
      ShareParams(
        text: l10n.inviteShareText(
          widget.shopName,
          _role.label(l10n),
          phone,
          invite.link,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final busy = context.select((MembersCubit c) => c.state.busy);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.inviteTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _phone,
            autofocus: true,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.phoneLabel,
              hintText: '077 123 4567',
            ),
          ),
          const SizedBox(height: 16),
          ToggleSwitch(
            minHeight: 48,
            minWidth: 140,
            totalSwitches: 2,
            labels: [Role.partner.label(l10n), Role.helper.label(l10n)],
            initialLabelIndex: _role == Role.partner ? 0 : 1,
            activeBgColor: [theme.colorScheme.primary],
            activeFgColor: theme.colorScheme.onPrimary,
            inactiveBgColor: theme.colorScheme.surfaceContainerHighest,
            inactiveFgColor: theme.colorScheme.onSurface,
            onToggle: (i) =>
                setState(() => _role = i == 1 ? Role.helper : Role.partner),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: busy ? null : _invite,
            child: Text(l10n.inviteSend),
          ),
        ],
      ),
    );
  }
}
