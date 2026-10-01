import 'package:flutter_bloc/flutter_bloc.dart';

/// The token from a `/invite/{token}` link, kept through login and PIN setup
/// until the join screen uses it.
class PendingInviteCubit extends Cubit<String?> {
  PendingInviteCubit() : super(null);

  void capture(String token) {
    if (token.isNotEmpty) emit(token);
  }

  void clear() => emit(null);
}
