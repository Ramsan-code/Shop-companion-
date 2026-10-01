import 'entry_type.dart';

/// Quick-tap categories for sales and expenses (PRD C4). Stored as the
/// `category` wire value on the entry; labels and icons live with the UI.
enum EntryCategory {
  // Sales
  grocery(EntryType.sale),
  vegetables(EntryType.sale),
  bakery(EntryType.sale),
  phoneCredit(EntryType.sale),
  otherSale(EntryType.sale),
  // Money out. Buying stock is a purchase, not an expense: Profit Mirror
  // counts it through the margin, so it isn't taken off twice.
  stockPurchase(EntryType.purchase),
  transport(EntryType.expense),
  electricity(EntryType.expense),
  wages(EntryType.expense),
  rent(EntryType.expense),
  otherExpense(EntryType.expense);

  const EntryCategory(this.type);

  final EntryType type;

  bool get isSale => type == EntryType.sale;

  static List<EntryCategory> get sales =>
      values.where((c) => c.isSale).toList();

  static List<EntryCategory> get spending =>
      values.where((c) => !c.isSale).toList();

  static EntryCategory? fromWire(String? value) =>
      value == null ? null : values.asNameMap()[value];
}
