import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/failure_message.dart';
import '../../../app/l10n/app_localizations.dart';
import '../../../core/failure.dart';
import 'pending_invite_cubit.dart';
import 'session_cubit.dart';

/// Accepts the invite from a `/invite/{token}` link (US9) after login and PIN.
class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  bool _busy = false;
  Failure? _failure;

  Future<void> _join() async {
    final token = context.read<PendingInviteCubit>().state;
    if (token == null) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    final result = await context
        .read<SessionCubit>()
        .repository
        .acceptInvite(token)
        .run();
    if (!mounted) return;
    result.match(
      (failure) => setState(() {
        _busy = false;
        _failure = failure;
      }),
      // The session stream picks up the membership and routes to the shell.
      (_) => context.read<PendingInviteCubit>().clear(),
    );
  }

  String _message(AppLocalizations l10n, Failure failure) => switch (failure) {
    NotFoundFailure() || ExpiredFailure() => l10n.joinInvalid,
    PermissionFailure(message: 'permission-denied') => l10n.joinWrongPhone,
    ConflictFailure() => l10n.joinAlreadyMember,
    _ => failureMessage(l10n, failure),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(l10n.joinTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(l10n.joinBody),
          if (_failure != null) ...[
            const SizedBox(height: 16),
            Text(
              _message(l10n, _failure!),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _join,
            child: Text(l10n.joinButton),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.read<PendingInviteCubit>().clear(),
            child: Text(l10n.startOwnShop),
          ),
        ],
      ),
    );
  }
}
