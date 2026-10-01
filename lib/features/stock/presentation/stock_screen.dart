import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/current_shop.dart';
import '../../../app/l10n/app_localizations.dart';
import '../../../core/di/providers.dart';
import '../../../core/money.dart';
import '../../../core/rbac/permission.dart';
import '../../../sync/sync_badge.dart';
import '../domain/stock.dart';

String formatQty(num qty) =>
    qty == qty.roundToDouble() ? '${qty.round()}' : qty.toStringAsFixed(1);

/// Basic stock (PRD C6): low-stock items first. Owner/Partner add and edit
/// items; a Helper only changes quantities with the − / + buttons.
class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final role = context.membership.role;
    final shopId = context.membership.shopId;
    final canManage = role.can(Permission.stockManage);
    final canCount = canManage || role.can(Permission.stockUpdateQty);
    final repo = ref.read(stockRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabStock), actions: const [SyncBadge()]),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              heroTag: 'stock-add',
              onPressed: () => StockItemSheet.show(context),
              icon: const Icon(FluentIcons.add_24_regular),
              label: Text(l10n.stockAdd),
            )
          : null,
      body: StreamBuilder<List<StockItem>>(
        stream: repo.watchItems(shopId),
        builder: (context, snap) {
          final items = snap.data;
          if (items == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.stockEmpty, textAlign: TextAlign.center),
              ),
            );
          }
          final low = items.where((i) => i.isLow).toList();
          final rest = items.where((i) => !i.isLow).toList();
          Widget row(StockItem i) => _StockRow(
            item: i,
            canCount: canCount,
            onTap: canManage
                ? () => StockItemSheet.show(context, item: i)
                : null,
            onChange: (delta) => repo.changeQty(
              shopId,
              i.id,
              delta,
              delta > 0 ? StockMoveReason.received : StockMoveReason.sold,
            ),
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
            children: [
              if (low.isNotEmpty) ...[
                _Header(
                  icon: FluentIcons.warning_24_regular,
                  text: '${l10n.stockLow} · ${l10n.stockLowCount(low.length)}',
                  color: theme.colorScheme.error,
                ),
                for (final i in low) row(i),
                const SizedBox(height: 12),
                _Header(text: l10n.stockAll),
              ],
              for (final i in rest) row(i),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.text, this.icon, this.color});

  final String text;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: color),
          ),
        ),
      ],
    ),
  );
}

class _StockRow extends StatelessWidget {
  const _StockRow({
    required this.item,
    required this.canCount,
    required this.onChange,
    this.onTap,
  });

  final StockItem item;
  final bool canCount;
  final void Function(num delta) onChange;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final qty = '${formatQty(item.qty)} ${item.unit ?? ''}'.trim();
    return Card(
      child: ListTile(
        key: ValueKey('stock-${item.id}'),
        minVerticalPadding: 12,
        onTap: onTap,
        title: Text(item.name),
        subtitle: Text(
          qty,
          style: theme.textTheme.titleMedium?.copyWith(
            color: item.isLow ? theme.colorScheme.error : null,
          ),
        ),
        trailing: canCount
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.outlined(
                    key: ValueKey('stock-minus-${item.id}'),
                    tooltip: l10n.stockTakeOne,
                    onPressed: () => onChange(-1),
                    icon: const Icon(FluentIcons.subtract_24_regular),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    key: ValueKey('stock-plus-${item.id}'),
                    tooltip: l10n.stockAddOne,
                    onPressed: () => onChange(1),
                    icon: const Icon(FluentIcons.add_24_regular),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}

/// Add or edit an item (Owner/Partner).
class StockItemSheet extends ConsumerStatefulWidget {
  const StockItemSheet({super.key, this.item});

  final StockItem? item;

  static Future<void> show(BuildContext context, {StockItem? item}) =>
      showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => StockItemSheet(item: item),
      );

  @override
  ConsumerState<StockItemSheet> createState() => _StockItemSheetState();
}

class _StockItemSheetState extends ConsumerState<StockItemSheet> {
  late final _name = TextEditingController(text: widget.item?.name);
  late final _unit = TextEditingController(text: widget.item?.unit);
  late final _qty = TextEditingController(
    text: widget.item == null ? '' : formatQty(widget.item!.qty),
  );
  late final _lowAt = TextEditingController(
    text: widget.item?.lowStockAt == null
        ? ''
        : formatQty(widget.item!.lowStockAt!),
  );
  late final _cost = TextEditingController(
    text: _rupees(widget.item?.costCents),
  );
  late final _price = TextEditingController(
    text: _rupees(widget.item?.priceCents),
  );
  bool _nameError = false;

  static String _rupees(int? cents) => cents == null
      ? ''
      : cents % 100 == 0
      ? '${cents ~/ 100}'
      : (cents / 100).toStringAsFixed(2);

  @override
  void dispose() {
    for (final c in [_name, _unit, _qty, _lowAt, _cost, _price]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) {
      setState(() => _nameError = true);
      return;
    }
    final draft = StockItemDraft(
      name: _name.text.trim(),
      unit: _unit.text.trim().isEmpty ? null : _unit.text.trim(),
      qty: num.tryParse(_qty.text.trim()) ?? 0,
      lowStockAt: num.tryParse(_lowAt.text.trim()),
      costCents: Money.tryParse(_cost.text)?.cents,
      priceCents: Money.tryParse(_price.text)?.cents,
    );
    final repo = ref.read(stockRepositoryProvider);
    final shopId = context.membership.shopId;
    final item = widget.item;
    final saved = item == null
        ? repo.addItem(shopId, draft).isRight()
        : repo.updateItem(shopId, item.id, draft).isRight();
    if (saved) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const number = TextInputType.numberWithOptions(decimal: true);
    Widget field(
      TextEditingController c,
      String label, {
      TextInputType? keyboard,
      String? error,
      Key? key,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        key: key,
        controller: c,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label, errorText: error),
      ),
    );
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
              widget.item == null ? l10n.stockAdd : l10n.stockEdit,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            field(
              _name,
              l10n.stockName,
              key: const ValueKey('stock-name'),
              error: _nameError ? l10n.errorCustomerName : null,
            ),
            Row(
              children: [
                Expanded(
                  child: field(
                    _qty,
                    l10n.stockQty,
                    keyboard: number,
                    key: const ValueKey('stock-qty'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: field(_unit, l10n.stockUnit)),
              ],
            ),
            field(
              _lowAt,
              l10n.stockLowAt,
              keyboard: number,
              key: const ValueKey('stock-low-at'),
            ),
            Row(
              children: [
                Expanded(child: field(_cost, l10n.stockCost, keyboard: number)),
                const SizedBox(width: 12),
                Expanded(
                  child: field(_price, l10n.stockPrice, keyboard: number),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const ValueKey('stock-save'),
              onPressed: _save,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
