import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// An LKR amount stored as integer cents (LKR × 100), as in Firestore (PRD 10).
///
/// Doubles never hold money: parsing and arithmetic stay in integers.
class Money extends Equatable implements Comparable<Money> {
  const Money(this.cents);

  const Money.zero() : cents = 0;

  factory Money.rupees(int rupees) => Money(rupees * 100);

  final int cents;

  /// Parses user or voice input like `500`, `1,250.5`, `Rs. 1,250.50`.
  /// Returns null for anything that isn't a plain non-negative amount.
  static Money? tryParse(String input) {
    final cleaned = input
        .replaceAll(
          RegExp(r'(?:rs\.?|ரூபா|ரூ\.?|lkr)', caseSensitive: false),
          '',
        )
        .replaceAll(',', '')
        .trim();
    final match = RegExp(r'^(\d{1,12})(?:\.(\d{1,2}))?$').firstMatch(cleaned);
    if (match == null) return null;
    final rupees = int.parse(match.group(1)!);
    final fraction = (match.group(2) ?? '').padRight(2, '0');
    return Money(rupees * 100 + int.parse(fraction));
  }

  Money operator +(Money other) => Money(cents + other.cents);
  Money operator -(Money other) => Money(cents - other.cents);

  bool operator <(Money other) => cents < other.cents;
  bool operator <=(Money other) => cents <= other.cents;
  bool operator >(Money other) => cents > other.cents;
  bool operator >=(Money other) => cents >= other.cents;

  Money abs() => Money(cents.abs());

  bool get isZero => cents == 0;
  bool get isNegative => cents < 0;

  /// `Rs. 1,250.00`. Sri Lanka groups by thousands in both Tamil and English,
  /// so grouping always uses the `en` pattern (the `ta` locale groups in lakhs).
  String format({bool showCents = true}) {
    final formatter = NumberFormat.decimalPatternDigits(
      locale: 'en',
      decimalDigits: showCents ? 2 : 0,
    );
    final abs = cents.abs();
    final value = showCents ? abs / 100 : abs ~/ 100;
    return '${isNegative ? '-' : ''}Rs. ${formatter.format(value)}';
  }

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);

  @override
  List<Object?> get props => [cents];

  @override
  String toString() => format();
}
