import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../../../app/current_shop.dart';
import '../../../app/l10n/app_localizations.dart';
import '../../../core/di/providers.dart';
import '../../../core/money.dart';
import '../../../core/rbac/permission.dart';
import '../domain/entry_type.dart';
import '../domain/models.dart';
import 'labels.dart';
import 'receipt.dart';

/// Give credit or record a payment for one customer (PRD C3). Saves locally
/// at once, so it works with no signal; the balance shows as pending until
/// the server confirms.
///
/// The Safe Credit Limit warning is added here in Phase 4, and voice entry
/// fills this same form in Phase 3.
class EntrySheet extends ConsumerStatefulWidget {
  const EntrySheet({super.key, required this.customer, required this.type});

  final Customer customer;
  final EntryType type;

  static Future<void> show(
    BuildContext context, {
    required Customer customer,
    required EntryType type,
  }) => showModalBottomSheet<void>(
    context: context,
    // Above the shell's bottom bar, not inside the tab.
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => EntrySheet(customer: customer, type: type),
  );

  @override
  ConsumerState<EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends ConsumerState<EntrySheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;
  late DateTime _date = _today();
  bool _settle = false;
  String? _amountError;

  static DateTime _today() {
    final now = clock.now();
    return DateTime(now.year, now.month, now.day, now.hour, now.minute);
  }

  bool get _isPayment => widget.type == EntryType.payment;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  /// What a "settle" would write off, if this payment is less than owed.
  Money? get _writeOff {
    final paid = Money.tryParse(_amount.text);
    final owed = widget.customer.balance;
    if (!_isPayment || paid == null || paid.isZero || paid >= owed) {
      return null;
    }
    return owed - paid;
  }

  Future<void> _pickDate() async {
    final now = clock.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: now.subtract(const Duration(days: 366)),
      lastDate: now,
    );
    if (picked != null) {
      setState(
        () => _date = DateTime(picked.year, picked.month, picked.day, 12),
      );
    }
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final amount = Money.tryParse(_amount.text);
    if (amount == null || amount.isZero) {
      setState(() => _amountError = l10n.errorAmount);
      return;
    }
    final repo = ref.read(ledgerRepositoryProvider);
    final membership = context.membership;
    final note = _note.text.trim();
    final saved = repo.addEntry(
      membership.shopId,
      EntryDraft(
        type: widget.type,
        amountCents: amount.cents,
        customerId: widget.customer.id,
        txnDate: _date,
        method: _isPayment ? _method : null,
        note: note.isEmpty ? null : note,
      ),
    );
    final writeOff = _writeOff;
    if (saved.isRight() && _settle && writeOff != null) {
      repo.addEntry(
        membership.shopId,
        EntryDraft(
          type: EntryType.discount,
          amountCents: writeOff.cents,
          customerId: widget.customer.id,
          txnDate: _date,
        ),
      );
    }
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    navigator.pop();
    saved.match((_) {}, (clientId) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.entrySaved)));
      if (_isPayment) {
        final balanceAfter =
            widget.customer.balance -
            amount -
            (_settle ? writeOff ?? const Money.zero() : const Money.zero());
        ReceiptDialog.show(
          navigator.context,
          ReceiptData(
            shopName: membership.shopName,
            customer: customerTitle(l10n, widget.customer),
            amount: amount,
            method: _method,
            date: _date,
            balanceAfter: balanceAfter,
            receiptNo: clientId,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canDiscount = context.membership.role.can(
      Permission.ledgerCreateExpense,
    );
    final writeOff = _writeOff;
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
              '${_isPayment ? l10n.recordPayment : l10n.giveCredit} · '
              '${customerTitle(l10n, widget.customer)}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('entry-amount'),
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: theme.textTheme.headlineMedium,
              decoration: InputDecoration(
                labelText: l10n.amountLabel,
                errorText: _amountError,
              ),
              onChanged: (_) => setState(() => _amountError = null),
            ),
            if (_isPayment) ...[
              const SizedBox(height: 16),
              ToggleSwitch(
                minHeight: 48,
                minWidth: 80,
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
              if (canDiscount && writeOff != null)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _settle,
                  onChanged: (v) => setState(() => _settle = v ?? false),
                  title: Text(l10n.settleWithDiscount(writeOff.format())),
                ),
            ],
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.dateLabel),
              trailing: Text(DateFormat.yMMMd(l10n.localeName).format(_date)),
              onTap: _pickDate,
            ),
            TextField(
              controller: _note,
              maxLength: 200,
              decoration: InputDecoration(labelText: l10n.noteLabel),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('entry-save'),
              onPressed: _save,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
