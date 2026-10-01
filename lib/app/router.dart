import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/session.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/session_cubit.dart';
import '../features/auth/presentation/setup_screen.dart';
import '../features/close_day/presentation/close_day_screen.dart';
import '../features/customers/presentation/customers_screen.dart';
import '../features/ledger/presentation/entry_screen.dart';
import '../features/ledger/presentation/home_screen.dart';
import '../features/settings/presentation/more_screen.dart';
import '../features/stock/presentation/stock_screen.dart';
import 'shells/helper_shell.dart';
import 'shells/owner_shell.dart';

/// Every route in the app (PRD 8.2: all routes declared in one file).
abstract final class Routes {
  static const splash = '/';
  static const login = '/login';
  static const setup = '/setup';

  // Owner / Partner shell
  static const home = '/home';
  static const customers = '/customers';
  static const stock = '/stock';
  static const more = '/more';

  // Helper shell
  static const entry = '/entry';
  static const helperCustomers = '/helper/customers';
  static const closeDay = '/close-day';

  static const ownerShell = {home, customers, stock, more};
  static const helperShell = {entry, helperCustomers, closeDay};
}

/// The redirect guard (PRD 9.3): not signed in → login, no shop → setup,
/// role decides the shell. Pure so it can be unit-tested.
///
/// This only picks screens. Security Rules are what stop a helper reading
/// profit, whatever route the app is on.
String? resolveRedirect(SessionState session, String location) {
  bool inShell(Set<String> shell) =>
      shell.any((r) => location == r || location.startsWith('$r/'));

  return switch (session) {
    SessionUnknown() => location == Routes.splash ? null : Routes.splash,
    SignedOut() => location == Routes.login ? null : Routes.login,
    SignedIn(membership: null) =>
      location == Routes.setup ? null : Routes.setup,
    SignedIn(:final membership?) when membership.role.usesHelperShell =>
      inShell(Routes.helperShell) ? null : Routes.entry,
    SignedIn() => inShell(Routes.ownerShell) ? null : Routes.home,
  };
}

GoRouter buildRouter(SessionCubit session) => GoRouter(
  initialLocation: Routes.splash,
  refreshListenable: _StreamListenable(session.stream),
  redirect: (context, state) =>
      resolveRedirect(session.state, state.matchedLocation),
  routes: [
    GoRoute(path: Routes.splash, builder: (_, _) => const SizedBox.shrink()),
    GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
    GoRoute(path: Routes.setup, builder: (_, _) => const SetupScreen()),
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => OwnerShell(navigationShell: shell),
      branches: [
        _branch(Routes.home, const HomeScreen()),
        _branch(Routes.customers, const CustomersScreen()),
        _branch(Routes.stock, const StockScreen()),
        _branch(Routes.more, const MoreScreen()),
      ],
    ),
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => HelperShell(navigationShell: shell),
      branches: [
        _branch(Routes.entry, const EntryScreen()),
        _branch(Routes.helperCustomers, const CustomersScreen()),
        _branch(Routes.closeDay, const CloseDayScreen()),
      ],
    ),
  ],
);

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (_, _) => screen)],
);

/// Lets go_router re-run [resolveRedirect] whenever the session changes.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
