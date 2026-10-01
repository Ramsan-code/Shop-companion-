import 'package:auto_size_text/auto_size_text.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/current_shop.dart';
import '../../../app/l10n/app_localizations.dart';
import '../../../app/theme.dart';
import '../../../core/di/providers.dart';
import '../../../sync/sync_badge.dart';
import '../../ledger/domain/entry_type.dart';
import '../../ledger/domain/models.dart';
import '../../ledger/presentation/entry_sheet.dart';
import '../../ledger/presentation/labels.dart';
import 'customer_form_sheet.dart';
import 'customers_bloc.dart';

/// Customer list: highest dues first, search, swipe for payment or call
/// (PRD C2). Used by both shells; [basePath] is this shell's customers route.
class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key, required this.basePath});

  final String basePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) => BlocProvider(
    create: (_) => CustomersBloc(
      ref.read(ledgerRepositoryProvider),
      context.membership.shopId,
    )..add(const CustomersStarted()),
    child: _CustomersView(basePath: basePath),
  );
}

class _CustomersView extends StatelessWidget {
  const _CustomersView({required this.basePath});

  final String basePath;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabCustomers),
        actions: const [SyncBadge()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CustomerFormSheet.show(context),
        icon: const Icon(FluentIcons.person_add_24_regular),
        label: Text(l10n.addCustomer),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(FluentIcons.search_24_regular),
                hintText: l10n.customersSearch,
              ),
              onChanged: (q) =>
                  context.read<CustomersBloc>().add(CustomersSearchChanged(q)),
            ),
          ),
          Expanded(
            child: BlocBuilder<CustomersBloc, CustomersState>(
              builder: (context, state) {
                if (state.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final visible = state.visible;
                if (visible.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        state.all.isEmpty ? l10n.noCustomers : l10n.noResults,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                // Lazy list: smooth with 500+ customers (PRD 11).
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: visible.length,
                  itemBuilder: (context, i) => CustomerRow(
                    customer: visible[i],
                    onTap: () => context.go('$basePath/${visible[i].id}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerRow extends StatelessWidget {
  const CustomerRow({super.key, required this.customer, required this.onTap});

  final Customer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final phone = customer.phone;
    return Slidable(
      key: ValueKey(customer.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => EntrySheet.show(
              context,
              customer: customer,
              type: EntryType.payment,
            ),
            icon: FluentIcons.money_24_regular,
            label: l10n.recordPayment,
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
          ),
          if (phone != null && phone.isNotEmpty)
            SlidableAction(
              onPressed: (_) => launchUrl(Uri(scheme: 'tel', path: phone)),
              icon: FluentIcons.call_24_regular,
              label: l10n.call,
              backgroundColor: scheme.secondaryContainer,
              foregroundColor: scheme.onSecondaryContainer,
            ),
        ],
      ),
      child: ListTile(
        minVerticalPadding: 12,
        onTap: onTap,
        title: Text(customerTitle(l10n, customer)),
        subtitle: customer.village == null ? null : Text(customer.village!),
        trailing: BalanceText(customer: customer),
      ),
    );
  }
}

/// Balance with colour and a pending-sync marker.
class BalanceText extends StatelessWidget {
  const BalanceText({super.key, required this.customer, this.large = false});

  final Customer customer;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final amounts = theme.extension<AmountStyle>()!;
    final cents = customer.balance.cents;
    final color = cents > 0 ? amounts.owed : amounts.paid;
    final caption = cents > 0
        ? l10n.owes
        : cents < 0
        ? l10n.advance
        : l10n.settled;
    final style = large
        ? amounts.large.copyWith(color: color)
        : theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: large
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: large ? 320 : 140),
          child: AutoSizeText(
            cents == 0 ? caption : customer.balance.abs().format(),
            maxLines: 1,
            minFontSize: 14,
            style: style,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (customer.isPending) ...[
              Icon(
                FluentIcons.cloud_arrow_up_16_regular,
                size: 16,
                color: theme.colorScheme.tertiary,
                semanticLabel: l10n.pendingSync,
              ),
              const SizedBox(width: 4),
            ],
            if (cents != 0) Text(caption, style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}
