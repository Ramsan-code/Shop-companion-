import 'dart:async';

import 'package:clock/clock.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide AsyncResult;
import 'package:go_router/go_router.dart';

import '../../../app/current_shop.dart';
import '../../../app/failure_message.dart';
import '../../../app/l10n/app_localizations.dart';
import '../../../core/di/providers.dart';
import '../../../core/failure.dart';
import '../../../core/file_sharer.dart';
import '../../../core/rbac/permission.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/session_cubit.dart';
import '../../close_day/domain/day_totals.dart';
import '../domain/data_rights.dart';

/// Your data and privacy (PRD N1, C9, N2; PDPA): export, dues report,
/// import, the privacy notice, and deleting the account or the shop.
class DataScreen extends ConsumerStatefulWidget {
  const DataScreen({super.key});

  @override
  ConsumerState<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends ConsumerState<DataScreen> {
  bool _busy = false;

  String get _here => GoRouterState.of(context).matchedLocation;

  void _show(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  String _refusal(AppLocalizations l10n, Failure f) => switch (f) {
    ValidationFailure(message: DataRefusal.nameMismatch) =>
      l10n.deleteShopMismatch,
    ValidationFailure(message: DataRefusal.deleteShopFirst) =>
      l10n.deleteAccountOwner,
    _ => failureMessage(l10n, f),
  };

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(dataRightsRepositoryProvider);
    final sharer = ref.read(fileSharerProvider);
    setState(() => _busy = true);
    final day = dayKey(clock.now());
    final result = await repo
        .exportShop(context.membership.shopId)
        .flatMap(
          (files) => repo
              .download(files.xlsxPath)
              .flatMap(
                (xlsx) => repo
                    .download(files.jsonPath)
                    .map((json) => (xlsx: xlsx, json: json)),
              ),
        )
        .run();
    if (!mounted) return;
    setState(() => _busy = false);
    await result.match((f) async => _show(_refusal(l10n, f)), (files) async {
      ref.read(telemetryProvider).exportDone();
      await sharer.share([
        SharedFile(
          files.xlsx,
          name: 'shop-companion-$day.xlsx',
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
        SharedFile(
          files.json,
          name: 'shop-companion-$day.json',
          mimeType: 'application/json',
        ),
      ]);
    });
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.deleteAccountConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('confirm-delete'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _run(ref.read(dataRightsRepositoryProvider).deleteMyAccount());
  }

  Future<void> _deleteShop() async {
    final l10n = AppLocalizations.of(context);
    final name = context.membership.shopName;
    final typed = await showDialog<String>(
      context: context,
      builder: (context) => _TypeToConfirm(name: name),
    );
    if (typed == null || !mounted) return;
    if (typed.trim() != name.trim()) {
      _show(l10n.deleteShopMismatch);
      return;
    }
    await _run(
      ref
          .read(dataRightsRepositoryProvider)
          .deleteShop(context.membership.shopId, confirmName: typed),
    );
  }

  /// Deletion succeeded: sign out; the router goes to the login screen.
  Future<void> _run(AsyncResult<Object> call) async {
    final l10n = AppLocalizations.of(context);
    final session = context.read<SessionCubit>();
    setState(() => _busy = true);
    final result = await call.run();
    if (!mounted) return;
    setState(() => _busy = false);
    await result.match(
      (f) async => _show(_refusal(l10n, f)),
      (_) => session.signOut(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Gone for a moment after deleting, before the router leaves this page.
    final session = context.watch<SessionCubit>().state;
    final membership = session is SignedIn ? session.membership : null;
    if (membership == null) return const Scaffold();
    final role = membership.role;
    final owner = role.can(Permission.shopManage);
    Widget tile({
      required IconData icon,
      required String title,
      String? subtitle,
      required VoidCallback? onTap,
      Key? key,
      Color? color,
    }) => ListTile(
      key: key,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(title, style: color == null ? null : TextStyle(color: color)),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: const Icon(FluentIcons.chevron_right_24_regular),
      onTap: _busy ? null : onTap,
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.dataTitle)),
      body: ListView(
        // Clear of the owner bar's raised mic button.
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
        children: [
          if (_busy) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(l10n.dataExporting),
          ],
          if (owner)
            tile(
              key: const ValueKey('data-export'),
              icon: FluentIcons.arrow_download_24_regular,
              title: l10n.dataExport,
              subtitle: l10n.dataExportHelp,
              onTap: _export,
            ),
          if (role.can(Permission.balanceRead) && !role.usesHelperShell)
            tile(
              key: const ValueKey('data-dues'),
              icon: FluentIcons.document_pdf_24_regular,
              title: l10n.duesReport,
              subtitle: l10n.duesReportHelp,
              onTap: () => context.go('$_here/dues'),
            ),
          if (owner && ref.read(featureFlagsProvider).importEnabled)
            tile(
              key: const ValueKey('data-import'),
              icon: FluentIcons.people_add_24_regular,
              title: l10n.importTitle,
              onTap: () => context.go('$_here/import'),
            ),
          tile(
            key: const ValueKey('data-privacy'),
            icon: FluentIcons.shield_lock_24_regular,
            title: l10n.privacyTitle,
            onTap: () => context.go('$_here/privacy'),
          ),
          const Divider(height: 32),
          tile(
            key: const ValueKey('data-delete-account'),
            icon: FluentIcons.person_delete_24_regular,
            title: l10n.deleteAccount,
            subtitle: l10n.deleteAccountHelp,
            onTap: _deleteAccount,
            color: theme.colorScheme.error,
          ),
          if (owner)
            tile(
              key: const ValueKey('data-delete-shop'),
              icon: FluentIcons.delete_24_regular,
              title: l10n.deleteShop,
              subtitle: l10n.deleteShopHelp,
              onTap: _deleteShop,
              color: theme.colorScheme.error,
            ),
        ],
      ),
    );
  }
}

/// The owner types the shop's name, so a shop is never deleted by a slip.
class _TypeToConfirm extends StatefulWidget {
  const _TypeToConfirm({required this.name});

  final String name;

  @override
  State<_TypeToConfirm> createState() => _TypeToConfirmState();
}

class _TypeToConfirmState extends State<_TypeToConfirm> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.deleteShop),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.deleteShopHelp),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('confirm-shop-name'),
            controller: _controller,
            decoration: InputDecoration(
              labelText: l10n.deleteShopConfirm(widget.name),
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
          key: const ValueKey('confirm-delete'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l10n.deleteConfirm),
        ),
      ],
    );
  }
}
