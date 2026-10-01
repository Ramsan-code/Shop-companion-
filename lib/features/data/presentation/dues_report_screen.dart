import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:clock/clock.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../app/current_shop.dart';
import '../../../app/l10n/app_localizations.dart';
import '../../../core/di/providers.dart';
import '../../../core/file_sharer.dart';
import '../../../core/money.dart';
import '../../close_day/domain/day_totals.dart';
import '../../ledger/domain/models.dart';
import '../../ledger/presentation/labels.dart';

/// Rows per A4 page.
const duesRowsPerPage = 26;

/// Dues report as a PDF (PRD C9: free Excel/PDF export). Pages are drawn by
/// Flutter, which shapes Tamil correctly, and placed in the PDF as images;
/// PDF text without a shaper breaks Tamil vowel signs.
class DuesReportScreen extends ConsumerWidget {
  const DuesReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.duesReport)),
      body: StreamBuilder<List<Customer>>(
        stream: ref
            .read(ledgerRepositoryProvider)
            .watchCustomers(context.membership.shopId),
        builder: (context, snap) {
          final customers = snap.data;
          if (customers == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final owing = customers.where((c) => c.balance.cents > 0).toList()
            ..sort((a, b) => b.balance.cents.compareTo(a.balance.cents));
          return _Pages(customers: owing);
        },
      ),
    );
  }
}

class _Pages extends ConsumerStatefulWidget {
  const _Pages({required this.customers});

  final List<Customer> customers;

  @override
  ConsumerState<_Pages> createState() => _PagesState();
}

class _PagesState extends ConsumerState<_Pages> {
  final _keys = <GlobalKey>[];
  bool _sharing = false;

  List<List<Customer>> get _pages {
    final pages = <List<Customer>>[];
    for (var i = 0; i < widget.customers.length; i += duesRowsPerPage) {
      pages.add(
        widget.customers.sublist(
          i,
          (i + duesRowsPerPage).clamp(0, widget.customers.length),
        ),
      );
    }
    return pages.isEmpty ? [const []] : pages;
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    final sharer = ref.read(fileSharerProvider);
    final pngs = <Uint8List>[];
    for (final key in _keys) {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.5);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data != null) pngs.add(data.buffer.asUint8List());
    }
    final pdf = await buildImagePdf(pngs);
    if (!mounted) return;
    setState(() => _sharing = false);
    await sharer.share([
      SharedFile(
        pdf,
        name: 'dues-${dayKey(clock.now())}.pdf',
        mimeType: 'application/pdf',
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = _pages;
    while (_keys.length < pages.length) {
      _keys.add(GlobalKey());
    }
    final total = widget.customers.fold<int>(0, (s, c) => s + c.balance.cents);
    return Column(
      children: [
        Expanded(
          // Every page is built (not lazily) so all can be captured.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                for (var i = 0; i < pages.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RepaintBoundary(
                      key: _keys[i],
                      child: _Page(
                        shopName: context.membership.shopName,
                        rows: pages[i],
                        firstNo: i * duesRowsPerPage + 1,
                        page: i + 1,
                        pages: pages.length,
                        summary: i == 0
                            ? l10n.duesTotal(
                                widget.customers.length,
                                Money(total).format(showCents: false),
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              key: const ValueKey('share-pdf'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _sharing ? null : _share,
              icon: const Icon(FluentIcons.share_24_regular),
              label: Text(l10n.sharePdf),
            ),
          ),
        ),
      ],
    );
  }
}

/// One A4 page, always light (it is printed).
class _Page extends StatelessWidget {
  const _Page({
    required this.shopName,
    required this.rows,
    required this.firstNo,
    required this.page,
    required this.pages,
    this.summary,
  });

  final String shopName;
  final List<Customer> rows;
  final int firstNo;
  final int page;
  final int pages;
  final String? summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const ink = Color(0xFF1B1B1B);
    const style = TextStyle(color: ink, fontSize: 11);
    final date = DateFormat('yyyy-MM-dd').format(clock.now());
    return AspectRatio(
      aspectRatio: PdfPageFormat.a4.width / PdfPageFormat.a4.height,
      child: Container(
        color: const Color(0xFFFFFFFF),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: DefaultTextStyle(
          style: style,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.duesReportTitle(shopName, date),
                style: style.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (summary != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(summary!),
                ),
              const Divider(color: ink),
              for (var i = 0; i < rows.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(width: 28, child: Text('${firstNo + i}.')),
                      Expanded(
                        child: Text(
                          customerTitle(l10n, rows[i]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: 96,
                        child: Text(
                          rows[i].phone ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                        ),
                      ),
                      Text(rows[i].balance.format(showCents: false)),
                    ],
                  ),
                ),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: Text(l10n.pageOf(page, pages)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A PDF with one full-page A4 image per page.
Future<Uint8List> buildImagePdf(List<Uint8List> pngs) {
  final doc = pw.Document(producer: 'Shop Companion');
  for (final png in pngs) {
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Image(pw.MemoryImage(png), fit: pw.BoxFit.contain),
      ),
    );
  }
  return doc.save();
}
