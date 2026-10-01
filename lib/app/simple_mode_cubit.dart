import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/preferences.dart';

/// Low-literacy mode (PRD N10): an icon-first home where every button can
/// say what it does. Remembered on this phone.
class SimpleModeCubit extends Cubit<bool> {
  SimpleModeCubit([this._prefs]) : super(false) {
    unawaited(_load());
  }

  final Preferences? _prefs;
  static const _key = 'simpleMode';

  Future<void> _load() async {
    final on = await _prefs?.getBool(_key);
    if (on != null && !isClosed) emit(on);
  }

  void set(bool on) {
    emit(on);
    unawaited(_prefs?.setBool(_key, on));
  }
}
