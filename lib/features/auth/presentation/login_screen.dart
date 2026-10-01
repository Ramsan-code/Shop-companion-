import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/failure_message.dart';
import '../../../app/l10n/app_localizations.dart';
import '../../../app/role_label.dart';
import '../../../core/rbac/role.dart';
import 'phone_auth_cubit.dart';
import 'session_cubit.dart';

/// Phone OTP login (PRD C10, flow 7.1-1). Android reads the SMS itself when
/// it can; the code field is the fallback.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        PhoneAuthCubit(context.read<SessionCubit>().repository),
    child: const _LoginView(),
  );
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _phone = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cubit = context.read<PhoneAuthCubit>();
    final session = context.read<SessionCubit>();
    return BlocBuilder<PhoneAuthCubit, PhoneAuthState>(
      builder: (context, state) {
        final error = state.failure == null
            ? null
            : failureMessage(l10n, state.failure!);
        return Scaffold(
          appBar: AppBar(title: Text(l10n.appTitle)),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: switch (state) {
              EnterCode() => [
                Text(
                  l10n.otpTitle(state.phone),
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(l10n.otpAutoRead),
                const SizedBox(height: 16),
                TextField(
                  key: const ValueKey('otp-field'),
                  controller: _code,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: l10n.otpLabel,
                    errorText: error,
                  ),
                  onSubmitted: cubit.confirm,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: state.verifying
                      ? null
                      : () => cubit.confirm(_code.text.trim()),
                  child: Text(l10n.verifyButton),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: cubit.resend,
                  child: Text(l10n.resendCode),
                ),
                TextButton(
                  onPressed: cubit.changeNumber,
                  child: Text(l10n.changeNumber),
                ),
              ],
              _ => [
                Text(l10n.loginTitle, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 16),
                TextField(
                  key: const ValueKey('phone-field'),
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: InputDecoration(
                    labelText: l10n.phoneLabel,
                    hintText: '077 123 4567',
                    errorText: error,
                  ),
                  onSubmitted: cubit.sendCode,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: state is SendingCode
                      ? null
                      : () => cubit.sendCode(_phone.text),
                  child: state is SendingCode
                      ? const SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : Text(l10n.continueButton),
                ),
                if (session.canDebugSignIn) ...[
                  const SizedBox(height: 40),
                  Text(l10n.devSignInTitle, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(l10n.devSignInBody),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final role in [
                        Role.owner,
                        Role.partner,
                        Role.helper,
                      ])
                        OutlinedButton(
                          onPressed: () => session.debugSignInAs(role),
                          child: Text(role.label(l10n)),
                        ),
                    ],
                  ),
                ],
              ],
            },
          ),
        );
      },
    );
  }
}
