import 'package:clock/clock.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/current_shop.dart';
import '../../../app/l10n/app_localizations.dart';
import '../../../app/router.dart';
import '../../../app/simple_mode_cubit.dart';
import '../../../core/di/providers.dart';
import '../../../core/money.dart';
import '../../../core/rbac/permission.dart';
import '../../../sync/sync_badge.dart';
import '../../collections/domain/collections.dart';
import '../../collections/presentation/trust_labels.dart';
import '../../collections/presentation/who_to_ask_cubit.dart';
import '../../customers/presentation/customers_screen.dart';
import '../domain/entry_type.dart';
import 'entry_sheet.dart';
import 'labels.dart';
import 'quick_entry_sheet.dart';
import 'simple_home.dart';

/// Owner/Partner home: Who To Ask Today (PRD D5, US2). One tap to call,
/// WhatsApp, record a payment, or ask later.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => BlocProvider(
    create: (_) => WhoToAskCubit(
      collections: ref.read(collectionsRepositoryProvider),
      ledger: ref.read(ledgerRepositoryProvider),
      shopId: context.membership.shopId,
    ),
    child: const _WhoToAskView(),
  );
}

class _WhoToAskView extends StatelessWidget {
  const _WhoToAskView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.whoToAskTitle),
        actions: const [SyncBadge()],
      ),
      body: BlocBuilder<WhoToAskCubit, WhoToAskState>(
        builder: (context, state) {
          final simple = context.watch<SimpleModeCubit>().state;
          final actions = simple ? const SimpleHome() : const _QuickActions();
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.rows.isEmpty) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              children: [
                actions,
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.whoToAskEmpty, textAlign: TextAlign.center),
                ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            children: [
              actions,
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  l10n.whoToAskSummary(
                    state.stillToAsk,
                    Money(state.totalDueCents).format(showCents: false),
                  ),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (state.fallback)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Text(l10n.whoToAskFallback),
                ),
              for (final row in state.rows) _WhoToAskCard(row: row),
            ],
          );
        },
      ),
    );
  }
}

/// Sale, money spent and Close Day, one tap from home (PRD C4, C5).
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canSpend = context.membership.role.can(
      Permission.ledgerCreateExpense,
    );
    Widget action(IconData icon, String label, VoidCallback onTap, Key key) =>
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilledButton.tonal(
              key: key,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(64),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              onPressed: onTap,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon),
                  const SizedBox(height: 2),
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        children: [
          action(
            FluentIcons.cart_24_regular,
            l10n.typeSale,
            () => QuickEntrySheet.show(context, sale: true),
            const ValueKey('quick-sale'),
          ),
          if (canSpend)
            action(
              FluentIcons.wallet_24_regular,
              l10n.typeExpense,
              () => QuickEntrySheet.show(context, sale: false),
              const ValueKey('quick-expense'),
            ),
          action(
            FluentIcons.calendar_checkmark_24_regular,
            l10n.tabCloseDay,
            () => context.go(Routes.ownerCloseDay),
            const ValueKey('quick-close-day'),
          ),
        ],
      ),
    );
  }
}

class _WhoToAskCard extends StatelessWidget {
  const _WhoToAskCard({required this.row});

  final WhoToAskRow row;

  Future<void> _call(BuildContext context, String phone) async {
    context.read<WhoToAskCubit>().contacted(
      row.customer.id,
      CollectAction.call,
    );
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _whatsApp(BuildContext context, String phone) async {
    final l10n = AppLocalizations.of(context);
    final text = l10n.whatsAppNudge(
      customerTitle(l10n, row.customer),
      context.membership.shopName,
      row.customer.balance.format(showCents: false),
    );
    context.read<WhoToAskCubit>().contacted(
      row.customer.id,
      CollectAction.whatsapp,
    );
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    await launchUrl(
      Uri.https('wa.me', '/$digits', {'text': text}),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _snooze(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<WhoToAskCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final now = clock.now();
    final payDay = row.customer.payDay;
    final until = await showModalBottomSheet<DateTime>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(FluentIcons.calendar_clock_24_regular),
              title: Text(l10n.snooze3Days),
              onTap: () =>
                  Navigator.pop(context, now.add(const Duration(days: 3))),
            ),
            if (payDay != null)
              ListTile(
                leading: const Icon(FluentIcons.money_24_regular),
                title: Text(l10n.snoozePayDay(payDay)),
                onTap: () => Navigator.pop(context, nextPayDay(payDay, now)),
              ),
          ],
        ),
      ),
    );
    if (until == null) return;
    cubit.snooze(row.customer.id, until);
    messenger.showSnackBar(SnackBar(content: Text(l10n.snoozed)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final phone = row.customer.phone;
    final hasPhone = phone != null && phone.isNotEmpty;
    final paid = row.paidSinceMorning;
    return Card(
      child: Opacity(
        opacity: paid ? 0.6 : 1,
        child: Column(
          children: [
            ListTile(
              minVerticalPadding: 12,
              onTap: () => context.go('${Routes.customers}/${row.customer.id}'),
              title: Text(customerTitle(l10n, row.customer)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (paid)
                    Text(l10n.whoToAskPaid)
                  else if (row.reason != null)
                    Text(reasonText(l10n, row.reason!)),
                  if (row.band != null) ...[
                    const SizedBox(height: 4),
                    TrustBandChip(band: row.band!),
                  ],
                ],
              ),
              trailing: BalanceText(customer: row.customer),
            ),
            if (!paid)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Wrap(
                  spacing: 4,
                  alignment: WrapAlignment.end,
                  children: [
                    if (hasPhone)
                      TextButton.icon(
                        onPressed: () => _call(context, phone),
                        icon: const Icon(FluentIcons.call_24_regular),
                        label: Text(l10n.call),
                      ),
                    if (hasPhone)
                      TextButton.icon(
                        onPressed: () => _whatsApp(context, phone),
                        icon: const Icon(FluentIcons.chat_24_regular),
                        label: Text(l10n.whatsApp),
                      ),
                    TextButton.icon(
                      onPressed: () => EntrySheet.show(
                        context,
                        customer: row.customer,
                        type: EntryType.payment,
                      ),
                      icon: const Icon(FluentIcons.money_24_regular),
                      label: Text(l10n.recordPayment),
                    ),
                    TextButton.icon(
                      onPressed: () => _snooze(context),
                      icon: const Icon(FluentIcons.clock_24_regular),
                      label: Text(l10n.snooze),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
