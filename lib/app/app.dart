import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/di/providers.dart';
import '../features/auth/presentation/session_cubit.dart';
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
  late final LocaleCubit _locale;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _session = SessionCubit(ref.read(authRepositoryProvider));
    _locale = LocaleCubit();
    _router = buildRouter(_session);
  }

  @override
  void dispose() {
    _router.dispose();
    _session.close();
    _locale.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: _session),
      BlocProvider.value(value: _locale),
    ],
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
  );
}
