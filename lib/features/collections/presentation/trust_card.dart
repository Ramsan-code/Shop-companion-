import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/current_shop.dart';
import '../../../app/failure_message.dart';
import '../../../app/l10n/app_localizations.dart';
import '../../../core/di/providers.dart';
import '../../../core/money.dart';
import '../../../core/rbac/permission.dart';
import '../../ledger/domain/models.dart';
import '../../ledger/presentation/labels.dart';
import '../domain/collections.dart';
import 'trust_labels.dart';

/// Trust band, plain reasons and the Safe Credit Limit on the customer page
/// (PRD D1, D2, US4). Owner and Partner only; the owner can change the limit.
class TrustCard extends ConsumerWidget {
  const TrustCard({super.key, required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = context.membership.role;
    if (!role.can(Permission.scoreRead)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return StreamBuilder<TrustInfo?>(
      stream: ref
          .read(collectionsRepositoryProvider)
          .watchTrust(context.membership.shopId, customer.id),
      builder: (context, snap) {
        final trust = snap.data;
        if (trust == null) return const SizedBox.shrink();
        final limit = trust.creditLimitCents;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TrustBandChip(band: trust.band, score: trust.score),
                const SizedBox(height: 8),
                for (final r in trust.reasons.take(2))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• ${reasonText(l10n, r)}'),
                  ),
                if (limit != null) ...[
                  const Divider(height: 24),
                  Text(
                    l10n.safeLimit(Money(limit).format(showCents: false)),
                    style: theme.textTheme.titleMedium,
                  ),
                  if (trust.isOverridden)
                    Text(
                      l10n.safeLimitOverridden,
                      style: theme.textTheme.bodySmall,
                    ),
                  if (role.can(Permission.limitOverride))
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) =>
                              _LimitDialog(customer: customer, trust: trust),
                        ),
                        child: Text(l10n.changeLimit),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LimitDialog extends ConsumerStatefulWidget {
  const _LimitDialog({required this.customer, required this.trust});

  final Customer customer;
  final TrustInfo trust;

  @override
  ConsumerState<_LimitDialog> createState() => _LimitDialogState();
}

class _LimitDialogState extends ConsumerState<_LimitDialog> {
  late final _amount = TextEditingController(
    text: ((widget.trust.creditLimitCents ?? 0) ~/ 100).toString(),
  );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save(int? limitCents) async {
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final result = await ref
        .read(collectionsRepositoryProvider)
        .overrideLimit(
          context.membership.shopId,
          widget.customer.id,
          limitCents,
        )
        .run();
    if (!mounted) return;
    result.match(
      (f) => setState(() {
        _busy = false;
        _error = failureMessage(l10n, f);
      }),
      (_) => navigator.pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final suggested = widget.trust.computedLimitCents;
    return AlertDialog(
      title: Text(l10n.changeLimitTitle(customerTitle(l10n, widget.customer))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const ValueKey('limit-amount'),
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.amountLabel,
              errorText: _error,
            ),
          ),
          if (widget.trust.isOverridden && suggested != null)
            TextButton(
              onPressed: _busy ? null : () => _save(null),
              child: Text(
                l10n.useSuggestedLimit(
                  Money(suggested).format(showCents: false),
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _busy
              ? null
              : () {
                  final money = Money.tryParse(_amount.text);
                  if (money == null) {
                    setState(() => _error = l10n.errorAmount);
                    return;
                  }
                  _save(money.cents);
                },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// The over-limit warning shown before saving credit (PRD D2: "warning
/// before saving credit above it"). [onConfirm] reports the "give anyway"
/// tick; saving needs it while the warning shows.
class LimitWarningBox extends StatelessWidget {
  const LimitWarningBox({
    super.key,
    required this.warning,
    required this.customerName,
    required this.confirmed,
    required this.onConfirm,
  });

  final LimitWarning warning;
  final String customerName;
  final bool confirmed;
  final ValueChanged<bool> onConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    // A Material, not a coloured box, so the checkbox row's ripple shows.
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.overLimitWarning(
                  customerName,
                  Money(warning.balanceAfterCents).format(showCents: false),
                  Money(warning.limitCents).format(showCents: false),
                ),
                style: TextStyle(color: scheme.onErrorContainer),
              ),
              CheckboxListTile(
                key: const ValueKey('give-anyway'),
                contentPadding: EdgeInsets.zero,
                value: confirmed,
                onChanged: (v) => onConfirm(v ?? false),
                title: Text(l10n.giveAnyway),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
