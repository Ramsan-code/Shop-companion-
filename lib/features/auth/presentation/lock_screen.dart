import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/l10n/app_localizations.dart';
import 'app_lock_cubit.dart';
import 'session_cubit.dart';
import 'widgets/pin_pad.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  @override
  void initState() {
    super.initState();
    // Offer the fingerprint straight away when the phone has one.
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    if (!mounted) return;
    final reason = AppLocalizations.of(context).fingerprintReason;
    await context.read<AppLockCubit>().unlockWithBiometric(reason);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lock = context.watch<AppLockCubit>();
    final state = lock.state;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(l10n.lockTitle, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                if (state.failedAttempts > 0)
                  Text(
                    l10n.pinWrong(state.attemptsLeft),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                const SizedBox(height: 24),
                PinPad(onCompleted: lock.unlockWithPin),
                if (state.biometricAvailable)
                  TextButton.icon(
                    onPressed: _tryBiometric,
                    icon: const Icon(FluentIcons.fingerprint_24_regular),
                    label: Text(l10n.useFingerprint),
                  ),
                TextButton(
                  onPressed: () => context.read<SessionCubit>().signOut(),
                  child: Text(l10n.forgotPin, textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
