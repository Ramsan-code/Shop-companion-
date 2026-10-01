import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/domain/session.dart';
import '../features/auth/presentation/session_cubit.dart';

extension CurrentShop on BuildContext {
  /// The signed-in user's membership. Shell screens are only reachable with
  /// one (see the router guard).
  Membership get membership {
    final session = read<SessionCubit>().state;
    return (session as SignedIn).membership!;
  }

  String get uid => (read<SessionCubit>().state as SignedIn).user.uid;
}
