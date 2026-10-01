import 'package:flutter/material.dart';

import '../../../app/l10n/app_localizations.dart';
import '../domain/collections.dart';

extension TrustBandLabel on TrustBand {
  String label(AppLocalizations l10n) => switch (this) {
    TrustBand.excellent => l10n.bandExcellent,
    TrustBand.good => l10n.bandGood,
    TrustBand.watch => l10n.bandWatch,
    TrustBand.risky => l10n.bandRisky,
  };

  Color color(ColorScheme scheme) => switch (this) {
    TrustBand.excellent => const Color(0xFF1B7F3B),
    TrustBand.good => scheme.primary,
    TrustBand.watch => const Color(0xFFB26A00),
    TrustBand.risky => scheme.error,
  };
}

/// The plain reason shown with every score (PRD D1: "plain reason shown").
String reasonText(AppLocalizations l10n, TrustReason r) {
  final v = r.value ?? 0;
  return switch (r.code) {
    'newCustomer' => l10n.reasonNewCustomer,
    'overdue' => l10n.reasonOverdue(v),
    'regularPayer' => l10n.reasonRegularPayer(v),
    'noRecentPayment' => l10n.reasonNoRecentPayment,
    'paysMost' => l10n.reasonPaysMost(v),
    'paysLittle' => l10n.reasonPaysLittle(v),
    'highBalance' => l10n.reasonHighBalance,
    'longCustomer' => l10n.reasonLongCustomer(v),
    'settled' => l10n.reasonSettled,
    'payDay' => l10n.reasonPayDay(v),
    _ => '',
  };
}

class TrustBandChip extends StatelessWidget {
  const TrustBandChip({super.key, required this.band, this.score});

  final TrustBand band;
  final int? score;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = band.color(Theme.of(context).colorScheme);
    return Chip(
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color),
      label: Text(
        score == null
            ? band.label(l10n)
            : '${band.label(l10n)} · ${l10n.trustScoreLabel(score!)}',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
