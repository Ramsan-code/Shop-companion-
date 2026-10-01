// Scores the voice parser against a transcript CSV (R0 voice benchmark).
//
//   dart run tool/voice_benchmark.dart transcripts.csv [customer-names.txt]
//
// CSV columns: speaker_id,transcript,expected_customer,expected_amount,expected_type
// The optional names file (one per line) is a shop's customer list; the
// heard name must then pick the right customer, as in the app.
// Exit code 1 when either PRD 11 target is missed.
import 'dart:io';

import 'package:shop_companion/features/voice/domain/voice_benchmark.dart';

void main(List<String> args) {
  if (args.isEmpty || args.length > 2) {
    stderr.writeln(
      'usage: dart run tool/voice_benchmark.dart <file.csv> [names.txt]',
    );
    exit(64);
  }
  final names = args.length == 2
      ? File(args[1])
            .readAsLinesSync()
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList()
      : null;
  final report = VoiceBenchmark.run(
    File(args.first).readAsStringSync(),
    customerNames: names,
  );
  stdout.writeln(report.describe());
  exit(report.meetsTargets ? 0 : 1);
}
