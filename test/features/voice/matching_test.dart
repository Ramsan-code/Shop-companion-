import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/features/ledger/domain/entry_type.dart';
import 'package:shop_companion/features/ledger/domain/models.dart';
import 'package:shop_companion/features/voice/domain/confirmation.dart';
import 'package:shop_companion/features/voice/domain/customer_matcher.dart';
import 'package:shop_companion/features/voice/domain/phonetic.dart';
import 'package:shop_companion/features/voice/domain/read_back.dart';

void main() {
  group('phoneticKey: Tamil script and romanisations agree', () {
    for (final (tamil, latin) in [
      ('ரவி', 'Ravi'),
      ('ரவி', 'Ravee'),
      ('குமார்', 'Kumar'),
      ('செல்வி', 'Selvi'),
      ('முருகன்', 'Murugan'),
      ('கண்ணன்', 'Kannan'),
      ('அருண்', 'Arun'),
      ('விஜய்', 'Vijay'),
      ('சித்ரா', 'Chitra'),
      ('தங்கராசா', 'Thangarasa'),
      ('செல்வராசா', 'Selvarasa'),
      ('சங்கீதா', 'Sangeetha'),
      ('அஞ்சலி', 'Anjali'),
    ]) {
      test(
        '$tamil = $latin',
        () => expect(phoneticKey(tamil), phoneticKey(latin)),
      );
    }

    test('different names differ', () {
      expect(phoneticKey('Ravi'), isNot(phoneticKey('Raja')));
      expect(phoneticKey('Kumar'), isNot(phoneticKey('Kamal')));
    });

    test('a key per word for multi-word names', () {
      expect(
        phoneticKeys('Ravi Kumar'),
        containsAll([phoneticKey('Ravi'), phoneticKey('Kumar')]),
      );
    });
  });

  group('CustomerMatcher', () {
    const ravi = Customer(id: 'ravi', name: 'Ravi', kinship: Kinship.annai);
    const raviT = Customer(id: 'ravi-t', name: 'Ravi', kinship: Kinship.thambi);
    const kumar = Customer(id: 'kumar', name: 'Kumar');
    const selvi = Customer(id: 'selvi', name: 'செல்வி', kinship: Kinship.akka);
    const matcher = CustomerMatcher();

    test('Tamil heard name finds a Latin-saved customer, and the reverse', () {
      expect(matcher.autoPick(matcher.rank('ரவி', const [ravi, kumar])), ravi);
      expect(
        matcher.autoPick(matcher.rank('Selvi', const [selvi, kumar])),
        selvi,
      );
    });

    test('the kinship word separates two customers with the same name', () {
      final ranked = matcher.rank('Ravi', const [
        ravi,
        raviT,
      ], heardKinship: Kinship.thambi);
      expect(matcher.autoPick(ranked), raviT);
    });

    test('ambiguous names are not auto-picked but offered', () {
      final ranked = matcher.rank('Ravi', const [ravi, raviT]);
      expect(ranked.map((m) => m.customer.id), containsAll(['ravi', 'ravi-t']));
      expect(matcher.autoPick(ranked), isNull);
    });

    test('nothing close: no candidates, so the sheet offers "add new"', () {
      expect(matcher.rank('Fathima', const [ravi, kumar]), isEmpty);
    });

    test('a near miss still ranks', () {
      final ranked = matcher.rank('Kumaar', const [kumar, ravi]);
      expect(ranked.first.customer, kumar);
    });
  });

  group('readConfirmation', () {
    test('yes words in Sri Lankan Tamil and English', () {
      for (final w in ['சரி', 'ஓம்', 'sari', 'OK', 'ஆம்.']) {
        expect(readConfirmation(w), Confirmation.yes, reason: w);
      }
    });

    test('no wins over yes', () {
      expect(readConfirmation('இல்லை'), Confirmation.no);
      expect(readConfirmation('சரி இல்லை'), Confirmation.no);
      expect(readConfirmation('வேண்டாம்'), Confirmation.no);
    });

    test('anything else is unclear', () {
      expect(readConfirmation(''), Confirmation.unclear);
      expect(readConfirmation('ரவி'), Confirmation.unclear);
    });
  });

  test('read-back keeps digits for the TTS voice', () {
    expect(
      readBackText(
        languageCode: 'ta',
        customer: 'ரவி அண்ணை',
        amountCents: 150000,
        type: EntryType.credit,
      ),
      'ரவி அண்ணை, 1500 ரூபா கடன். சரியா?',
    );
    expect(
      readBackText(
        languageCode: 'en',
        customer: 'Ravi annai',
        amountCents: 125050,
        type: EntryType.payment,
      ),
      'Ravi annai, 1250 rupees 50 cents payment received. Is that right?',
    );
  });
}
