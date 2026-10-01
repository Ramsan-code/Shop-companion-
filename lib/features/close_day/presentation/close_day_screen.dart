import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/current_shop.dart';
import '../../../app/l10n/app_localizations.dart';
import '../../../core/di/providers.dart';
import '../../../core/money.dart';
import '../../../core/rbac/permission.dart';
import '../../../sync/sync_badge.dart';
import '../../collections/presentation/who_to_ask_cubit.dart';
import '../../ledger/presentation/labels.dart';
import '../../voice/domain/speech_input.dart';
import '../../voice/domain/voice_entry_parser.dart';
import '../domain/day_totals.dart';
import 'close_day_cubit.dart';

/// Close Day (PRD C5, D11 lite, flow 7.1-5): say or type the counted cash,
/// see expected vs counted and Profit Mirror in plain words, hear it read
/// out, and see tomorrow's follow-ups. A Helper only enters the count.
class CloseDayScreen extends ConsumerWidget {
  const CloseDayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = context.membership;
    final owner = membership.role.can(Permission.profitRead);
    final shopId = membership.shopId;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CloseDayCubit(
            ledger: ref.read(ledgerRepositoryProvider),
            stock: ref.read(stockRepositoryProvider),
            closeDay: ref.read(closeDayRepositoryProvider),
            shopId: shopId,
            withTotals: owner,
          ),
        ),
        if (membership.role.can(Permission.insightsRead))
          BlocProvider(
            create: (_) => WhoToAskCubit(
              collections: ref.read(collectionsRepositoryProvider),
              ledger: ref.read(ledgerRepositoryProvider),
              shopId: shopId,
            ),
          ),
      ],
      child: owner ? const _OwnerView() : const _HelperView(),
    );
  }
}

String _money(int cents) => Money(cents).format(showCents: false);

class _HelperView extends StatelessWidget {
  const _HelperView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.closeDayTitle),
        actions: const [SyncBadge()],
      ),
      body: BlocBuilder<CloseDayCubit, CloseDayState>(
        builder: (context, state) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(l10n.helperCountHelp, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            _CountInput(
              onSave: (cents) {
                if (!context.read<CloseDayCubit>().saveCount(cents)) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(l10n.countSaved)));
              },
            ),
            if (state.myCountCents case final c?) ...[
              const SizedBox(height: 16),
              Text(
                l10n.yourCount(_money(c)),
                key: const ValueKey('my-count'),
                style: theme.textTheme.titleMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OwnerView extends ConsumerWidget {
  const _OwnerView();

  /// The spoken summary in the app's language (PRD flow 7.1-5).
  static String summary(AppLocalizations l10n, CloseDayState state) {
    String say(int cents) => l10n.rupeesSpoken('${cents ~/ 100}');
    final t = state.totals;
    final parts = [
      l10n.closeDaySpoken(
        say(t.salesCents),
        say(t.collectedCents),
        say(t.expensesCents + t.purchasesCents),
        say(t.profitEstimateCents),
      ),
    ];
    if (state.differenceCents case final diff?) {
      parts.add(_cashLine(l10n, diff, say));
    }
    return parts.join(' ');
  }

  static String _cashLine(
    AppLocalizations l10n,
    int diff,
    String Function(int) money,
  ) => diff == 0
      ? l10n.closeDayMatch
      : diff < 0
      ? l10n.closeDayShort(money(-diff))
      : l10n.closeDayOver(money(diff));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final readBack = ref.read(readBackProvider);
    Future<void> speak(CloseDayState state) =>
        readBack.speak(summary(l10n, state), languageCode: l10n.localeName);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.closeDayTitle),
        actions: const [SyncBadge()],
      ),
      body: BlocBuilder<CloseDayCubit, CloseDayState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final t = state.totals;
          final diff = state.differenceCents;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _Line(l10n.typeSale, t.salesCents),
                      _Line(l10n.closeDayCreditGiven, t.creditCents),
                      _Line(l10n.closeDayCollected, t.collectedCents),
                      _Line(
                        l10n.closeDaySpent,
                        t.expensesCents + t.purchasesCents,
                      ),
                    ],
                  ),
                ),
              ),
              _ProfitMirror(totals: t),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Line(l10n.closeDayOpening, t.openingCashCents),
                      _Line(
                        l10n.closeDayExpected,
                        t.expectedCashCents,
                        emphasise: true,
                      ),
                      const SizedBox(height: 12),
                      _CountInput(
                        onSave: (cents) {
                          final cubit = context.read<CloseDayCubit>();
                          if (!cubit.saveCount(cents)) return;
                          // Read out once the new count is in the state.
                          unawaited(
                            cubit.stream
                                .firstWhere((s) => s.countedCents == cents)
                                .timeout(const Duration(seconds: 2))
                                .then(speak, onError: (_) {}),
                          );
                        },
                      ),
                      if (diff != null) ...[
                        const SizedBox(height: 12),
                        _CashResult(diff: diff),
                      ],
                      if (state.closing != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(
                                FluentIcons.cloud_checkmark_24_regular,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Flexible(child: Text(l10n.closingRecorded)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('close-day-listen'),
                onPressed: () => speak(state),
                icon: const Icon(FluentIcons.speaker_2_24_regular),
                label: Text(l10n.closeDayListen),
              ),
              const SizedBox(height: 16),
              Text(l10n.tomorrowTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              _Tomorrow(state: state),
            ],
          );
        },
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.cents, {this.emphasise = false});

  final String label;
  final int cents;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final style = emphasise ? text.titleLarge : text.titleMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: text.bodyLarge)),
          Text(_money(cents), style: style),
        ],
      ),
    );
  }
}

/// Profit Mirror lite (PRD D11): one sentence, plain words.
class _ProfitMirror extends StatelessWidget {
  const _ProfitMirror({required this.totals});

  final DayTotals totals;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profit = totals.profitEstimateCents;
    final loss = profit < 0;
    return Card(
      color: loss
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loss
                  ? l10n.profitMirrorLoss(_money(-profit))
                  : l10n.profitMirror(_money(profit)),
              key: const ValueKey('profit-mirror'),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(l10n.profitMirrorHow(totals.marginPercent)),
          ],
        ),
      ),
    );
  }
}

class _CashResult extends StatelessWidget {
  const _CashResult({required this.diff});

  final int diff;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final ok = diff == 0;
    return Material(
      color: ok ? scheme.primaryContainer : scheme.errorContainer,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              ok
                  ? FluentIcons.checkmark_circle_24_filled
                  : FluentIcons.warning_24_filled,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _OwnerView._cashLine(l10n, diff, _money),
                key: const ValueKey('cash-result'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tomorrow extends StatelessWidget {
  const _Tomorrow({required this.state});

  final CloseDayState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final whoToAsk = context.select<WhoToAskCubit?, List<WhoToAskRow>>(
      (c) =>
          c?.state.rows.where((r) => !r.paidSinceMorning).take(3).toList() ??
          const [],
    );
    final lines = [
      for (final r in whoToAsk)
        (
          FluentIcons.person_24_regular,
          l10n.tomorrowAsk(
            customerTitle(l10n, r.customer),
            r.customer.balance.format(showCents: false),
          ),
        ),
      for (final i in state.lowStock)
        (FluentIcons.box_24_regular, l10n.tomorrowRestock(i.name)),
    ];
    if (lines.isEmpty) return Text(l10n.tomorrowNothing);
    return Column(
      children: [
        for (final (icon, text) in lines)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon),
            title: Text(text),
          ),
      ],
    );
  }
}

/// Counted cash: typed, or said ("ஐயாயிரத்து இருநூறு").
class _CountInput extends ConsumerStatefulWidget {
  const _CountInput({required this.onSave});

  final void Function(int cents) onSave;

  @override
  ConsumerState<_CountInput> createState() => _CountInputState();
}

class _CountInputState extends ConsumerState<_CountInput> {
  final _controller = TextEditingController();
  String? _error;
  bool _listening = false;
  StreamSubscription<SpeechEvent>? _sub;

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    _controller.dispose();
    super.dispose();
  }

  Future<void> _listen() async {
    final engine = ref.read(voiceEngineProvider(context.membership.shopId));
    final input = await engine.pick();
    if (input == null || !mounted) return;
    setState(() => _listening = true);
    await _sub?.cancel();
    _sub = input
        .listen(maxDuration: const Duration(seconds: 5))
        .listen(
          (event) {
            if (event is HeardSpeech) {
              final cents = const VoiceEntryParser()
                  .parse(event.text)
                  .amountCents;
              if (cents != null) {
                _controller.text = cents % 100 == 0
                    ? '${cents ~/ 100}'
                    : (cents / 100).toStringAsFixed(2);
              }
            }
          },
          onDone: () {
            if (mounted) setState(() => _listening = false);
          },
        );
  }

  void _save() {
    final money = Money.tryParse(_controller.text);
    if (money == null || money.isNegative) {
      setState(() => _error = AppLocalizations.of(context).errorAmount);
      return;
    }
    setState(() => _error = null);
    FocusScope.of(context).unfocus();
    widget.onSave(money.cents);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('count-amount'),
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: Theme.of(context).textTheme.headlineSmall,
                decoration: InputDecoration(
                  labelText: l10n.closeDayCountLabel,
                  errorText: _error,
                ),
                onSubmitted: (_) => _save(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              key: const ValueKey('count-mic'),
              iconSize: 28,
              tooltip: l10n.closeDaySayCount,
              onPressed: _listening ? null : _listen,
              icon: Icon(
                _listening
                    ? FluentIcons.mic_24_filled
                    : FluentIcons.mic_24_regular,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const ValueKey('count-save'),
          onPressed: _save,
          icon: const Icon(FluentIcons.calendar_checkmark_24_regular),
          label: Text(l10n.closeDaySave),
        ),
      ],
    );
  }
}
