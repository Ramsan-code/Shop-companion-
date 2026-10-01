import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:clock/clock.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobx/mobx.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../../../app/current_shop.dart';
import '../../../app/l10n/app_localizations.dart';
import '../../../core/di/providers.dart';
import '../../../core/rbac/permission.dart';
import '../../collections/domain/collections.dart';
import '../../collections/presentation/trust_card.dart';
import '../../ledger/domain/entry_type.dart';
import '../../ledger/domain/ledger_math.dart';
import '../../ledger/domain/models.dart';
import '../../ledger/presentation/labels.dart';
import '../data/cloud_speech_input.dart';
import '../domain/confirmation.dart';
import '../domain/read_back.dart';
import '../domain/speech_input.dart';
import 'voice_entry_store.dart';

/// Voice entry (PRD C1, US1, flow 7.1-2): tap mic → speak → spoken and
/// visual read-back → "சரி" or one tap → saved locally (works offline).
///
/// Everything speech fills in is an editable form underneath, so the keypad
/// fallback is always there: correct a misheard amount by typing, or type
/// the whole entry when speech isn't available.
class VoiceEntrySheet extends ConsumerStatefulWidget {
  const VoiceEntrySheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    // Above the shell's bottom bar, not inside the tab.
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const VoiceEntrySheet(),
  );

  @override
  ConsumerState<VoiceEntrySheet> createState() => _VoiceEntrySheetState();
}

class _VoiceEntrySheetState extends ConsumerState<VoiceEntrySheet> {
  VoiceEntryStore? _store;
  List<Customer> _customers = const [];
  SpeechInput? _input;
  StreamSubscription<SpeechEvent>? _listening;
  bool _deviceFailed = false;
  final _amount = TextEditingController();
  final _search = TextEditingController();
  ReactionDisposer? _syncAmount;

  // Captured once: `ref` and `context` can't be used after unmount.
  late final String _shopId = context.membership.shopId;
  late final VoiceEngine _engine = ref.read(voiceEngineProvider(_shopId));
  late final ReadBack _readBack = ref.read(readBackProvider);
  final _opened = Stopwatch()..start();

  /// Safe Credit Limit for the chosen customer (Owner/Partner only).
  late final bool _canSeeLimits = context.membership.role.can(
    Permission.scoreRead,
  );
  ReactionDisposer? _followCustomer;

  /// Credit and payment for everyone; sale with `ledger:create`; expense
  /// with `ledger:createExpense` (Owner/Partner).
  late final List<EntryType> _types = [
    EntryType.credit,
    EntryType.payment,
    EntryType.sale,
    if (context.membership.role.can(Permission.ledgerCreateExpense))
      EntryType.expense,
  ];
  StreamSubscription<TrustInfo?>? _trustSub;
  TrustInfo? _trust;
  bool _giveAnyway = false;

  LimitWarning? get _warning {
    final store = _store;
    final customer = store?.customer.value;
    final amount = store?.amount.value;
    if (customer == null || amount == null) return null;
    if (store!.type.value != EntryType.credit) return null;
    return checkCreditLimit(
      trust: _trust,
      balanceCents: customer.balance.cents,
      creditCents: amount.cents,
    );
  }

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    // Touch the late fields while mounted.
    _engine;
    _readBack;
    _canSeeLimits;
    _types;
    // The cached list: available offline, used to match the heard name.
    _customers = await ref
        .read(ledgerRepositoryProvider)
        .watchCustomers(_shopId)
        .first;
    if (!mounted) return;
    final store = VoiceEntryStore(customers: _customers, allowedTypes: _types);
    _syncAmount = reaction((_) => store.amountText.value, (String text) {
      if (_amount.text != text) _amount.text = text;
    });
    if (_canSeeLimits) {
      _followCustomer = reaction((_) => store.customer.value?.id, (String? id) {
        unawaited(_trustSub?.cancel());
        setState(() {
          _trust = null;
          _giveAnyway = false;
        });
        if (id == null) return;
        _trustSub = ref
            .read(collectionsRepositoryProvider)
            .watchTrust(_shopId, id)
            .listen((t) {
              if (mounted) setState(() => _trust = t);
            });
      }, fireImmediately: true);
    }
    setState(() => _store = store);
    await _listen();
  }

  Future<void> _listen() async {
    final store = _store!;
    await _listening?.cancel();
    final input = await _engine.pick(deviceFailed: _deviceFailed);
    if (!mounted) return;
    if (input == null) {
      store.fail(
        _deviceFailed ? SpeechFailure.network : SpeechFailure.unavailable,
      );
      return;
    }
    _input = input;
    store.relisten();
    _listening = input
        .listen(phrases: [for (final c in _customers) c.name])
        .listen((event) => _onEvent(input, event));
  }

  void _onEvent(SpeechInput input, SpeechEvent event) {
    final store = _store!;
    switch (event) {
      case PartialSpeech(:final text):
        store.setPartial(text);
      case HeardSpeech(:final text):
        store.applyHeard(text);
        if (store.canSave.value) unawaited(_readBackAndConfirm());
      case SpeechFailed(:final reason):
        final engine = _engine;
        // The phone's recogniser can't do Tamil here: try the cloud once.
        if (input == engine.device &&
            !_deviceFailed &&
            engine.cloud != null &&
            (reason == SpeechFailure.network ||
                reason == SpeechFailure.unavailable)) {
          _deviceFailed = true;
          unawaited(_listen());
        } else {
          store.fail(reason);
        }
    }
  }

  String _who(AppLocalizations l10n, VoiceEntryStore store) {
    if (!store.needsCustomer.value) return '';
    final c = store.customer.value;
    if (c != null) return customerTitle(l10n, c);
    final name = store.newCustomerName.value ?? '';
    final kin = store.newCustomerKinship.value;
    return kin == null ? name : '$name ${kin.label(l10n)}';
  }

  Future<void> _readBackAndConfirm() async {
    final store = _store!;
    final l10n = AppLocalizations.of(context);
    final text = readBackText(
      languageCode: l10n.localeName,
      customer: _who(l10n, store),
      amountCents: store.amount.value!.cents,
      type: store.type.value,
    );
    await _readBack.speak(text, languageCode: l10n.localeName);
    // Only the on-device recogniser is quick enough for a one-word answer.
    final device = _engine.device;
    // Over the Safe Credit Limit: never saved by voice alone, it needs the
    // "give anyway" tick.
    if (!mounted ||
        !store.canSave.value ||
        _input != device ||
        _warning != null) {
      return;
    }
    final answer = await device
        .listen(maxDuration: const Duration(seconds: 4))
        .firstWhere((e) => e is! PartialSpeech)
        .timeout(
          const Duration(seconds: 6),
          onTimeout: () => const SpeechFailed(SpeechFailure.noSpeech),
        );
    if (!mounted) return;
    if (answer is HeardSpeech &&
        readConfirmation(answer.text) == Confirmation.yes &&
        store.canSave.value) {
      await _save();
    }
  }

  Future<void> _save() async {
    final store = _store!;
    if (!store.canSave.value) return;
    if (_warning != null && !_giveAnyway) return;
    store.markSaving();
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(ledgerRepositoryProvider);
    final shopId = _shopId;
    final needsCustomer = affectsCustomer(store.type.value);
    var customerId = needsCustomer ? store.customer.value?.id : null;
    final newName = store.newCustomerName.value;
    if (needsCustomer && customerId == null && newName != null) {
      customerId = repo
          .addCustomer(
            shopId,
            CustomerDraft(
              name: newName,
              kinship: store.newCustomerKinship.value,
            ),
          )
          .toNullable();
    }
    final saved = repo.addEntry(
      shopId,
      EntryDraft(
        type: store.type.value,
        amountCents: store.amount.value!.cents,
        customerId: customerId,
        txnDate: clock.now(),
        // Spoken entries are cash; the keypad sheets ask for the method.
        method: store.type.value == EntryType.credit
            ? null
            : PaymentMethod.cash,
        source: store.heard.value.isEmpty ? 'text' : 'voice',
      ),
    );
    if (saved.isLeft()) {
      store.markEditing();
      return;
    }
    // Voice entry speed (NFR: under 10 seconds), engine only.
    ref
        .read(telemetryProvider)
        .voiceEntrySaved(
          took: _opened.elapsed,
          cloud: _input != null && _input != _engine.device,
        );
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(l10n.entrySaved)));
  }

  @override
  void dispose() {
    _syncAmount?.call();
    _followCustomer?.call();
    unawaited(_trustSub?.cancel());
    unawaited(_listening?.cancel());
    unawaited(_input?.cancel());
    unawaited(_readBack.stop());
    _amount.dispose();
    _search.dispose();
    super.dispose();
  }

  String _failureText(AppLocalizations l10n, SpeechFailure f) => switch (f) {
    SpeechFailure.permission => l10n.voicePermission,
    SpeechFailure.noSpeech => l10n.voiceNoSpeech,
    SpeechFailure.network => l10n.voiceNetwork,
    SpeechFailure.unavailable => l10n.voiceUnavailable,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final store = _store;
    if (store == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Observer(
          builder: (context) {
            final listening = store.step.value == VoiceStep.listening;
            final failure = store.failure.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // What is happening / what was heard.
                Row(
                  children: [
                    Icon(
                      listening
                          ? FluentIcons.mic_24_filled
                          : FluentIcons.mic_off_24_regular,
                      size: 32,
                      color: listening
                          ? theme.colorScheme.error
                          : theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        listening
                            ? (store.partial.value.isEmpty
                                  ? l10n.voiceListening
                                  : store.partial.value)
                            : failure != null
                            ? _failureText(l10n, failure)
                            : l10n.voiceHeard(store.heard.value),
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                if (store.canSave.value && store.heard.value.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _ReadBackCard(
                    who: _who(l10n, store),
                    amount: store.amount.value!.format(),
                    type: store.type.value.label(l10n),
                    prompt: l10n.voiceSayYes,
                  ),
                ],
                const SizedBox(height: 16),
                if (store.needsCustomer.value) ...[
                  _CustomerField(
                    store: store,
                    search: _search,
                    who: _who(l10n, store),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  key: const ValueKey('voice-amount'),
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: theme.textTheme.headlineSmall,
                  decoration: InputDecoration(labelText: l10n.amountLabel),
                  onChanged: store.setAmountText,
                ),
                if (_warning case final warning?)
                  LimitWarningBox(
                    warning: warning,
                    customerName: _who(l10n, store),
                    confirmed: _giveAnyway,
                    onConfirm: (v) => setState(() => _giveAnyway = v),
                  ),
                const SizedBox(height: 16),
                ToggleSwitch(
                  key: const ValueKey('voice-type'),
                  minHeight: 48,
                  minWidth: _types.length > 3 ? 84 : 110,
                  totalSwitches: _types.length,
                  labels: [for (final t in _types) t.label(l10n)],
                  initialLabelIndex: _types.indexOf(store.type.value),
                  activeBgColor: [theme.colorScheme.primary],
                  activeFgColor: theme.colorScheme.onPrimary,
                  inactiveBgColor: theme.colorScheme.surfaceContainerHighest,
                  inactiveFgColor: theme.colorScheme.onSurface,
                  onToggle: (i) => store.setType(_types[i ?? 0]),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: listening ? null : _listen,
                        icon: const Icon(FluentIcons.mic_24_regular),
                        label: Text(l10n.voiceSpeakAgain),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: const ValueKey('voice-save'),
                        onPressed:
                            store.canSave.value &&
                                (_warning == null || _giveAnyway)
                            ? _save
                            : null,
                        child: Text(l10n.save),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReadBackCard extends StatelessWidget {
  const _ReadBackCard({
    required this.who,
    required this.amount,
    required this.type,
    required this.prompt,
  });

  final String who;
  final String amount;
  final String type;
  final String prompt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (who.isNotEmpty) Text(who, style: theme.textTheme.titleLarge),
            AutoSizeText(
              '$amount · $type',
              maxLines: 1,
              minFontSize: 14,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(prompt, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// The chosen customer, or the candidates, or a typed search (keypad).
class _CustomerField extends StatefulWidget {
  const _CustomerField({
    required this.store,
    required this.search,
    required this.who,
  });

  final VoiceEntryStore store;
  final TextEditingController search;
  final String who;

  @override
  State<_CustomerField> createState() => _CustomerFieldState();
}

class _CustomerFieldState extends State<_CustomerField> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final store = widget.store;
    return Observer(
      builder: (context) {
        final chosen = store.hasCustomer.value;
        final results = store.search(_query);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (chosen)
              InputChip(
                avatar: const Icon(FluentIcons.person_24_regular),
                label: Text(
                  store.customer.value == null
                      ? l10n.voiceNewCustomer(widget.who)
                      : widget.who,
                ),
                onDeleted: () => store.chooseNewCustomer(''),
              )
            else ...[
              if (store.candidates.isNotEmpty) ...[
                Text(
                  l10n.voiceWhichCustomer,
                  style: theme.textTheme.titleSmall,
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final m in store.candidates)
                      ActionChip(
                        label: Text(customerTitle(l10n, m.customer)),
                        onPressed: () => store.chooseCustomer(m.customer),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: widget.search,
                decoration: InputDecoration(
                  labelText: l10n.customerSearchLabel,
                  prefixIcon: const Icon(FluentIcons.search_24_regular),
                ),
                onChanged: (q) => setState(() => _query = q),
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final c in results)
                    ActionChip(
                      label: Text(customerTitle(l10n, c)),
                      onPressed: () => store.chooseCustomer(c),
                    ),
                  if (_query.trim().length >= 2)
                    ActionChip(
                      avatar: const Icon(FluentIcons.person_add_24_regular),
                      label: Text(l10n.addAsNew(_query.trim())),
                      onPressed: () => store.chooseNewCustomer(_query),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
