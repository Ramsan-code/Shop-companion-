import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/l10n/app_localizations.dart';
import 'app_lock_cubit.dart';
import 'widgets/pin_pad.dart';

/// "Set PIN" step of first-time setup (PRD 7.1-1): enter twice to confirm.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String? _first;
  bool _mismatch = false;

  Future<void> _entered(String pin) async {
    if (_first == null) {
      setState(() {
        _first = pin;
        _mismatch = false;
      });
    } else if (_first == pin) {
      await context.read<AppLockCubit>().setPin(pin);
    } else {
      setState(() {
        _first = null;
        _mismatch = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  _first == null ? l10n.pinSetupTitle : l10n.pinConfirmTitle,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _mismatch ? l10n.pinMismatch : l10n.pinSetupBody,
                  textAlign: TextAlign.center,
                  style: _mismatch
                      ? TextStyle(color: theme.colorScheme.error)
                      : null,
                ),
                const SizedBox(height: 24),
                PinPad(
                  key: ValueKey(_first == null ? 'first' : 'confirm'),
                  onCompleted: _entered,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
