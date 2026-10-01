import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../../../app/current_shop.dart';
import '../../../app/failure_message.dart';
import '../../../app/l10n/app_localizations.dart';
import '../../../core/di/providers.dart';
import '../../../core/rbac/permission.dart';
import '../../ledger/domain/models.dart';

extension ReminderToneLabel on ReminderTone {
  String label(AppLocalizations l10n) => switch (this) {
    ReminderTone.gentle => l10n.toneGentle,
    ReminderTone.normal => l10n.toneNormal,
    ReminderTone.firm => l10n.toneFirm,
  };
}

ToggleSwitch _toggle(
  BuildContext context, {
  required List<String> labels,
  required int index,
  required ValueChanged<int> onToggle,
  double minWidth = 80,
}) {
  final scheme = Theme.of(context).colorScheme;
  return ToggleSwitch(
    minHeight: 48,
    minWidth: minWidth,
    totalSwitches: labels.length,
    labels: labels,
    initialLabelIndex: index,
    activeBgColor: [scheme.primary],
    activeFgColor: scheme.onPrimary,
    inactiveBgColor: scheme.surfaceContainerHighest,
    inactiveFgColor: scheme.onSurface,
    onToggle: (i) => onToggle(i ?? index),
  );
}

/// Picks a tone; [allowDefault] adds "shop default" (null) first.
class ToneToggle extends StatelessWidget {
  const ToneToggle({
    super.key,
    required this.tone,
    required this.onChanged,
    this.allowDefault = false,
  });

  final ReminderTone? tone;
  final ValueChanged<ReminderTone?> onChanged;
  final bool allowDefault;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = <ReminderTone?>[
      if (allowDefault) null,
      ...ReminderTone.values,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: _toggle(
        context,
        labels: [
          for (final t in options)
            t == null ? l10n.toneShopDefault : t.label(l10n),
        ],
        index: options.indexOf(tone),
        onToggle: (i) => onChanged(options[i]),
      ),
    );
  }
}

/// Per-customer reminder settings in the customer form (PRD D3, US3, PDPA
/// consent). Shown to roles that can send reminders.
class RemindersSectionWidget extends ConsumerWidget {
  const RemindersSectionWidget({
    super.key,
    required this.customer,
    required this.consent,
    required this.tone,
    required this.lang,
    required this.onConsent,
    required this.onTone,
    required this.onLang,
  });

  final Customer? customer;
  final bool consent;
  final ReminderTone? tone;
  final ReminderLang lang;
  final ValueChanged<bool> onConsent;
  final ValueChanged<ReminderTone?> onTone;
  final ValueChanged<ReminderLang> onLang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!context.membership.role.can(Permission.reminderSend)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.reminderSection, style: theme.textTheme.titleSmall),
        SwitchListTile(
          key: const ValueKey('reminder-consent'),
          contentPadding: EdgeInsets.zero,
          value: consent,
          onChanged: onConsent,
          title: Text(l10n.reminderConsent),
          subtitle: Text(l10n.reminderConsentHelp),
        ),
        ToneToggle(tone: tone, onChanged: onTone, allowDefault: true),
        const SizedBox(height: 12),
        Text(l10n.reminderLanguage, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 4),
        _toggle(
          context,
          labels: const ['தமிழ்', 'English'],
          index: lang.index,
          minWidth: 120,
          onToggle: (i) => onLang(ReminderLang.values[i]),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: () => _preview(context, ref),
            child: Text(l10n.previewMessage),
          ),
        ),
      ],
    );
  }

  Future<void> _preview(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final c = customer;
    if (c == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.previewNeedsSave)));
      return;
    }
    final settings = await ref
        .read(remindersRepositoryProvider)
        .watchSettings(context.membership.shopId)
        .first;
    if (!context.mounted) return;
    final future = ref
        .read(remindersRepositoryProvider)
        .preview(context.membership.shopId, c.id, tone ?? settings.tone, lang)
        .run();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.previewMessage),
        content: FutureBuilder(
          future: future,
          builder: (context, snap) {
            final result = snap.data;
            if (result == null) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return result.match(
              (f) => Text(failureMessage(l10n, f)),
              (text) =>
                  SelectableText(text, key: const ValueKey('preview-text')),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
  }
}
