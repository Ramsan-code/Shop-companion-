import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/money.dart';
import '../domain/entry_type.dart';
import '../domain/voice_entry_parser.dart';

/// Opened by the centre mic button. Phase 0 takes typed text so the parser
/// can be tried on a device; Phase 3 adds speech_to_text, spoken read-back,
/// the MobX confirm store and saving.
class VoiceEntrySheet extends StatefulWidget {
  const VoiceEntrySheet({super.key, this.parser = const VoiceEntryParser()});

  final VoiceEntryParser parser;

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const VoiceEntrySheet(),
  );

  @override
  State<VoiceEntrySheet> createState() => _VoiceEntrySheetState();
}

class _VoiceEntrySheetState extends State<VoiceEntrySheet> {
  ParsedEntry _parsed = const ParsedEntry();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final unknown = l10n.parsedUnknown;
    final amount = _parsed.amountCents;
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
          Text(l10n.micTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            autofocus: true,
            decoration: InputDecoration(hintText: l10n.micHint),
            onChanged: (text) =>
                setState(() => _parsed = widget.parser.parse(text)),
          ),
          const SizedBox(height: 16),
          _Row(
            label: l10n.parsedCustomer,
            value: [
              _parsed.customerName,
              _parsed.kinshipTerm,
            ].whereType<String>().join(' '),
            fallback: unknown,
          ),
          _Row(
            label: l10n.parsedAmount,
            value: amount == null ? '' : Money(amount).format(),
            fallback: unknown,
            large: true,
          ),
          _Row(
            label: l10n.parsedType,
            value: _parsed.type == null ? '' : _typeLabel(l10n, _parsed.type!),
            fallback: unknown,
          ),
        ],
      ),
    );
  }

  static String _typeLabel(AppLocalizations l10n, EntryType type) =>
      switch (type) {
        EntryType.credit => l10n.typeCredit,
        EntryType.payment => l10n.typePayment,
        EntryType.sale => l10n.typeSale,
        EntryType.expense => l10n.typeExpense,
        // The parser doesn't produce these yet; labels arrive with Phase 6.
        EntryType.purchase || EntryType.discount => type.name,
      };
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.fallback,
    this.large = false,
  });

  final String label;
  final String value;
  final String fallback;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = large
        ? theme.textTheme.headlineMedium
        : theme.textTheme.titleMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Expanded(
            child: AutoSizeText(
              value.isEmpty ? fallback : value,
              maxLines: 1,
              minFontSize: 14,
              style: value.isEmpty
                  ? style?.copyWith(color: theme.colorScheme.outline)
                  : style,
            ),
          ),
        ],
      ),
    );
  }
}
