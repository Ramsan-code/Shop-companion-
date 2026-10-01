import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/app/router.dart';
import 'package:shop_companion/core/rbac/role.dart';
import 'package:shop_companion/features/auth/domain/session.dart';

void main() {
  const user = AppUser(uid: 'u1', phone: '+94770000000');
  SignedIn signedInAs(Role role) => SignedIn(
    user,
    membership: Membership(shopId: 's1', shopName: 'Shop', role: role),
  );

  test('signed out always lands on login', () {
    expect(resolveRedirect(const SignedOut(), Routes.home), Routes.login);
    expect(resolveRedirect(const SignedOut(), Routes.login), isNull);
  });

  test('signed in without a shop goes to setup', () {
    expect(resolveRedirect(const SignedIn(user), Routes.home), Routes.setup);
    expect(resolveRedirect(const SignedIn(user), Routes.setup), isNull);
  });

  test('owner and partner use the five-tab shell', () {
    for (final role in [Role.owner, Role.partner]) {
      expect(resolveRedirect(signedInAs(role), Routes.login), Routes.home);
      expect(resolveRedirect(signedInAs(role), Routes.stock), isNull);
      expect(resolveRedirect(signedInAs(role), Routes.entry), Routes.home);
    }
  });

  test('helper is kept inside the helper shell', () {
    final helper = signedInAs(Role.helper);
    expect(resolveRedirect(helper, Routes.home), Routes.entry);
    expect(resolveRedirect(helper, Routes.more), Routes.entry);
    expect(resolveRedirect(helper, Routes.closeDay), isNull);
    expect(resolveRedirect(helper, '/stockpile'), Routes.entry);
  });
}
