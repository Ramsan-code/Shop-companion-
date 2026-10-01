import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/current_shop.dart';
import '../../../app/l10n/app_localizations.dart';
import '../../../core/di/providers.dart';
import '../../../core/phone.dart';
import '../../ledger/domain/models.dart';
import '../../ledger/presentation/labels.dart';

/// Add or edit a customer (PRD C2), optionally from the phone's contacts.
/// Saves locally at once, so it works with no signal.
class CustomerFormSheet extends ConsumerStatefulWidget {
  const CustomerFormSheet({super.key, this.customer});

  final Customer? customer;

  static Future<void> show(BuildContext context, {Customer? customer}) =>
      showModalBottomSheet<void>(
        context: context,
        // Above the shell's bottom bar, not inside the tab.
        useRootNavigator: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => CustomerFormSheet(customer: customer),
      );

  @override
  ConsumerState<CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends ConsumerState<CustomerFormSheet> {
  late final _name = TextEditingController(text: widget.customer?.name);
  late final _phone = TextEditingController(text: widget.customer?.phone);
  late final _village = TextEditingController(text: widget.customer?.village);
  late final _payDay = TextEditingController(
    text: widget.customer?.payDay?.toString(),
  );
  late Kinship? _kinship = widget.customer?.kinship;
  late IncomeType? _income = widget.customer?.incomeType;
  String? _nameError;
  String? _payDayError;

  @override
  void dispose() {
    for (final c in [_name, _phone, _village, _payDay]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickContact() async {
    try {
      final status = await FlutterContacts.permissions.request(
        PermissionType.read,
      );
      if (status != PermissionStatus.granted &&
          status != PermissionStatus.limited) {
        return;
      }
      final contact = await FlutterContacts.native.showPicker(
        properties: {ContactProperty.phone},
      );
      if (contact == null || !mounted) return;
      setState(() {
        _name.text = contact.displayName ?? _name.text;
        final number = contact.phones.firstOrNull?.number;
        if (number != null) _phone.text = normalizeLkMobile(number) ?? number;
      });
    } on Exception {
      // No picker on this device: the fields stay editable by hand.
    }
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    final payDayText = _payDay.text.trim();
    final payDay = payDayText.isEmpty ? null : int.tryParse(payDayText);
    setState(() {
      _nameError = name.isEmpty ? l10n.errorCustomerName : null;
      _payDayError =
          payDayText.isNotEmpty && (payDay == null || payDay < 1 || payDay > 31)
          ? l10n.errorPayDay
          : null;
    });
    if (_nameError != null || _payDayError != null) return;

    final phoneText = _phone.text.trim();
    final draft = CustomerDraft(
      name: name,
      phone: phoneText.isEmpty
          ? null
          : normalizeLkMobile(phoneText) ?? phoneText,
      kinship: _kinship,
      village: _village.text.trim().isEmpty ? null : _village.text.trim(),
      incomeType: _income,
      payDay: payDay,
    );
    final repo = ref.read(ledgerRepositoryProvider);
    final shopId = context.membership.shopId;
    final existing = widget.customer;
    if (existing == null) {
      repo.addCustomer(shopId, draft);
    } else {
      repo.updateCustomer(shopId, existing.id, draft);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
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
              widget.customer == null ? l10n.addCustomer : l10n.editCustomer,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (widget.customer == null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: _pickContact,
                  icon: const Icon(FluentIcons.contact_card_24_regular),
                  label: Text(l10n.fromContacts),
                ),
              ),
            TextField(
              key: const ValueKey('customer-name'),
              controller: _name,
              autofocus: widget.customer == null,
              textCapitalization: TextCapitalization.words,
              maxLength: 80,
              decoration: InputDecoration(
                labelText: l10n.customerName,
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.kinshipLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ChoiceChip(
                  label: Text(l10n.kinNone),
                  selected: _kinship == null,
                  onSelected: (_) => setState(() => _kinship = null),
                ),
                for (final k in Kinship.values)
                  ChoiceChip(
                    label: Text(k.label(l10n)),
                    selected: _kinship == k,
                    onSelected: (_) => setState(() => _kinship = k),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.customerPhone,
                hintText: '077 123 4567',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _village,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.customerVillage),
            ),
            const SizedBox(height: 16),
            Text(l10n.incomeLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final t in IncomeType.values)
                  ChoiceChip(
                    label: Text(t.label(l10n)),
                    selected: _income == t,
                    onSelected: (on) => setState(() => _income = on ? t : null),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _payDay,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.payDayLabel,
                errorText: _payDayError,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(l10n.save)),
          ],
        ),
      ),
    );
  }
}
