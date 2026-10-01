import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/session.dart';
import '../features/auth/presentation/app_lock_cubit.dart';
import '../features/auth/presentation/join_screen.dart';
import '../features/auth/presentation/lock_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/pending_invite_cubit.dart';
import '../features/auth/presentation/pin_setup_screen.dart';
import '../features/auth/presentation/session_cubit.dart';
import '../features/auth/presentation/setup_screen.dart';
import '../features/close_day/presentation/close_day_screen.dart';
import '../features/customers/presentation/customer_detail_screen.dart';
import '../features/customers/presentation/customers_screen.dart';
import '../features/ledger/presentation/entry_screen.dart';
import '../features/ledger/presentation/home_screen.dart';
import '../features/settings/presentation/members_screen.dart';
import '../features/settings/presentation/more_screen.dart';
import '../features/stock/presentation/stock_screen.dart';
import 'shells/helper_shell.dart';
import 'shells/owner_shell.dart';

/// Every route in the app (PRD 8.2: all routes declared in one file).
abstract final class Routes {
  static const splash = '/';
  static const login = '/login';
  static const pinSetup = '/pin';
  static const lock = '/lock';
  static const setup = '/setup';
  static const join = '/join';

  /// Deep link from an invite SMS (PRD 9.3). Never shown: the token is
  /// captured and the guard routes on.
  static const invitePrefix = '/invite/';

  // Owner / Partner shell
  static const home = '/home';
  static const customers = '/customers';
  static const stock = '/stock';
  static const more = '/more';
  static const members = '/more/members';

  // Helper shell
  static const entry = '/entry';
  static const helperCustomers = '/helper/customers';
  static const closeDay = '/close-day';

  static const ownerShell = {home, customers, stock, more};
  static const helperShell = {entry, helperCustomers, closeDay};
}

/// The redirect guard (PRD 9.3), in order: session known → signed in →
/// PIN set and unlocked → has a shop (or joins one from an invite) → the
/// role decides the shell. Pure so it can be unit-tested.
///
/// This only picks screens. Security Rules are what stop a helper reading
/// profit, whatever route the app is on.
String? resolveRedirect(
  SessionState session,
  LockStatus lock,
  String location, {
  bool hasPendingInvite = false,
}) {
  bool inShell(Set<String> shell) =>
      shell.any((r) => location == r || location.startsWith('$r/'));
  String? only(String route) => location == route ? null : route;

  return switch (session) {
    SessionUnknown() => only(Routes.splash),
    SignedOut() => only(Routes.login),
    SignedIn() when lock == LockStatus.needsPin => only(Routes.pinSetup),
    SignedIn() when lock == LockStatus.locked => only(Routes.lock),
    SignedIn() when lock != LockStatus.unlocked => only(Routes.splash),
    SignedIn(membership: null) when hasPendingInvite => only(Routes.join),
    SignedIn(membership: null) => only(Routes.setup),
    SignedIn(:final membership?) when membership.role.usesHelperShell =>
      inShell(Routes.helperShell) ? null : Routes.entry,
    SignedIn() => inShell(Routes.ownerShell) ? null : Routes.home,
  };
}

GoRouter buildRouter({
  required SessionCubit session,
  required AppLockCubit lock,
  required PendingInviteCubit invite,
}) => GoRouter(
  initialLocation: Routes.splash,
  refreshListenable: _StreamListenable([
    session.stream,
    lock.stream,
    invite.stream,
  ]),
  redirect: (context, state) {
    final location = state.uri.path;
    if (location.startsWith(Routes.invitePrefix)) {
      invite.capture(location.substring(Routes.invitePrefix.length));
    }
    final current = session.state;
    // Someone who already has a shop can't use an invite (multi-shop is R3).
    if (current is SignedIn && current.membership != null) {
      if (invite.state != null) invite.clear();
    }
    return resolveRedirect(
      current,
      lock.state.status,
      location,
      hasPendingInvite: invite.state != null,
    );
  },
  routes: [
    GoRoute(path: Routes.splash, builder: (_, _) => const _Splash()),
    GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
    GoRoute(path: Routes.pinSetup, builder: (_, _) => const PinSetupScreen()),
    GoRoute(path: Routes.lock, builder: (_, _) => const LockScreen()),
    GoRoute(path: Routes.setup, builder: (_, _) => const SetupScreen()),
    GoRoute(path: Routes.join, builder: (_, _) => const JoinScreen()),
    GoRoute(
      path: '${Routes.invitePrefix}:token',
      builder: (_, _) => const _Splash(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => OwnerShell(navigationShell: shell),
      branches: [
        _branch(Routes.home, const HomeScreen()),
        _customersBranch(Routes.customers),
        _branch(Routes.stock, const StockScreen()),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.more,
              builder: (_, _) => const MoreScreen(),
              routes: [
                GoRoute(
                  path: 'members',
                  builder: (_, _) => const MembersScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => HelperShell(navigationShell: shell),
      branches: [
        _branch(Routes.entry, const EntryScreen()),
        _customersBranch(Routes.helperCustomers),
        _branch(Routes.closeDay, const CloseDayScreen()),
      ],
    ),
  ],
);

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (_, _) => screen)],
);

/// Customer list with `/{customerId}` detail pages under it.
StatefulShellBranch _customersBranch(String path) => StatefulShellBranch(
  routes: [
    GoRoute(
      path: path,
      builder: (_, _) => CustomersScreen(basePath: path),
      routes: [
        GoRoute(
          path: ':customerId',
          builder: (_, state) => CustomerDetailScreen(
            customerId: state.pathParameters['customerId']!,
          ),
        ),
      ],
    ),
  ],
);

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) =>
      const ColoredBox(color: Color(0x00000000), child: SizedBox.expand());
}

/// Lets go_router re-run the guard whenever session, lock or invite change.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(List<Stream<Object?>> streams) {
    _subscriptions = [
      for (final s in streams) s.listen((_) => notifyListeners()),
    ];
  }

  late final List<StreamSubscription<Object?>> _subscriptions;

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }
}
