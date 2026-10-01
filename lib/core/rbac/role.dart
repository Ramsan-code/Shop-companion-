import 'permission.dart';

/// Shop roles (PRD 6). Mirrors `seed/roles.json`; a test keeps them in sync.
///
/// Phase 1 reads `roles/{role}` from Firestore so new roles (for example
/// Accountant) need no app update. This map is the offline default.
enum Role {
  owner,
  partner,
  helper,
  admin;

  static Role? fromWire(String value) {
    for (final r in values) {
      if (r.name == value) return r;
    }
    return null;
  }

  Set<Permission> get permissions => defaultPermissions[this]!;

  bool can(Permission permission) => permissions.contains(permission);

  /// Owner and Partner get the five-tab shell; Helper gets the simple one.
  bool get usesHelperShell => this == Role.helper;
}

const Map<Role, Set<Permission>> defaultPermissions = {
  Role.owner: {
    Permission.ledgerCreate,
    Permission.ledgerCreateExpense,
    Permission.ledgerEditOwn,
    Permission.ledgerEditAny,
    Permission.customerWrite,
    Permission.balanceRead,
    Permission.scoreRead,
    Permission.limitOverride,
    Permission.reminderSend,
    Permission.profitRead,
    Permission.insightsRead,
    Permission.stockManage,
    Permission.stockUpdateQty,
    Permission.drawerCheck,
    Permission.drawerCount,
    Permission.supplierManage,
    Permission.auditRead,
    Permission.memberInvite,
    Permission.shopManage,
    Permission.supportGrant,
  },
  Role.partner: {
    Permission.ledgerCreate,
    Permission.ledgerCreateExpense,
    Permission.ledgerEditOwn,
    Permission.ledgerEditAny,
    Permission.customerWrite,
    Permission.balanceRead,
    Permission.scoreRead,
    Permission.reminderSend,
    Permission.profitRead,
    Permission.insightsRead,
    Permission.stockManage,
    Permission.stockUpdateQty,
    Permission.drawerCheck,
    Permission.drawerCount,
    Permission.supplierManage,
  },
  Role.helper: {
    Permission.ledgerCreate,
    Permission.ledgerEditOwn,
    Permission.customerWrite,
    Permission.balanceRead,
    Permission.stockUpdateQty,
    Permission.drawerCount,
  },
  // Platform Admin works only through audited callable functions.
  Role.admin: {},
};
