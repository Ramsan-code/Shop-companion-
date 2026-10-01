import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/current_shop.dart';
import '../../../app/l10n/app_localizations.dart';
import '../../../core/di/providers.dart';
import '../../../sync/sync_badge.dart';
import '../../customers/presentation/customers_bloc.dart';
import '../../customers/presentation/customers_screen.dart';
import '../../voice/presentation/voice_entry_sheet.dart';
import '../domain/entry_type.dart';
import 'entry_sheet.dart';

/// Helper home: quick credit or payment (PRD 9.3 helper shell). Pick the
/// type, then the customer.
class EntryScreen extends StatelessWidget {
  const EntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget big(IconData icon, String label, EntryType type) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(72)),
        onPressed: () => _CustomerPicker.show(context, type),
        icon: Icon(icon, size: 28),
        label: Text(label, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabEntry), actions: const [SyncBadge()]),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          big(FluentIcons.add_24_regular, l10n.giveCredit, EntryType.credit),
          big(
            FluentIcons.money_24_regular,
            l10n.recordPayment,
            EntryType.payment,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: () => VoiceEntrySheet.show(context),
            icon: const Icon(FluentIcons.mic_24_filled),
            label: Text(l10n.micTitle),
          ),
        ],
      ),
    );
  }
}

class _CustomerPicker extends ConsumerWidget {
  const _CustomerPicker({required this.type});

  final EntryType type;

  static Future<void> show(BuildContext context, EntryType type) =>
      showModalBottomSheet<void>(
        context: context,
        // Above the shell's bottom bar, not inside the tab.
        useRootNavigator: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _CustomerPicker(type: type),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => CustomersBloc(
        ref.read(ledgerRepositoryProvider),
        context.membership.shopId,
      )..add(const CustomersStarted()),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          children: [
            Text(
              l10n.chooseCustomer,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Builder(
              builder: (context) => Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(FluentIcons.search_24_regular),
                    hintText: l10n.customersSearch,
                  ),
                  onChanged: (q) => context.read<CustomersBloc>().add(
                    CustomersSearchChanged(q),
                  ),
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<CustomersBloc, CustomersState>(
                builder: (context, state) => ListView(
                  children: [
                    for (final c in state.visible)
                      CustomerRow(
                        customer: c,
                        onTap: () {
                          final navigator = Navigator.of(context);
                          final parent = navigator.context;
                          navigator.pop();
                          EntrySheet.show(parent, customer: c, type: type);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
