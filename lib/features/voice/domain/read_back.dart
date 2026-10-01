import '../../ledger/domain/entry_type.dart';

/// What the phone says back before saving (PRD C1: spoken read-back).
///
/// Amounts stay as digits: the Tamil text-to-speech voice reads "1500" as
/// ஆயிரத்து ஐநூறு itself, more reliably than spelled-out words.
String readBackText({
  required String languageCode,
  required String customer,
  required int amountCents,
  required EntryType type,
}) {
  final rupees = amountCents ~/ 100;
  // A sale or expense has no customer to name.
  final who = customer.isEmpty ? '' : '$customer, ';
  final cents = amountCents % 100;
  if (languageCode == 'ta') {
    final money = cents == 0 ? '$rupees ரூபா' : '$rupees ரூபா $cents சதம்';
    final what = switch (type) {
      EntryType.credit => 'கடன்',
      EntryType.payment => 'பணம் வந்தது',
      EntryType.sale => 'விற்பனை',
      EntryType.discount => 'தள்ளுபடி',
      EntryType.expense || EntryType.purchase => 'செலவு',
    };
    return '$who$money $what. சரியா?';
  }
  final money = cents == 0 ? '$rupees rupees' : '$rupees rupees $cents cents';
  final what = switch (type) {
    EntryType.credit => 'credit',
    EntryType.payment => 'payment received',
    EntryType.sale => 'sale',
    EntryType.discount => 'discount',
    EntryType.expense || EntryType.purchase => 'expense',
  };
  return '$who$money $what. Is that right?';
}
