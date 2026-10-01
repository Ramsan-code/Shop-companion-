import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/preferences.dart';

/// Tamil first (PRD 2); English on request. Sinhala arrives in Release 2.
/// The choice is remembered on this phone.
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit([this._prefs]) : super(tamil) {
    unawaited(_load());
  }

  final Preferences? _prefs;

  static const tamil = Locale('ta');
  static const english = Locale('en');
  static const supported = [tamil, english];
  static const _key = 'locale';

  Future<void> _load() async {
    final code = await _prefs?.getString(_key);
    if (code == english.languageCode && !isClosed) emit(english);
  }

  void select(Locale locale) {
    emit(locale);
    unawaited(_prefs?.setString(_key, locale.languageCode));
  }
}
