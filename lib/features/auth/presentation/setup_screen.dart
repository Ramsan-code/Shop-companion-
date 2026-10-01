import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/failure_message.dart';
import '../../../app/l10n/app_localizations.dart';
import '../../../core/failure.dart';
import 'session_cubit.dart';

/// "Say shop name" step of first-time setup (PRD 7.1-1). Calls the
/// `createShop` function; the session stream then routes to the shell.
/// Voice input for the name arrives with the mic in Phase 3.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _name = TextEditingController();
  bool _busy = false;
  Failure? _failure;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_name.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    final result = await context.read<SessionCubit>().createShop(_name.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failure = result.getLeft().toNullable();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l10n.setupTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            maxLength: 80,
            decoration: InputDecoration(
              labelText: l10n.shopNameLabel,
              errorText: _failure == null
                  ? null
                  : failureMessage(l10n, _failure!),
            ),
            onSubmitted: (_) => _create(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _create,
            child: Text(l10n.createShopButton),
          ),
        ],
      ),
    );
  }
}
