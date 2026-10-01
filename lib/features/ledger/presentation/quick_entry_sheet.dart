import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../../../app/current_shop.dart';
import '../../../app/l10n/app_localizations.dart';
import '../../../core/di/providers.dart';
import '../../../core/money.dart';
import '../domain/categories.dart';
import '../domain/models.dart';
import 'category_labels.dart';
import 'labels.dart';

/// A sale or money spent, with no customer (PRD C4): tap a category, type
/// the amount, save. Saved locally at once, like every entry.
class QuickEntrySheet extends ConsumerStatefulWidget {
  const QuickEntrySheet({super.key, required this.sale});

  /// true: sales categories; false: expenses and stock bought.
  final bool sale;

  static Future<void> show(BuildContext context, {required bool sale}) =>
      showModalBottomSheet<void>(
        context: context,
        // Above the shell's bottom bar, not inside the tab.
        useRootNavigator: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => QuickEntrySheet(sale: sale),
      );

  @override
  ConsumerState<QuickEntrySheet> createState() => _QuickEntrySheetState();
}

class _QuickEntrySheetState extends ConsumerState<QuickEntrySheet> {
  final _amount = TextEditingController();
  late EntryCategory _category = widget.sale
      ? EntryCategory.grocery
      : EntryCategory.stockPurchase;
  PaymentMethod _method = PaymentMethod.cash;
  String? _amountError;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final amount = Money.tryParse(_amount.text);
    if (amount == null || amount.isZero || amount.isNegative) {
      setState(() => _amountError = l10n.errorAmount);
      return;
    }
    final saved = ref
        .read(ledgerRepositoryProvider)
        .addEntry(
          context.membership.shopId,
          EntryDraft(
            type: _category.type,
            amountCents: amount.cents,
            txnDate: clock.now(),
            method: _method,
            category: _category.name,
          ),
        );
    if (saved.isLeft()) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(l10n.entrySaved)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final categories = widget.sale
        ? EntryCategory.sales
        : EntryCategory.spending;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.sale ? l10n.recordSale : l10n.recordExpense,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(l10n.chooseCategory, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.1,
              children: [
                for (final c in categories)
                  _CategoryTile(
                    category: c,
                    selected: c == _category,
                    onTap: () => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('quick-amount'),
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: theme.textTheme.headlineSmall,
              decoration: InputDecoration(
                labelText: l10n.amountLabel,
                errorText: _amountError,
              ),
              onChanged: (_) {
                if (_amountError != null) setState(() => _amountError = null);
              },
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            Text(l10n.paidBy, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            ToggleSwitch(
              minHeight: 48,
              minWidth: 84,
              totalSwitches: PaymentMethod.values.length,
              labels: [for (final m in PaymentMethod.values) m.label(l10n)],
              initialLabelIndex: _method.index,
              activeBgColor: [theme.colorScheme.primary],
              activeFgColor: theme.colorScheme.onPrimary,
              inactiveBgColor: theme.colorScheme.surfaceContainerHighest,
              inactiveFgColor: theme.colorScheme.onSurface,
              onToggle: (i) =>
                  setState(() => _method = PaymentMethod.values[i ?? 0]),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const ValueKey('quick-save'),
              onPressed: _save,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final EntryCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected
            ? BorderSide(color: scheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(category.icon, size: 30),
              const SizedBox(height: 4),
              Text(
                category.label(l10n),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
