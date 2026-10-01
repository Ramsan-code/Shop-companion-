import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/features/ledger/domain/entry_type.dart';
import 'package:shop_companion/features/ledger/domain/models.dart';
import 'package:shop_companion/features/voice/domain/speech_input.dart';
import 'package:shop_companion/features/voice/presentation/voice_entry_store.dart';

void main() {
  const ravi = Customer(id: 'ravi', name: 'Ravi', kinship: Kinship.annai);
  const raviT = Customer(id: 'ravi-t', name: 'Ravi', kinship: Kinship.thambi);
  const kumar = Customer(id: 'kumar', name: 'குமார்');

  VoiceEntryStore store() =>
      VoiceEntryStore(customers: const [ravi, raviT, kumar]);

  test('US1: "Ravi annai 500 kadan" fills everything, ready to save', () {
    final s = store()..applyHeard('Ravi annai 500 kadan');
    expect(s.customer.value, ravi);
    expect(s.amount.value?.cents, 50000);
    expect(s.type.value, EntryType.credit);
    expect(s.canSave.value, isTrue);
    expect(s.step.value, VoiceStep.confirming);
  });

  test('Tamil speech matches a customer saved in Tamil script', () {
    final s = store()..applyHeard('Kumar 1500 thanthar');
    expect(s.customer.value, kumar);
    expect(s.type.value, EntryType.payment);
    expect(s.amountText.value, '1500');
  });

  test('two Ravis without a kinship word: candidates, no guess', () {
    final s = store()..applyHeard('Ravi 200 kadan');
    expect(s.customer.value, isNull);
    expect(
      s.candidates.map((m) => m.customer.id),
      containsAll(['ravi', 'ravi-t']),
    );
    expect(s.canSave.value, isFalse);
    s.chooseCustomer(raviT);
    expect(s.canSave.value, isTrue);
  });

  test('an unknown name becomes a new customer', () {
    final s = store()..applyHeard('Fathima akka 300 kadan');
    expect(s.customer.value, isNull);
    expect(s.newCustomerName.value, 'Fathima');
    expect(s.newCustomerKinship.value, Kinship.akka);
    expect(s.canSave.value, isTrue);
  });

  test('keypad fallback: speech failed, everything typed', () {
    final s = store()..fail(SpeechFailure.unavailable);
    expect(s.failure.value, SpeechFailure.unavailable);
    expect(s.canSave.value, isFalse);
    expect(s.search('ra').map((c) => c.id), ['ravi', 'ravi-t']);
    s
      ..chooseCustomer(ravi)
      ..setAmountText('1,250.50')
      ..setType(EntryType.payment);
    expect(s.amount.value?.cents, 125050);
    expect(s.canSave.value, isTrue);
    s.markSaving();
    expect(s.canSave.value, isFalse);
  });

  test('a misheard amount is corrected by typing', () {
    final s = store()..applyHeard('Ravi annai 5000 kadan');
    s.setAmountText('500');
    expect(s.amount.value?.cents, 50000);
    s.setAmountText('0');
    expect(s.canSave.value, isFalse);
  });
}
