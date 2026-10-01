import 'package:mobx/mobx.dart';

import '../../../core/phone.dart';
import '../../ledger/domain/models.dart';
import '../../voice/domain/voice_entry_parser.dart';
import '../domain/import_table.dart';

enum ImportIssue { none, noName, duplicate }

class ImportRow {
  ImportRow(this.candidate, this.issue)
    : include = Observable(issue == ImportIssue.none);

  final ImportCandidate candidate;
  final ImportIssue issue;
  final Observable<bool> include;
}

/// The import preview grid (PRD N2, US10; PRD 9.1 MobX for short-lived form
/// state). Rows from a file or spoken one by one; the owner unticks what
/// shouldn't come in, fixes the column guess, then saves in one step.
class ImportStore {
  ImportStore({
    required List<Customer> existing,
    this.parser = const VoiceEntryParser(),
  }) : _names = {for (final c in existing) c.name.trim().toLowerCase()},
       _phones = {for (final c in existing) ?normalizeLkMobile(c.phone ?? '')};

  final VoiceEntryParser parser;
  final Set<String> _names;
  final Set<String> _phones;

  List<List<String>> _table = const [];
  final columns = Observable<ColumnMap?>(null);
  final flip = Observable(false);
  final fileRows = ObservableList<ImportRow>();
  final spokenRows = ObservableList<ImportRow>();

  /// Header cells for the column pickers ("Column 3" when there is none).
  late final headers = Computed<List<String>>(() {
    final map = columns.value;
    if (map == null || _table.isEmpty) return const [];
    final width = _table.fold<int>(0, (w, r) => r.length > w ? r.length : w);
    final header = map.headerRow >= 0
        ? _table[map.headerRow]
        : const <String>[];
    return [
      for (var i = 0; i < width; i++)
        i < header.length && header[i].isNotEmpty ? header[i] : '#${i + 1}',
    ];
  });

  late final rows = Computed<List<ImportRow>>(
    () => [...fileRows, ...spokenRows],
  );

  late final chosen = Computed<List<ImportCandidate>>(
    () => [
      for (final r in rows.value)
        if (r.include.value && r.issue != ImportIssue.noName) r.candidate,
    ],
  );

  late final totalOwedCents = Computed<int>(
    () => chosen.value.fold(
      0,
      (s, c) => s + (c.balanceCents > 0 ? c.balanceCents : 0),
    ),
  );

  ImportIssue _issue(ImportCandidate c) {
    if (c.name.trim().isEmpty) return ImportIssue.noName;
    final phone = normalizeLkMobile(c.phone ?? '');
    if (_names.contains(c.name.trim().toLowerCase()) ||
        (phone != null && _phones.contains(phone))) {
      return ImportIssue.duplicate;
    }
    return ImportIssue.none;
  }

  void loadTable(List<List<String>> table) => runInAction(() {
    _table = table;
    columns.value = guessColumns(table);
    _rebuild();
  });

  void setColumns(ColumnMap map) => runInAction(() {
    columns.value = map;
    _rebuild();
  });

  void setFlip(bool value) => runInAction(() {
    flip.value = value;
    _rebuild();
  });

  void _rebuild() {
    final map = columns.value;
    fileRows
      ..clear()
      ..addAll([
        if (map != null)
          for (final c in candidatesFrom(_table, map, flip: flip.value))
            ImportRow(c, _issue(c)),
      ]);
  }

  /// Voice bulk entry: "Ravi annai 1500" adds a row. Returns false when
  /// no name was heard.
  bool addSpoken(String text) {
    final parsed = parser.parse(text);
    final name = parsed.customerName;
    if (name == null || name.trim().isEmpty) return false;
    final candidate = ImportCandidate(
      name: name.trim(),
      kinship: parsed.kinshipTerm,
      balanceCents: parsed.amountCents ?? 0,
    );
    runInAction(() => spokenRows.add(ImportRow(candidate, _issue(candidate))));
    return true;
  }

  void toggle(ImportRow row) =>
      runInAction(() => row.include.value = !row.include.value);
}
