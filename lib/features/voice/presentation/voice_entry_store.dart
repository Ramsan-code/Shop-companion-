import 'package:mobx/mobx.dart';

import '../../../core/money.dart';
import '../../ledger/domain/entry_type.dart';
import '../../ledger/domain/ledger_math.dart';
import '../../ledger/domain/models.dart';
import '../domain/customer_matcher.dart';
import '../domain/speech_input.dart';
import '../domain/voice_entry_parser.dart';

enum VoiceStep { listening, confirming, saving }

/// Short-lived form state for the voice confirm sheet (PRD 9.1: MobX, created
/// and disposed with its widget). Pure: no plugins, so it is unit-testable.
///
/// The keypad fallback is the same form: whatever speech fills in can be
/// corrected by typing, and if speech fails the form is simply typed.
class VoiceEntryStore {
  VoiceEntryStore({
    required this._customers,
    EntryType defaultType = EntryType.credit,
    this.allowedTypes = const [EntryType.credit, EntryType.payment],
    this.parser = const VoiceEntryParser(),
    this.matcher = const CustomerMatcher(),
  }) : type = Observable(defaultType);

  final List<Customer> _customers;

  /// What this person may record by voice (sale and expense need no
  /// customer; expense needs `ledger:createExpense`).
  final List<EntryType> allowedTypes;
  final VoiceEntryParser parser;
  final CustomerMatcher matcher;

  final step = Observable(VoiceStep.listening);
  final partial = Observable('');
  final heard = Observable('');
  final failure = Observable<SpeechFailure?>(null);

  final customer = Observable<Customer?>(null);
  final candidates = ObservableList<CustomerMatch>();

  /// A heard name with no matching customer: saving creates one.
  final newCustomerName = Observable<String?>(null);
  final newCustomerKinship = Observable<Kinship?>(null);

  final amountText = Observable('');
  final Observable<EntryType> type;

  late final amount = Computed(() {
    final money = Money.tryParse(amountText.value);
    return money == null || money.isZero ? null : money;
  });

  late final hasCustomer = Computed(
    () => customer.value != null || newCustomerName.value != null,
  );

  /// Credit and payment belong to a customer; a sale or expense doesn't.
  late final needsCustomer = Computed(() => affectsCustomer(type.value));

  late final canSave = Computed(
    () =>
        step.value != VoiceStep.saving &&
        (hasCustomer.value || !needsCustomer.value) &&
        amount.value != null,
  );

  void setPartial(String text) => runInAction(() => partial.value = text);

  /// A final transcript: parse it and fill in what was understood.
  void applyHeard(String text) => runInAction(() {
    heard.value = text;
    partial.value = '';
    failure.value = null;
    step.value = VoiceStep.confirming;

    final parsed = parser.parse(text);
    final cents = parsed.amountCents;
    if (cents != null) amountText.value = _format(cents);
    if (parsed.type case final t? when allowedTypes.contains(t)) {
      type.value = t;
    }

    final name = parsed.customerName;
    if (name == null) return;
    final kinship = Kinship.values.byWire(parsed.kinshipTerm);
    final ranked = matcher.rank(name, _customers, heardKinship: kinship);
    candidates
      ..clear()
      ..addAll(ranked);
    final picked = matcher.autoPick(ranked);
    customer.value = picked;
    if (picked == null && ranked.isEmpty) {
      newCustomerName.value = name;
      newCustomerKinship.value = kinship;
    } else {
      newCustomerName.value = null;
    }
  });

  void fail(SpeechFailure reason) => runInAction(() {
    failure.value = reason;
    partial.value = '';
    step.value = VoiceStep.confirming;
  });

  void relisten() => runInAction(() {
    failure.value = null;
    step.value = VoiceStep.listening;
  });

  void chooseCustomer(Customer c) => runInAction(() {
    customer.value = c;
    newCustomerName.value = null;
  });

  void chooseNewCustomer(String name) => runInAction(() {
    customer.value = null;
    newCustomerName.value = name.trim().isEmpty ? null : name.trim();
  });

  void setAmountText(String text) => runInAction(() => amountText.value = text);

  void setType(EntryType t) => runInAction(() => type.value = t);

  void markSaving() => runInAction(() => step.value = VoiceStep.saving);

  void markEditing() => runInAction(() => step.value = VoiceStep.confirming);

  /// Customers whose names contain [query], for the keypad customer field.
  List<Customer> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _customers
        .where((c) => c.name.toLowerCase().contains(q))
        .take(5)
        .toList();
  }

  static String _format(int cents) =>
      cents % 100 == 0 ? '${cents ~/ 100}' : (cents / 100).toStringAsFixed(2);
}
