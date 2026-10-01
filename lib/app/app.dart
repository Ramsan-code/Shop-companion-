import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/di/providers.dart';
import '../core/rbac/permission.dart';
import '../features/auth/domain/session.dart';
import '../features/auth/presentation/app_lock_cubit.dart';
import '../features/auth/presentation/pending_invite_cubit.dart';
import '../features/auth/presentation/session_cubit.dart';
import '../sync/sync_service.dart';
import 'l10n/app_localizations.dart';
import 'locale_cubit.dart';
import 'router.dart';
import 'theme.dart';

class ShopCompanionApp extends ConsumerStatefulWidget {
  const ShopCompanionApp({super.key});

  @override
  ConsumerState<ShopCompanionApp> createState() => _ShopCompanionAppState();
}

class _ShopCompanionAppState extends ConsumerState<ShopCompanionApp> {
  late final SessionCubit _session;
  late final AppLockCubit _lock;
  late final PendingInviteCubit _invite;
  late final LocaleCubit _locale;
  late final GoRouter _router;
  late final AppLifecycleListener _lifecycle;
  late final StreamSubscription<SessionState> _sessionToLock;
  late final StreamSubscription<SessionState> _sessionToSync;
  late final StreamSubscription<SessionState> _sessionToPush;
  late final StreamSubscription<String> _pushRoutes;
  late final SyncService _sync;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authRepositoryProvider);
    _session = SessionCubit(auth);
    _lock = AppLockCubit(
      store: ref.read(pinStoreProvider),
      biometrics: ref.read(biometricAuthProvider),
      onWipe: _session.signOut,
      onPinSet: () => auth.markPinSet().run(),
    );
    _invite = PendingInviteCubit();
    _locale = LocaleCubit();
    _sessionToLock = _session.stream.listen(
      (s) => _lock.userChanged(s is SignedIn ? s.user.uid : null),
    );
    // The sync engine follows whichever shop is signed in.
    _sync = ref.read(syncServiceProvider);
    // Files (voice clips) upload from the drift outbox whenever online.
    final outbox = ref.read(outboxDatabaseProvider);
    if (outbox != null) {
      _sync.watchOutbox(outbox);
      unawaited(ref.read(outboxUploaderProvider)!.start());
    }
    String? syncedShop;
    _sessionToSync = _session.stream.listen((s) {
      final shopId = s is SignedIn ? s.membership?.shopId : null;
      if (shopId == syncedShop) return;
      syncedShop = shopId;
      _sync.watchShop(
        shopId == null ? null : ref.read(ledgerRepositoryProvider),
        shopId,
      );
    });
    // The 06:00 Who To Ask push goes to Owner and Partner phones (PRD US2).
    final push = ref.read(pushRegistrationProvider);
    String? registeredFor;
    _sessionToPush = _session.stream.listen((s) {
      final m = s is SignedIn ? s.membership : null;
      if (s is! SignedIn || m == null) return;
      if (!m.role.can(Permission.insightsRead) || registeredFor == s.user.uid) {
        return;
      }
      registeredFor = s.user.uid;
      unawaited(push.register(s.user.uid));
    });
    _router = buildRouter(session: _session, lock: _lock, invite: _invite);
    // A tapped notification opens its screen (behind the lock, as usual).
    _pushRoutes = push.openedRoutes.listen(_router.go);
    _lifecycle = AppLifecycleListener(
      onPause: _lock.appPaused,
      onResume: _lock.appResumed,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _sessionToLock.cancel();
    _sessionToSync.cancel();
    _sessionToPush.cancel();
    _pushRoutes.cancel();
    _router.dispose();
    _session.close();
    _lock.close();
    _invite.close();
    _locale.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StoreProvider(
    store: _sync.store,
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _session),
        BlocProvider.value(value: _lock),
        BlocProvider.value(value: _invite),
        BlocProvider.value(value: _locale),
      ],
      // Any touch counts as activity for the 5-minute auto-lock.
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _lock.userActivity(),
        child: BlocBuilder<LocaleCubit, Locale>(
          builder: (context, locale) => MaterialApp.router(
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            locale: locale,
            supportedLocales: LocaleCubit.supported,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: _router,
          ),
        ),
      ),
    ),
  );
}
