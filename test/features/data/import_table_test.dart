import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/features/data/domain/import_table.dart';
import 'package:shop_companion/features/data/presentation/import_store.dart';
import 'package:shop_companion/features/ledger/domain/models.dart';

Uint8List text(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  group('parseAmountCents', () {
    final cases = {
      '1500': 150000,
      'Rs. 1,500.00': 150000,
      'Rs.1,500.5': 150050,
      '1500 Dr': 150000,
      '500 Cr': -50000,
      '-500': -50000,
      '(500)': -50000,
      'ரூ. 250': 25000,
      'LKR 2,000': 200000,
      '': null,
      'abc': null,
      '1.234': null,
    };
    cases.forEach((input, cents) {
      test('"$input"', () => expect(parseAmountCents(input), cents));
    });
  });

  test('Khatabook-style workbook: title rows, get/give columns', () {
    final bytes = File('test/fixtures/khatabook_customers.xlsx')
        .readAsBytesSync();
    final table = readTable(bytes, 'Customers.xlsx')!;
    final map = guessColumns(table);
    expect(map.headerRow, 2);
    expect((map.name, map.phone, map.balance), (0, 1, null));
    expect((map.owes, map.advance), (2, 3));
    expect(candidatesFrom(table, map), const [
      ImportCandidate(
        name: 'Ravi',
        phone: '077 123 4567',
        balanceCents: 150000,
      ),
      ImportCandidate(
        name: 'முருகன் அண்ணை',
        phone: '0711234567',
        balanceCents: 225050,
      ),
      ImportCandidate(name: 'Kamala', balanceCents: -30000),
      ImportCandidate(name: '', phone: '0779999999', balanceCents: 10000),
    ]);
  });

  test('OkCredit-style CSV: BOM, semicolons, Dr/Cr balance', () {
    final table = readTable(
      text(
        '﻿Customer Name;Mobile;Balance\r\n'
        'Selvi;0771112222;"2,400 Dr"\r\n'
        'Kumar;;100 Cr\r\n',
      ),
      'okcredit.csv',
    )!;
    final map = guessColumns(table);
    expect((map.name, map.phone, map.balance), (0, 1, 2));
    expect(candidatesFrom(table, map).map((c) => c.balanceCents), [
      240000,
      -10000,
    ]);
    // Some apps show it from the customer's side.
    expect(candidatesFrom(table, map, flip: true).first.balanceCents, -240000);
  });

  test('no header row: first text and first number column', () {
    final table = readTable(text('Ravi,1500\nSelvi,200\n'), 'x.csv')!;
    final map = guessColumns(table);
    expect(map.headerRow, -1);
    expect(candidatesFrom(table, map).map((c) => c.name), ['Ravi', 'Selvi']);
  });

  test('a file that is not a table', () {
    expect(readTable(Uint8List.fromList([0x50, 0x4b, 1, 2]), 'x.xlsx'), isNull);
  });

  group('ImportStore', () {
    ImportStore store() => ImportStore(
      existing: const [Customer(id: 'r', name: 'Ravi', phone: '+94771234567')],
    );

    test('flags duplicates and nameless rows, unticked', () {
      final s = store()
        ..loadTable(
          readTable(
            File('test/fixtures/khatabook_customers.xlsx').readAsBytesSync(),
            'c.xlsx',
          )!,
        );
      expect(s.rows.value.map((r) => r.issue), [
        ImportIssue.duplicate,
        ImportIssue.none,
        ImportIssue.none,
        ImportIssue.noName,
      ]);
      expect(s.chosen.value.map((c) => c.name), ['முருகன் அண்ணை', 'Kamala']);
      // Advances don't count towards what is owed.
      expect(s.totalOwedCents.value, 225050);
      s.toggle(s.rows.value.first);
      expect(s.chosen.value, hasLength(3));
    });

    test('changing the balance column rebuilds the rows', () {
      final s = store()
        ..loadTable([
          ['Name', 'Old', 'New'],
          ['Anbu', '10', '20'],
        ]);
      expect(s.chosen.value.single.balanceCents, 1000);
      s.setColumns(s.columns.value!.copyWith(balance: () => 2));
      expect(s.chosen.value.single.balanceCents, 2000);
    });

    test('voice bulk entry adds a row per phrase', () {
      final s = store();
      expect(s.addSpoken('செல்வி அக்கா ஆயிரம்'), isTrue);
      expect(s.addSpoken('ஐநூறு'), isFalse);
      final row = s.spokenRows.single.candidate;
      expect(
        (row.name, row.kinship, row.balanceCents),
        ('செல்வி', 'akka', 100000),
      );
    });
  });
}
