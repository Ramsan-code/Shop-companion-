// Scores the voice parser against a transcript CSV (R0 voice benchmark).
//
//   dart run tool/voice_benchmark.dart path/to/transcripts.csv
//
// CSV columns: speaker_id,transcript,expected_customer,expected_amount,expected_type
// Exit code 1 when either PRD 11 target is missed.
import 'dart:io';

import 'package:shop_companion/features/voice/domain/voice_benchmark.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('usage: dart run tool/voice_benchmark.dart <file.csv>');
    exit(64);
  }
  final report = VoiceBenchmark.run(File(args.single).readAsStringSync());
  stdout.writeln(report.describe());
  exit(report.meetsTargets ? 0 : 1);
}
