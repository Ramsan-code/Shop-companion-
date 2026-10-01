import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:equatable/equatable.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

/// Switch-in import (PRD N2, US10): read a customer list exported from
/// Khatabook, OkCredit, Shopbook or any spreadsheet. Their layouts differ
/// and change, so columns are guessed from the header and the owner can
/// correct the guess in the preview; nothing is saved until they confirm.

/// Cells as text, first sheet only. Returns null when the file can't be
/// read as a spreadsheet or CSV.
List<List<String>>? readTable(Uint8List bytes, String fileName) {
  final lower = fileName.toLowerCase();
  try {
    if (lower.endsWith('.xlsx') || lower.endsWith('.ods')) {
      final book = SpreadsheetDecoder.decodeBytes(bytes);
      if (book.tables.isEmpty) return null;
      return [
        for (final row in book.tables.values.first.rows)
          [for (final cell in row) _cellText(cell)],
      ];
    }
    var text = utf8.decode(bytes, allowMalformed: true);
    if (text.startsWith('﻿')) text = text.substring(1);
    return [
      for (final row in Csv().decode(text))
        [for (final cell in row) _cellText(cell)],
    ];
  } on Object {
    return null;
  }
}

String _cellText(Object? cell) => switch (cell) {
  null => '',
  final double d when d == d.roundToDouble() => d.toInt().toString(),
  _ => cell.toString().trim(),
};

/// Which column holds what. A balance is either one signed column, or a
/// "you will get" (owes) column and a "you will give" (advance) column.
class ColumnMap extends Equatable {
  const ColumnMap({
    this.headerRow = 0,
    this.name,
    this.phone,
    this.balance,
    this.owes,
    this.advance,
  });

  final int headerRow;
  final int? name;
  final int? phone;
  final int? balance;
  final int? owes;
  final int? advance;

  ColumnMap copyWith({
    int? Function()? name,
    int? Function()? phone,
    int? Function()? balance,
  }) => ColumnMap(
    headerRow: headerRow,
    name: name == null ? this.name : name(),
    phone: phone == null ? this.phone : phone(),
    balance: balance == null ? this.balance : balance(),
    // Choosing a single balance column replaces the split ones.
    owes: balance == null ? owes : null,
    advance: balance == null ? advance : null,
  );

  @override
  List<Object?> get props => [headerRow, name, phone, balance, owes, advance];
}

const _nameHeaders = [
  'name',
  'customer name',
  'customer',
  'party name',
  'party',
  'contact name',
  'பெயர்',
  'வாடிக்கையாளர்',
];
const _phoneHeaders = [
  'phone',
  'phone number',
  'mobile',
  'mobile number',
  'contact',
  'contact number',
  'number',
  'தொலைபேசி',
];
const _balanceHeaders = [
  'balance',
  'net balance',
  'closing balance',
  'balance amount',
  'due',
  'amount due',
  'outstanding',
  'amount',
  'நிலுவை',
];
const _owesHeaders = [
  'you will get',
  "you'll get",
  'will get',
  'to collect',
  'receivable',
  'to receive',
  'get',
];
const _advanceHeaders = [
  'you will give',
  "you'll give",
  'will give',
  'to pay',
  'payable',
  'advance',
  'give',
];

String _norm(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r"[^a-z\u0B80-\u0BFF\s']"), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

int? _find(List<String> header, List<String> names) {
  final cells = header.map(_norm).toList();
  // Exact header first, then a header that starts with the word.
  for (final n in names) {
    final i = cells.indexOf(n);
    if (i >= 0) return i;
  }
  for (final n in names) {
    final i = cells.indexWhere((c) => c.startsWith('$n '));
    if (i >= 0) return i;
  }
  return null;
}

/// Finds the header row (exports often start with a title or the shop name)
/// and the columns under it.
ColumnMap guessColumns(List<List<String>> table) {
  for (var r = 0; r < table.length && r < 10; r++) {
    final header = table[r];
    final name = _find(header, _nameHeaders);
    if (name == null) continue;
    final owes = _find(header, _owesHeaders);
    final advance = _find(header, _advanceHeaders);
    final split = owes != null && advance != null;
    final phone = _find(header, _phoneHeaders);
    return ColumnMap(
      headerRow: r,
      name: name,
      phone: phone,
      balance: split
          ? null
          : _find(header, _balanceHeaders) ??
                owes ??
                _amountColumn(table, r + 1, skip: {name, ?phone}),
      owes: split ? owes : null,
      advance: split ? advance : null,
    );
  }
  // No header: first text column is the name, first number column the balance.
  final first = table.isEmpty ? const <String>[] : table.first;
  final name = first.indexWhere(
    (c) => c.isNotEmpty && parseAmountCents(c) == null,
  );
  final balance = first.indexWhere((c) => parseAmountCents(c) != null);
  return ColumnMap(
    headerRow: -1,
    name: name < 0 ? null : name,
    balance: balance < 0 ? null : balance,
  );
}

/// The first column whose values under [from] read as amounts and not as
/// phone numbers, for headers we don't recognise.
int? _amountColumn(
  List<List<String>> table,
  int from, {
  Set<int> skip = const {},
}) {
  final rows = table
      .skip(from)
      .take(20)
      .where((r) => r.any((c) => c.isNotEmpty));
  if (rows.isEmpty) return null;
  final width = rows.fold<int>(0, (w, r) => r.length > w ? r.length : w);
  for (var c = 0; c < width; c++) {
    if (skip.contains(c)) continue;
    final values = [
      for (final r in rows)
        if (c < r.length && r[c].isNotEmpty) r[c],
    ];
    if (values.isNotEmpty &&
        values.every(
          (v) => parseAmountCents(v) != null && !_looksLikePhone(v),
        )) {
      return c;
    }
  }
  return null;
}

bool _looksLikePhone(String v) =>
    RegExp(r'^(\+94|0094|94|0)?7\d{8}$')
        .hasMatch(v.replaceAll(RegExp(r'[\s\-()]'), ''));

/// "Rs. 1,500.00", "1500 Dr", "500 Cr", "-500", "(500)", "₹ 1,200" → cents.
/// Dr (debit) means the customer owes; Cr (credit) means paid in advance.
int? parseAmountCents(String raw) {
  var s = raw.trim().toLowerCase();
  if (s.isEmpty) return null;
  var sign = 1;
  if (s.endsWith('cr')) {
    sign = -1;
    s = s.substring(0, s.length - 2);
  } else if (s.endsWith('dr')) {
    s = s.substring(0, s.length - 2);
  }
  if (s.startsWith('(') && s.endsWith(')')) {
    sign = -sign;
    s = s.substring(1, s.length - 1);
  }
  s = s.replaceAll(RegExp(r'rs\.?|lkr|₹|රු|ரூ\.?|,|\s'), '');
  if (s.startsWith('-')) {
    sign = -sign;
    s = s.substring(1);
  } else if (s.startsWith('+')) {
    s = s.substring(1);
  }
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(s)) return null;
  final parts = s.split('.');
  final cents =
      int.parse(parts[0]) * 100 +
      (parts.length > 1 ? int.parse(parts[1].padRight(2, '0')) : 0);
  return sign * cents;
}

/// One customer to bring in.
class ImportCandidate extends Equatable {
  const ImportCandidate({
    required this.name,
    this.phone,
    this.kinship,
    this.balanceCents = 0,
  });

  final String name;
  final String? phone;

  /// Canonical kinship word, when it came from speech.
  final String? kinship;

  /// Positive: the customer owes the shop.
  final int balanceCents;

  @override
  List<Object?> get props => [name, phone, kinship, balanceCents];
}

/// Rows under the header as candidates (empty rows skipped). [flip] swaps
/// the sign for apps that show balances from the customer's side.
List<ImportCandidate> candidatesFrom(
  List<List<String>> table,
  ColumnMap map, {
  bool flip = false,
}) {
  String cell(List<String> row, int? i) =>
      i == null || i >= row.length ? '' : row[i].trim();
  final out = <ImportCandidate>[];
  for (var r = map.headerRow + 1; r < table.length; r++) {
    final row = table[r];
    if (row.every((c) => c.trim().isEmpty)) continue;
    var cents = 0;
    if (map.balance != null) {
      cents = parseAmountCents(cell(row, map.balance)) ?? 0;
    } else {
      cents =
          (parseAmountCents(cell(row, map.owes))?.abs() ?? 0) -
          (parseAmountCents(cell(row, map.advance))?.abs() ?? 0);
    }
    final phone = cell(row, map.phone);
    out.add(
      ImportCandidate(
        name: cell(row, map.name),
        phone: phone.isEmpty ? null : phone,
        balanceCents: flip ? -cents : cents,
      ),
    );
  }
  return out;
}
