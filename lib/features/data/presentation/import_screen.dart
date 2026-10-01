import 'dart:async';

import 'package:clock/clock.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/current_shop.dart';
import '../../../app/l10n/app_localizations.dart';
import '../../../core/di/providers.dart';
import '../../../core/money.dart';
import '../../../core/phone.dart';
import '../../ledger/domain/entry_type.dart';
import '../../ledger/domain/models.dart';
import '../../voice/domain/speech_input.dart';
import '../domain/import_table.dart';
import 'import_store.dart';

/// Switch-in import (PRD N2, US10): a Khatabook/OkCredit/Shopbook export,
/// or customers said one by one, into a preview; one tap saves them all.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  ImportStore? _store;
  bool _listening = false;
  String _partial = '';
  StreamSubscription<SpeechEvent>? _sub;
  SpeechInput? _input;
  late final String _shopId = context.membership.shopId;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final customers = await ref
        .read(ledgerRepositoryProvider)
        .watchCustomers(_shopId)
        .first;
    if (mounted) setState(() => _store = ImportStore(existing: customers));
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    unawaited(_input?.cancel());
    super.dispose();
  }

  Future<void> _pickFile() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final file = await ref.read(fileOpenerProvider).pick(const [
      'xlsx',
      'csv',
      'ods',
      'txt',
    ]);
    if (file == null || !mounted) return;
    final table = readTable(file.bytes, file.name);
    if (table == null || table.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.importUnreadable)));
      return;
    }
    _store!.loadTable(table);
  }

  /// Voice bulk entry: keep listening, one customer per phrase, until Stop.
  Future<void> _listen() async {
    final engine = ref.read(voiceEngineProvider(_shopId));
    final input = await engine.pick();
    if (input == null || !mounted) return;
    _input = input;
    setState(() => _listening = true);
    var silences = 0;
    while (mounted && _listening) {
      final done = Completer<void>();
      _sub = input.listen(maxDuration: const Duration(seconds: 6)).listen((
        event,
      ) {
        switch (event) {
          case PartialSpeech(:final text):
            setState(() => _partial = text);
          case HeardSpeech(:final text):
            silences = 0;
            _store!.addSpoken(text);
            setState(() => _partial = '');
          case SpeechFailed(:final reason):
            // One pause means "next"; a second one, or any other
            // failure, ends the list.
            if (reason != SpeechFailure.noSpeech || ++silences >= 2) {
              setState(() => _listening = false);
            }
        }
      }, onDone: done.complete);
      await done.future;
      // Finished on its own: nothing to cancel (cancelling a finished
      // recogniser stream can wait forever).
      _sub = null;
      if (_store!.spokenRows.length >= 500) break;
    }
    if (mounted) setState(() => _listening = false);
  }

  Future<void> _stop() async {
    setState(() => _listening = false);
    await _input?.stop();
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(ledgerRepositoryProvider);
    final now = clock.now();
    var saved = 0;
    for (final c in _store!.chosen.value) {
      final id = repo
          .addCustomer(
            _shopId,
            CustomerDraft(
              name: c.name,
              phone: normalizeLkMobile(c.phone ?? ''),
              kinship: Kinship.values.byWire(c.kinship),
            ),
          )
          .toNullable();
      if (id == null) continue;
      saved++;
      if (c.balanceCents == 0) continue;
      // The opening balance as one entry, so the books still add up:
      // credit if they owe, a payment if they paid in advance.
      repo.addEntry(
        _shopId,
        EntryDraft(
          type: c.balanceCents > 0 ? EntryType.credit : EntryType.payment,
          amountCents: c.balanceCents.abs(),
          customerId: id,
          txnDate: now,
          method: c.balanceCents > 0 ? null : PaymentMethod.cash,
          note: l10n.importOpeningNote,
          source: 'import',
        ),
      );
    }
    ref.read(telemetryProvider).importDone(saved);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.importDone(saved))));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final store = _store;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.importTitle)),
      body: store == null
          ? const Center(child: CircularProgressIndicator())
          : Observer(
              builder: (context) {
                final rows = store.rows.value;
                final map = store.columns.value;
                final count = store.chosen.value.length;
                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        children: [
                          if (rows.isEmpty) ...[
                            Text(
                              l10n.importHelp,
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 16),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  key: const ValueKey('import-pick'),
                                  onPressed: _listening ? null : _pickFile,
                                  icon: const Icon(
                                    FluentIcons.document_table_24_regular,
                                  ),
                                  label: Text(l10n.importPickFile),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                key: const ValueKey('import-speak'),
                                tooltip: _listening
                                    ? l10n.importStop
                                    : l10n.importSpeak,
                                onPressed: _listening ? _stop : _listen,
                                icon: Icon(
                                  _listening
                                      ? FluentIcons.stop_24_filled
                                      : FluentIcons.mic_24_regular,
                                ),
                              ),
                            ],
                          ),
                          if (_listening)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _partial.isEmpty
                                    ? l10n.importSpeakHelp
                                    : _partial,
                              ),
                            ),
                          if (map != null) ...[
                            const SizedBox(height: 12),
                            _ColumnPickers(store: store, map: map),
                            SwitchListTile(
                              key: const ValueKey('import-flip'),
                              contentPadding: EdgeInsets.zero,
                              title: Text(l10n.importFlipSign),
                              value: store.flip.value,
                              onChanged: store.setFlip,
                            ),
                          ],
                          if (rows.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              l10n.importSummary(
                                count,
                                Money(store.totalOwedCents.value)
                                    .format(showCents: false),
                              ),
                              key: const ValueKey('import-summary'),
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            for (final row in rows)
                              _RowTile(
                                row: row,
                                onToggle: () => store.toggle(row),
                              ),
                          ],
                        ],
                      ),
                    ),
                    if (rows.isNotEmpty)
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: FilledButton(
                            key: const ValueKey('import-save'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                            ),
                            onPressed: count == 0 || _listening ? null : _save,
                            child: Text(l10n.importSave(count)),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _ColumnPickers extends StatelessWidget {
  const _ColumnPickers({required this.store, required this.map});

  final ImportStore store;
  final ColumnMap map;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final headers = store.headers.value;
    Widget picker(
      String label,
      int? value,
      void Function(int?) onChanged,
      String key,
    ) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<int?>(
        key: ValueKey(key),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          DropdownMenuItem(value: null, child: Text(l10n.columnNone)),
          for (var i = 0; i < headers.length; i++)
            DropdownMenuItem(value: i, child: Text(headers[i])),
        ],
        onChanged: onChanged,
      ),
    );
    final splitBalance = map.balance == null && map.owes != null;
    return Column(
      children: [
        picker(
          l10n.columnName,
          map.name,
          (v) => store.setColumns(map.copyWith(name: () => v)),
          'col-name',
        ),
        picker(
          l10n.columnPhone,
          map.phone,
          (v) => store.setColumns(map.copyWith(phone: () => v)),
          'col-phone',
        ),
        if (!splitBalance)
          picker(
            l10n.columnBalance,
            map.balance,
            (v) => store.setColumns(map.copyWith(balance: () => v)),
            'col-balance',
          ),
      ],
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({required this.row, required this.onToggle});

  final ImportRow row;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = row.candidate;
    final issue = switch (row.issue) {
      ImportIssue.noName => l10n.importNoName,
      ImportIssue.duplicate => l10n.importDuplicate,
      ImportIssue.none => null,
    };
    return Observer(
      builder: (_) => CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: row.include.value && row.issue != ImportIssue.noName,
        onChanged: row.issue == ImportIssue.noName ? null : (_) => onToggle(),
        title: Text(
          [c.name, if (c.kinship != null) c.kinship].join(' '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          [
            if (c.phone != null) c.phone!,
            if (c.balanceCents < 0) l10n.importAdvance,
            ?issue,
          ].join(' · '),
          style: issue == null
              ? null
              : TextStyle(color: theme.colorScheme.error),
        ),
        secondary: Text(
          Money(c.balanceCents.abs()).format(showCents: false),
          style: theme.textTheme.titleMedium,
        ),
      ),
    );
  }
}
