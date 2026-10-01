/// Ledger entry types (PRD 10.1 `entries.type`).
enum EntryType {
  credit,
  payment,
  sale,
  expense,
  purchase,
  discount;

  static EntryType? fromWire(String value) {
    for (final t in values) {
      if (t.name == value) return t;
    }
    return null;
  }
}
