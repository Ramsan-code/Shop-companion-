import '../core/rbac/role.dart';
import 'l10n/app_localizations.dart';

extension RoleLabel on Role {
  String label(AppLocalizations l10n) => switch (this) {
    Role.owner => l10n.roleOwner,
    Role.partner => l10n.rolePartner,
    Role.helper => l10n.roleHelper,
    Role.admin => 'Admin',
  };
}
