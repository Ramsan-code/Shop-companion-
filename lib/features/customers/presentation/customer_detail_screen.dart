import 'package:clock/clock.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/current_shop.dart';
import '../../../app/failure_message.dart';
import '../../../app/l10n/app_localizations.dart';
import '../../../core/di/providers.dart';
import '../../../core/failure.dart';
import '../../../core/money.dart';
import '../../../core/rbac/permission.dart';
import '../../../sync/sync_badge.dart';
import '../../collections/presentation/trust_card.dart';
import '../../data/domain/data_rights.dart';
import '../../ledger/domain/entry_type.dart';
import '../../ledger/domain/models.dart';
import '../../ledger/presentation/entry_sheet.dart';
import '../../ledger/presentation/labels.dart';
import 'customer_detail_cubit.dart';
import 'customer_form_sheet.dart';
import 'customers_screen.dart';

/// One customer's account: balance, actions and full history with the
/// running balance (PRD C2, C3).
class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => BlocProvider(
    create: (_) => CustomerDetailCubit(
      ref.read(ledgerRepositoryProvider),
      context.membership.shopId,
      customerId,
    ),
    child: const _DetailView(),
  );
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<CustomerDetailCubit, CustomerDetailState>(
      listenWhen: (a, b) => b.failure != null && a.failure != b.failure,
      listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, state.failure!))),
      ),
      builder: (context, state) {
        final customer = state.customer;
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(),
            body: state.loading
                ? const Center(child: CircularProgressIndicator())
                : Center(child: Text(l10n.noResults)),
          );
        }
        final balances = state.runningBalances;
        return Scaffold(
          appBar: AppBar(
            title: Text(customerTitle(l10n, customer)),
            actions: [
              IconButton(
                key: const ValueKey('share-statement'),
                tooltip: l10n.shareStatement,
                icon: const Icon(FluentIcons.share_24_regular),
                onPressed: () => _shareStatement(context, customer),
              ),
              if (customer.phone?.isNotEmpty ?? false)
                IconButton(
                  tooltip: l10n.call,
                  icon: const Icon(FluentIcons.call_24_regular),
                  onPressed: () =>
                      launchUrl(Uri(scheme: 'tel', path: customer.phone)),
                ),
              IconButton(
                tooltip: l10n.editCustomer,
                icon: const Icon(FluentIcons.edit_24_regular),
                onPressed: () =>
                    CustomerFormSheet.show(context, customer: customer),
              ),
              const SyncBadge(),
              // PDPA erasure: Owner only (shop:manage).
              if (context.membership.role.can(Permission.shopManage))
                PopupMenuButton<void>(
                  key: const ValueKey('customer-menu'),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      key: const ValueKey('erase-customer'),
                      onTap: () => _erase(context, customer),
                      child: Text(l10n.eraseCustomer),
                    ),
                  ],
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: BalanceText(customer: customer, large: true),
              ),
              if (customer.optedOut || customer.disputeOpen)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      if (customer.optedOut)
                        Chip(
                          avatar: const Icon(
                            FluentIcons.speaker_mute_24_regular,
                            size: 18,
                          ),
                          label: Text(l10n.optedOutChip),
                        ),
                      if (customer.disputeOpen)
                        Chip(
                          avatar: const Icon(
                            FluentIcons.warning_24_regular,
                            size: 18,
                          ),
                          label: Text(l10n.disputeChip),
                        ),
                    ],
                  ),
                ),
              TrustCard(customer: customer),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => EntrySheet.show(
                          context,
                          customer: customer,
                          type: EntryType.credit,
                        ),
                        icon: const Icon(FluentIcons.add_24_regular),
                        label: Text(l10n.giveCredit),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => EntrySheet.show(
                          context,
                          customer: customer,
                          type: EntryType.payment,
                        ),
                        icon: const Icon(FluentIcons.money_24_regular),
                        label: Text(l10n.recordPayment),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
                child: Text(
                  l10n.history,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (state.entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.noEntries),
                ),
              for (final entry in state.entries)
                _EntryTile(
                  entry: entry,
                  balanceAfter: Money(balances[entry.id] ?? 0),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// "Share statement" (PRD N8, US5): a fresh link through the share sheet,
/// for WhatsApp by hand (Free plan) or SMS.
/// Erase a customer who owes nothing (PDPA). The server refuses otherwise.
Future<void> _erase(BuildContext context, Customer customer) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  final shopId = context.membership.shopId;
  final container = ProviderScope.containerOf(context);
  if (customer.balance.cents != 0) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.eraseNeedsZero)));
    return;
  }
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(l10n.eraseCustomerConfirm(customerTitle(l10n, customer))),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('confirm-erase'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.erase),
        ),
      ],
    ),
  );
  if (ok != true) return;
  final result = await container
      .read(dataRightsRepositoryProvider)
      .eraseCustomer(shopId, customer.id)
      .run();
  result.match(
    (f) => messenger.showSnackBar(
      SnackBar(
        content: Text(
          f is ValidationFailure && f.message == DataRefusal.balanceNotZero
              ? l10n.eraseNeedsZero
              : failureMessage(l10n, f),
        ),
      ),
    ),
    (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.customerErased)));
      router.pop();
    },
  );
}

Future<void> _shareStatement(BuildContext context, Customer customer) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final membership = context.membership;
  final container = ProviderScope.containerOf(context);
  final result = await container
      .read(remindersRepositoryProvider)
      .statementLink(membership.shopId, customer.id)
      .run();
  result.match(
    (f) => messenger.showSnackBar(
      SnackBar(content: Text(failureMessage(l10n, f))),
    ),
    (link) => SharePlus.instance.share(
      ShareParams(
        text: l10n.statementShareText(
          customerTitle(l10n, customer),
          membership.shopName,
          link,
        ),
      ),
    ),
  );
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.balanceAfter});

  final LedgerEntry entry;
  final Money balanceAfter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final increases = entry.type == EntryType.credit;
    final strike = entry.isDeleted
        ? const TextStyle(decoration: TextDecoration.lineThrough)
        : null;
    final subtitle = [
      DateFormat.yMMMd(l10n.localeName).format(entry.txnDate),
      if (entry.method != null) entry.method!.label(l10n),
      if (entry.note?.isNotEmpty ?? false) entry.note!,
      if (entry.isDeleted) l10n.entryDeleted,
    ].join(' · ');
    return ListTile(
      minVerticalPadding: 10,
      onTap: entry.isDeleted
          ? null
          : () => _EditEntrySheet.show(context, entry),
      leading: Icon(
        increases
            ? FluentIcons.arrow_up_24_regular
            : FluentIcons.arrow_down_24_regular,
        color: increases ? theme.colorScheme.error : theme.colorScheme.primary,
      ),
      title: Text(
        '${entry.type.label(l10n)}  ${entry.amount.format()}',
        style: strike,
      ),
      subtitle: Text(subtitle),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            balanceAfter.format(showCents: false),
            style: theme.textTheme.bodySmall,
          ),
          if (entry.isPending)
            Icon(
              FluentIcons.cloud_arrow_up_16_regular,
              size: 16,
              color: theme.colorScheme.tertiary,
              semanticLabel: l10n.pendingSync,
            ),
        ],
      ),
    );
  }
}

/// Fix an amount or note; Owner/Partner can also delete (PRD 6).
class _EditEntrySheet extends StatefulWidget {
  const _EditEntrySheet({required this.entry});

  final LedgerEntry entry;

  static Future<void> show(BuildContext context, LedgerEntry entry) =>
      showModalBottomSheet<void>(
        context: context,
        // Above the shell's bottom bar, not inside the tab.
        useRootNavigator: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => BlocProvider.value(
          value: context.read<CustomerDetailCubit>(),
          child: _EditEntrySheet(entry: entry),
        ),
      );

  @override
  State<_EditEntrySheet> createState() => _EditEntrySheetState();
}

class _EditEntrySheetState extends State<_EditEntrySheet> {
  late final _amount = TextEditingController(
    text: (widget.entry.amountCents / 100).toStringAsFixed(
      widget.entry.amountCents % 100 == 0 ? 0 : 2,
    ),
  );
  late final _note = TextEditingController(text: widget.entry.note);
  String? _amountError;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save({required bool direct}) async {
    final l10n = AppLocalizations.of(context);
    final amount = Money.tryParse(_amount.text);
    if (amount == null || amount.isZero) {
      setState(() => _amountError = l10n.errorAmount);
      return;
    }
    final navigator = Navigator.of(context);
    final ok = await context.read<CustomerDetailCubit>().editEntry(
      widget.entry,
      amountCents: amount.cents,
      note: _note.text.trim(),
      direct: direct,
    );
    if (ok) navigator.pop();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<CustomerDetailCubit>();
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.deleteEntryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && await cubit.deleteEntry(widget.entry)) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final role = context.membership.role;
    final direct = widget.entry.canEditDirectly(context.uid, clock.now());
    final manager = role.can(Permission.ledgerEditAny);
    final canEdit = direct || manager;
    final busy = context.select((CustomerDetailCubit c) => c.state.busy);
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
          Text(l10n.editEntry, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          if (!canEdit)
            Text(l10n.cannotEditEntry)
          else ...[
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.amountLabel,
                errorText: _amountError,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLength: 200,
              decoration: InputDecoration(labelText: l10n.noteLabel),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: busy ? null : () => _save(direct: direct),
              child: Text(l10n.save),
            ),
          ],
          if (manager) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: busy ? null : _delete,
              child: Text(l10n.deleteEntry),
            ),
          ],
        ],
      ),
    );
  }
}
