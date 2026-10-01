/// Named actions from `roles/{role}.permissions` (PRD 6.1).
///
/// The app only uses these to hide UI. Security Rules and Cloud Functions are
/// the real enforcement, so a missing check here is never a security hole.
enum Permission {
  ledgerCreate('ledger:create'),
  ledgerCreateExpense('ledger:createExpense'),
  ledgerEditOwn('ledger:editOwn'),

  /// Edit or delete any entry at any age, through the callables (logged).
  ledgerEditAny('ledger:editAny'),
  customerWrite('customer:write'),
  balanceRead('balance:read'),
  scoreRead('score:read'),
  limitOverride('limit:override'),
  reminderSend('reminder:send'),
  profitRead('profit:read'),
  insightsRead('insights:read'),
  stockManage('stock:manage'),
  stockUpdateQty('stock:updateQty'),
  drawerCheck('drawer:check'),
  drawerCount('drawer:count'),
  supplierManage('supplier:manage'),
  auditRead('audit:read'),
  memberInvite('member:invite'),
  shopManage('shop:manage'),
  supportGrant('support:grant');

  const Permission(this.wireName);

  /// The string stored in Firestore and checked by Security Rules.
  final String wireName;

  static Permission? fromWire(String value) {
    for (final p in values) {
      if (p.wireName == value) return p;
    }
    return null;
  }
}
