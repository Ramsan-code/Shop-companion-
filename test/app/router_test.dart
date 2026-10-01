import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/app/router.dart';
import 'package:shop_companion/core/rbac/role.dart';
import 'package:shop_companion/features/auth/domain/session.dart';
import 'package:shop_companion/features/auth/presentation/app_lock_cubit.dart';

void main() {
  const user = AppUser(uid: 'u1', phone: '+94770000000');
  const noShop = SignedIn(user);
  SignedIn signedInAs(Role role) => SignedIn(
    user,
    membership: Membership(shopId: 's1', shopName: 'Shop', role: role),
  );
  String? go(
    SessionState s,
    String location, {
    LockStatus lock = LockStatus.unlocked,
    bool invite = false,
  }) => resolveRedirect(s, lock, location, hasPendingInvite: invite);

  test('waits on the splash until the session is known', () {
    expect(go(const SessionUnknown(), Routes.home), Routes.splash);
    expect(go(const SessionUnknown(), Routes.splash), isNull);
  });

  test('signed out always lands on login', () {
    expect(go(const SignedOut(), Routes.home), Routes.login);
    expect(go(const SignedOut(), '/invite/abc'), Routes.login);
    expect(go(const SignedOut(), Routes.login), isNull);
  });

  test('PIN comes before anything else once signed in (flow 7.1-1)', () {
    for (final s in [noShop, signedInAs(Role.owner)]) {
      expect(go(s, Routes.home, lock: LockStatus.needsPin), Routes.pinSetup);
      expect(go(s, Routes.pinSetup, lock: LockStatus.needsPin), isNull);
      expect(go(s, Routes.home, lock: LockStatus.locked), Routes.lock);
      expect(go(s, Routes.more, lock: LockStatus.checking), Routes.splash);
    }
  });

  test('unlocked without a shop: setup, or join when an invite is pending', () {
    expect(go(noShop, Routes.home), Routes.setup);
    expect(go(noShop, Routes.setup), isNull);
    expect(go(noShop, '/invite/abc', invite: true), Routes.join);
    expect(go(noShop, Routes.join, invite: true), isNull);
  });

  test('owner and partner use the five-tab shell', () {
    for (final role in [Role.owner, Role.partner]) {
      expect(go(signedInAs(role), Routes.login), Routes.home);
      expect(go(signedInAs(role), Routes.stock), isNull);
      expect(go(signedInAs(role), Routes.members), isNull);
      expect(go(signedInAs(role), Routes.entry), Routes.home);
      expect(go(signedInAs(role), Routes.lock), Routes.home);
    }
  });

  test('helper is kept inside the helper shell', () {
    final helper = signedInAs(Role.helper);
    expect(go(helper, Routes.home), Routes.entry);
    expect(go(helper, Routes.members), Routes.entry);
    expect(go(helper, Routes.closeDay), isNull);
    expect(go(helper, '/stockpile'), Routes.entry);
  });
}
