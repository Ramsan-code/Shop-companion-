import '../../../core/money.dart';
import '../../ledger/domain/entry_type.dart';
import '../../ledger/domain/models.dart';
import 'customer_matcher.dart';
import 'phonetic.dart';
import 'voice_entry_parser.dart';

/// One labelled transcript from the benchmark set.
class BenchmarkCase {
  const BenchmarkCase({
    required this.speakerId,
    required this.transcript,
    required this.customer,
    required this.amountCents,
    required this.type,
  });

  final String speakerId;
  final String transcript;
  final String customer;
  final int amountCents;
  final EntryType type;
}

class BenchmarkMiss {
  const BenchmarkMiss(this.testCase, this.parsed);

  final BenchmarkCase testCase;
  final ParsedEntry parsed;
}

class BenchmarkReport {
  const BenchmarkReport({
    required this.total,
    required this.amountCorrect,
    required this.customerCorrect,
    required this.typeCorrect,
    required this.misses,
  });

  /// PRD 11 voice targets, first try, before general release.
  static const amountTarget = 0.90;
  static const customerTarget = 0.85;

  final int total;
  final int amountCorrect;
  final int customerCorrect;
  final int typeCorrect;
  final List<BenchmarkMiss> misses;

  double _rate(int n) => total == 0 ? 0 : n / total;

  double get amountAccuracy => _rate(amountCorrect);
  double get customerAccuracy => _rate(customerCorrect);
  double get typeAccuracy => _rate(typeCorrect);

  bool get meetsTargets =>
      total > 0 &&
      amountAccuracy >= amountTarget &&
      customerAccuracy >= customerTarget;

  String describe() {
    String pct(double v) => '${(v * 100).toStringAsFixed(1)}%';
    final lines = [
      'Cases:    $total',
      'Amount:   ${pct(amountAccuracy)} (target ${pct(amountTarget)})',
      'Customer: ${pct(customerAccuracy)} (target ${pct(customerTarget)})',
      'Type:     ${pct(typeAccuracy)}',
      meetsTargets ? 'PASS' : 'FAIL',
      if (misses.isNotEmpty) '\nMisses:',
      for (final m in misses)
        '  [${m.testCase.speakerId}] "${m.testCase.transcript}" → '
            'customer=${m.parsed.customerName}, '
            'amount=${m.parsed.amountCents}, type=${m.parsed.type?.name}',
    ];
    return lines.join('\n');
  }
}

/// Runs [VoiceEntryParser] over labelled transcripts.
///
/// Customer accuracy: with a [customerNames] list (a shop's real names),
/// the heard name must pick the expected customer through
/// [CustomerMatcher], as in the app. Without one, the heard name must sound
/// the same as the expected one (same [phoneticKey]), so "Ravee" for "Ravi"
/// or Tamil script for a romanised name still counts.
abstract final class VoiceBenchmark {
  static BenchmarkReport run(
    String csv, {
    VoiceEntryParser parser = const VoiceEntryParser(),
    List<String>? customerNames,
    CustomerMatcher matcher = const CustomerMatcher(),
  }) {
    final customers = [
      for (final (i, name) in (customerNames ?? const <String>[]).indexed)
        Customer(id: '$i', name: name),
    ];
    final cases = parseCsv(csv);
    var amount = 0, customer = 0, type = 0;
    final misses = <BenchmarkMiss>[];
    for (final c in cases) {
      final parsed = parser.parse(c.transcript);
      final amountOk = parsed.amountCents == c.amountCents;
      final heardName = parsed.customerName;
      final bool customerOk;
      if (heardName == null) {
        customerOk = false;
      } else if (customers.isNotEmpty) {
        final picked = matcher.autoPick(
          matcher.rank(
            heardName,
            customers,
            heardKinship: Kinship.values.byWire(parsed.kinshipTerm),
          ),
        );
        customerOk = picked?.name == c.customer;
      } else {
        customerOk = phoneticKey(heardName) == phoneticKey(c.customer);
      }
      final typeOk = parsed.type == c.type;
      if (amountOk) amount++;
      if (customerOk) customer++;
      if (typeOk) type++;
      if (!(amountOk && customerOk && typeOk)) {
        misses.add(BenchmarkMiss(c, parsed));
      }
    }
    return BenchmarkReport(
      total: cases.length,
      amountCorrect: amount,
      customerCorrect: customer,
      typeCorrect: type,
      misses: misses,
    );
  }

  /// Minimal CSV: header row, comma-separated, double quotes around fields
  /// that contain commas ("1,500").
  static List<BenchmarkCase> parseCsv(String csv) {
    final rows = csv
        .split(RegExp(r'\r?\n'))
        .where((l) => l.trim().isNotEmpty)
        .skip(1);
    return [
      for (final (i, row) in rows.indexed) _toCase(_splitRow(row), i + 2),
    ];
  }

  static BenchmarkCase _toCase(List<String> f, int line) {
    if (f.length != 5) {
      throw FormatException('line $line: expected 5 columns, got ${f.length}');
    }
    final amount = Money.tryParse(f[3]);
    final type = EntryType.fromWire(f[4].trim());
    if (amount == null || type == null) {
      throw FormatException('line $line: bad amount or type');
    }
    return BenchmarkCase(
      speakerId: f[0].trim(),
      transcript: f[1].trim(),
      customer: f[2].trim(),
      amountCents: amount.cents,
      type: type,
    );
  }

  static List<String> _splitRow(String row) {
    final fields = <String>[];
    final buffer = StringBuffer();
    var quoted = false;
    for (final char in row.split('')) {
      if (char == '"') {
        quoted = !quoted;
      } else if (char == ',' && !quoted) {
        fields.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    fields.add(buffer.toString());
    return fields;
  }
}
