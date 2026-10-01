import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/current_shop.dart';
import '../../../app/failure_message.dart';
import '../../../app/l10n/app_localizations.dart';
import '../../../core/di/providers.dart';
import '../../../core/rbac/permission.dart';
import '../../ledger/domain/models.dart';
import '../../ledger/presentation/labels.dart';
import '../domain/reminders.dart';
import 'reminder_widgets.dart';

/// Reminders (PRD C7, D3, D8): the owner's settings and LankaQR, reminders
/// waiting for approval, and what was sent and what happened to it.
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final shopId = context.membership.shopId;
    final repo = ref.read(remindersRepositoryProvider);
    final canManage = context.membership.role.can(Permission.shopManage);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.remindersTitle)),
      body: StreamBuilder<List<Customer>>(
        stream: ref.read(ledgerRepositoryProvider).watchCustomers(shopId),
        builder: (context, customersSnap) {
          final names = {
            for (final c in customersSnap.data ?? const <Customer>[])
              c.id: customerTitle(l10n, c),
          };
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              if (canManage)
                StreamBuilder<ReminderSettings>(
                  stream: repo.watchSettings(shopId),
                  builder: (context, snap) => snap.data == null
                      ? const SizedBox.shrink()
                      : _SettingsCard(settings: snap.data!),
                ),
              StreamBuilder<List<Reminder>>(
                stream: repo.watchReminders(shopId),
                builder: (context, snap) => _ReminderLists(
                  reminders: snap.data ?? const [],
                  names: names,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsCard extends ConsumerWidget {
  const _SettingsCard({required this.settings});

  final ReminderSettings settings;

  void _update(BuildContext context, WidgetRef ref, ReminderSettings next) =>
      ref
          .read(remindersRepositoryProvider)
          .updateSettings(context.membership.shopId, next);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final payload = settings.lankaQrPayload;
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              key: const ValueKey('auto-reminders'),
              contentPadding: EdgeInsets.zero,
              value: settings.autoReminders,
              onChanged: settings.planAllowsAutomatic
                  ? (v) => _update(
                      context,
                      ref,
                      settings.copyWith(autoReminders: v),
                    )
                  : null,
              title: Text(l10n.autoReminders),
              subtitle: Text(
                settings.planAllowsAutomatic
                    ? l10n.autoRemindersHelp
                    : l10n.remindersPlanNote,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.approvalMode,
              onChanged: (v) =>
                  _update(context, ref, settings.copyWith(approvalMode: v)),
              title: Text(l10n.approvalMode),
            ),
            Text(l10n.defaultTone, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            ToneToggle(
              tone: settings.tone,
              onChanged: (t) => _update(
                context,
                ref,
                settings.copyWith(tone: t ?? ReminderTone.gentle),
              ),
            ),
            const Divider(height: 32),
            Text(l10n.lankaQrTitle, style: theme.textTheme.titleMedium),
            Text(l10n.lankaQrHelp, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            if (payload == null)
              Text(l10n.lankaQrNotSet)
            else
              Center(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(8),
                  child: QrImageView(
                    key: const ValueKey('lankaqr-preview'),
                    data: payload,
                    size: 180,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final scanned = await Navigator.of(context).push<String>(
                  MaterialPageRoute(builder: (_) => const ScanLankaQrScreen()),
                );
                if (scanned != null && context.mounted) {
                  _update(
                    context,
                    ref,
                    settings.copyWith(lankaQrPayload: scanned),
                  );
                }
              },
              icon: const Icon(FluentIcons.scan_qr_code_24_regular),
              label: Text(l10n.scanLankaQr),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderLists extends ConsumerWidget {
  const _ReminderLists({required this.reminders, required this.names});

  final List<Reminder> reminders;
  final Map<String, String> names;

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    List<String> ids, {
    required bool approve,
  }) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(remindersRepositoryProvider)
        .decide(context.membership.shopId, ids, approve: approve)
        .run();
    result.match(
      (f) => messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, f))),
      ),
      (_) {},
    );
  }

  String _status(AppLocalizations l10n, Reminder r) {
    final label = switch (r.status) {
      ReminderStatus.pendingApproval => l10n.statusPending,
      ReminderStatus.queued => l10n.statusQueued,
      ReminderStatus.sent => l10n.statusSent,
      ReminderStatus.delivered => l10n.statusDelivered,
      ReminderStatus.read => l10n.statusRead,
      ReminderStatus.failed => l10n.statusFailed,
      ReminderStatus.skipped => l10n.statusSkipped,
      ReminderStatus.cancelled => l10n.statusCancelled,
    };
    return r.channel == 'sms' ? '$label · ${l10n.viaSms}' : label;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pending = reminders
        .where((r) => r.status == ReminderStatus.pendingApproval)
        .toList();
    final recent = reminders
        .where((r) => r.status != ReminderStatus.pendingApproval)
        .toList();
    final date = DateFormat.MMMd(l10n.localeName);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pending.isNotEmpty) ...[
          ListTile(
            title: Text(
              l10n.pendingApproval,
              style: theme.textTheme.titleMedium,
            ),
            trailing: FilledButton(
              key: const ValueKey('approve-all'),
              onPressed: () => _decide(context, ref, [
                for (final r in pending) r.id,
              ], approve: true),
              child: Text(l10n.approveAll),
            ),
          ),
          for (final r in pending)
            ListTile(
              title: Text(names[r.customerId] ?? '…'),
              trailing: Wrap(
                spacing: 4,
                children: [
                  TextButton(
                    onPressed: () =>
                        _decide(context, ref, [r.id], approve: false),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton.tonal(
                    onPressed: () =>
                        _decide(context, ref, [r.id], approve: true),
                    child: Text(l10n.approve),
                  ),
                ],
              ),
            ),
        ],
        ListTile(
          title: Text(l10n.recentReminders, style: theme.textTheme.titleMedium),
        ),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(l10n.noReminders),
          ),
        for (final r in recent)
          ListTile(
            title: Text(names[r.customerId] ?? '…'),
            subtitle: Text(_status(l10n, r)),
            trailing: Text(
              date.format(r.sentAt ?? r.createdAt ?? DateTime.now()),
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

/// Scans the shop's LankaQR sticker once (PRD D8).
class ScanLankaQrScreen extends StatefulWidget {
  const ScanLankaQrScreen({super.key});

  @override
  State<ScanLankaQrScreen> createState() => _ScanLankaQrScreenState();
}

class _ScanLankaQrScreenState extends State<ScanLankaQrScreen> {
  bool _done = false;
  String? _error;

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    final l10n = AppLocalizations.of(context);
    for (final code in capture.barcodes) {
      final value = code.rawValue;
      if (value == null) continue;
      if (looksLikeLankaQr(value)) {
        _done = true;
        Navigator.pop(context, value);
        return;
      }
      setState(() => _error = l10n.lankaQrInvalid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanLankaQr)),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          if (_error != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 32,
              child: Material(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error!),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
