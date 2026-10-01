import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/role_label.dart';
import '../../../core/rbac/role.dart';
import 'session_cubit.dart';

/// Phase 0: phone field against the fake repository, plus a debug-only role
/// picker. Phase 1 adds Firebase phone OTP with SMS auto-read.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = context.read<SessionCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l10n.loginTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.phoneLabel,
              prefixText: '+94 ',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => session.signIn(_phone.text),
            child: Text(l10n.continueButton),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 40),
            Text(
              l10n.devSignInTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(l10n.devSignInBody),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final role in [Role.owner, Role.partner, Role.helper])
                  OutlinedButton(
                    onPressed: () => session.debugSignInAs(role),
                    child: Text(role.label(l10n)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
