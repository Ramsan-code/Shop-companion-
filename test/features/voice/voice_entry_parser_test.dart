import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/features/voice/domain/entry_type.dart';
import 'package:shop_companion/features/voice/domain/tamil_numbers.dart';
import 'package:shop_companion/features/voice/domain/voice_benchmark.dart';
import 'package:shop_companion/features/voice/domain/voice_entry_parser.dart';

void main() {
  const parser = VoiceEntryParser();

  group('VoiceEntryParser', () {
    test('parses the PRD example "Ravi annai 500 kadan"', () {
      expect(
        parser.parse('Ravi annai 500 kadan'),
        const ParsedEntry(
          customerName: 'Ravi',
          kinshipTerm: 'annai',
          amountCents: 50000,
          type: EntryType.credit,
        ),
      );
    });

    test('parses Tamil script with number words', () {
      final p = parser.parse('ரவி அண்ணை ஐநூறு கடன்');
      expect(p.customerName, 'ரவி');
      expect(p.kinshipTerm, 'annai');
      expect(p.amountCents, 50000);
      expect(p.type, EntryType.credit);
      expect(p.isComplete, isTrue);
    });

    test('combines compound number words', () {
      expect(parser.parse('ஆயிரத்து ஐநூறு').amountCents, 150000);
      expect(parser.parse('rendu aayiram anjooru').amountCents, 250000);
      expect(parser.parse('2 ஆயிரம்').amountCents, 200000);
    });

    test('keeps rupees and cents in integers', () {
      expect(parser.parse('Kala 1,250.50 kattinar').amountCents, 125050);
      expect(parser.parse('Rs.75 Siva').amountCents, 7500);
    });

    test('strips the dative suffix from names', () {
      expect(parser.parse('ravikku 100 kadan').customerName, 'Ravi');
      expect(parser.parse('ரவிக்கு 100 கடன்').customerName, 'ரவி');
    });

    test('flags two separate amounts as ambiguous', () {
      final p = parser.parse('Ravi 500 Kumar 200 kadan');
      expect(p.ambiguousAmount, isTrue);
      expect(p.amountCents, 50000);
    });

    test('leaves unknown parts empty instead of guessing', () {
      final p = parser.parse('Ravi annai');
      expect(p.amountCents, isNull);
      expect(p.type, isNull);
      expect(p.isComplete, isFalse);
      expect(parser.parse('').customerName, isNull);
    });
  });

  group('combineNumberValues', () {
    test('handles multipliers', () {
      expect(combineNumberValues([5, 100]), 500);
      expect(combineNumberValues([1, 100, 50]), 150);
      expect(combineNumberValues([20, 1000]), 20000);
      expect(combineNumberValues([2, 100000, 50, 1000]), 250000);
    });
  });

  test('synthetic benchmark fixtures all pass', () {
    final report = VoiceBenchmark.run(
      File('test/fixtures/voice_phrases.csv').readAsStringSync(),
    );
    expect(report.total, greaterThanOrEqualTo(15));
    expect(report.misses, isEmpty, reason: report.describe());
    expect(report.meetsTargets, isTrue);
  });
}
