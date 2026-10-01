import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/money.dart';
import '../domain/models.dart';
import 'labels.dart';

class ReceiptData {
  const ReceiptData({
    required this.shopName,
    required this.customer,
    required this.amount,
    required this.method,
    required this.date,
    required this.balanceAfter,
    required this.receiptNo,
  });

  final String shopName;
  final String customer;
  final Money amount;
  final PaymentMethod method;
  final DateTime date;
  final Money balanceAfter;

  /// The entry's clientId; the first 8 characters are printed.
  final String receiptNo;
}

/// Payment receipt shared as an image (PRD C3) through the Android share
/// sheet or WhatsApp. An image, not a PDF: Flutter's text engine shapes
/// Tamil correctly, and PDF libraries without a shaper break vowel signs.
class ReceiptDialog extends StatelessWidget {
  ReceiptDialog({super.key, required this.data});

  final ReceiptData data;
  final _boundary = GlobalKey();

  static Future<void> show(BuildContext context, ReceiptData data) =>
      showDialog<void>(
        context: context,
        builder: (_) => ReceiptDialog(data: data),
      );

  Future<void> _share(BuildContext context) async {
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (png == null) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            png.buffer.asUint8List(),
            mimeType: 'image/png',
            name: 'receipt-${data.receiptNo.substring(0, 8)}.png',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      contentPadding: const EdgeInsets.all(12),
      content: RepaintBoundary(
        key: _boundary,
        child: ReceiptCard(data: data),
      ),
      actions: [
        TextButton(
          key: const ValueKey('receipt-close'),
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
        FilledButton(
          onPressed: () => _share(context),
          child: Text(l10n.shareReceipt),
        ),
      ],
    );
  }
}

class ReceiptCard extends StatelessWidget {
  const ReceiptCard({super.key, required this.data});

  final ReceiptData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Fixed light colours: the image is read on other people's phones.
    const ink = Color(0xFF1B1B1B);
    final small = theme.textTheme.bodyMedium!.copyWith(color: ink);
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: small)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: small.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            data.shopName,
            style: theme.textTheme.titleLarge!.copyWith(color: ink),
            textAlign: TextAlign.center,
          ),
          Text(l10n.receiptTitle, style: small, textAlign: TextAlign.center),
          const Divider(height: 24),
          Text(
            data.amount.format(),
            style: theme.textTheme.headlineMedium!.copyWith(
              color: const Color(0xFF0B6E4F),
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          row(l10n.receiptFrom, data.customer),
          row(l10n.receiptMethod, data.method.label(l10n)),
          row(
            l10n.dateLabel,
            DateFormat.yMMMd(l10n.localeName).format(data.date),
          ),
          row(l10n.receiptBalance, data.balanceAfter.format()),
          row(l10n.receiptNo, data.receiptNo.substring(0, 8).toUpperCase()),
        ],
      ),
    );
  }
}
