import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/current_shop.dart';
import '../../../app/l10n/app_localizations.dart';
import '../../../app/router.dart';
import '../../../core/di/providers.dart';
import '../../../core/rbac/permission.dart';
import '../../voice/presentation/voice_entry_sheet.dart';
import '../domain/entry_type.dart';
import 'entry_screen.dart';
import 'quick_entry_sheet.dart';

/// Low-literacy mode (PRD N10): big pictures, few words, and a speaker on
/// every tile that says what it does.
class SimpleHome extends ConsumerWidget {
  const SimpleHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final role = context.membership.role;
    final ownerShell = !role.usesHelperShell;
    final readBack = ref.read(readBackProvider);
    final tiles = <_Tile>[
      _Tile(
        FluentIcons.mic_24_filled,
        l10n.tabMic,
        l10n.helpMic,
        () => VoiceEntrySheet.show(context),
      ),
      _Tile(
        FluentIcons.add_circle_24_regular,
        l10n.typeCredit,
        l10n.helpCredit,
        () => CustomerPicker.show(context, EntryType.credit),
      ),
      _Tile(
        FluentIcons.money_24_regular,
        l10n.typePayment,
        l10n.helpPayment,
        () => CustomerPicker.show(context, EntryType.payment),
      ),
      _Tile(
        FluentIcons.cart_24_regular,
        l10n.typeSale,
        l10n.helpSale,
        () => QuickEntrySheet.show(context, sale: true),
      ),
      if (role.can(Permission.ledgerCreateExpense))
        _Tile(
          FluentIcons.wallet_24_regular,
          l10n.typeExpense,
          l10n.helpExpense,
          () => QuickEntrySheet.show(context, sale: false),
        ),
      _Tile(
        FluentIcons.calendar_checkmark_24_regular,
        l10n.tabCloseDay,
        l10n.helpCloseDay,
        () => context.go(ownerShell ? Routes.ownerCloseDay : Routes.closeDay),
      ),
      _Tile(
        FluentIcons.box_24_regular,
        l10n.tabStock,
        l10n.helpStock,
        () => context.go(ownerShell ? Routes.stock : Routes.helperStock),
      ),
    ];
    return GridView.count(
      // Sits inside the page's own list.
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(4),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: [
        for (final t in tiles)
          _SimpleTile(
            tile: t,
            onHear: () => readBack.speak(t.help, languageCode: l10n.localeName),
          ),
      ],
    );
  }
}

class _Tile {
  const _Tile(this.icon, this.label, this.help, this.onTap);

  final IconData icon;
  final String label;
  final String help;
  final VoidCallback onTap;
}

class _SimpleTile extends StatelessWidget {
  const _SimpleTile({required this.tile, required this.onHear});

  final _Tile tile;
  final VoidCallback onHear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: tile.onTap,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tile.icon, size: 56, color: scheme.onPrimaryContainer),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      tile.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                tooltip: l10n.hearThis,
                onPressed: onHear,
                icon: const Icon(FluentIcons.speaker_2_24_regular),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
