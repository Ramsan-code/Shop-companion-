import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Tamil first (PRD 2); English on request. Sinhala arrives in Release 2.
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit() : super(tamil);

  static const tamil = Locale('ta');
  static const english = Locale('en');
  static const supported = [tamil, english];

  void select(Locale locale) => emit(locale);
}
