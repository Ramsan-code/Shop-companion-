import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/failure.dart';
import '../../../core/phone.dart';
import '../domain/auth_repository.dart';

/// Login screen state: enter phone → enter (or auto-read) code.
sealed class PhoneAuthState extends Equatable {
  const PhoneAuthState({this.failure});

  final Failure? failure;

  @override
  List<Object?> get props => [runtimeType, failure];
}

final class EnterPhone extends PhoneAuthState {
  const EnterPhone({super.failure});
}

final class SendingCode extends PhoneAuthState {
  const SendingCode();
}

final class EnterCode extends PhoneAuthState {
  const EnterCode({
    required this.phone,
    required this.verificationId,
    this.resendToken,
    this.verifying = false,
    super.failure,
  });

  final String phone;
  final String verificationId;
  final int? resendToken;
  final bool verifying;

  EnterCode copyWith({bool? verifying, Failure? failure}) => EnterCode(
    phone: phone,
    verificationId: verificationId,
    resendToken: resendToken,
    verifying: verifying ?? this.verifying,
    failure: failure,
  );

  @override
  List<Object?> get props => [...super.props, phone, verificationId, verifying];
}

/// Signed in. The session stream takes over routing from here.
final class PhoneVerified extends PhoneAuthState {
  const PhoneVerified();
}

class PhoneAuthCubit extends Cubit<PhoneAuthState> {
  PhoneAuthCubit(this._repository) : super(const EnterPhone());

  final AuthRepository _repository;
  StreamSubscription<PhoneAuthEvent>? _verification;

  Future<void> sendCode(String input, {int? resendToken}) async {
    final phone = normalizeLkMobile(input);
    if (phone == null) {
      emit(const EnterPhone(failure: ValidationFailure('phone')));
      return;
    }
    emit(const SendingCode());
    await _verification?.cancel();
    _verification = _repository
        .startPhoneSignIn(phone, resendToken: resendToken)
        .listen(
          (event) => switch (event) {
            CodeSent(:final verificationId, :final resendToken) => emit(
              EnterCode(
                phone: phone,
                verificationId: verificationId,
                resendToken: resendToken,
              ),
            ),
            AutoVerified() => emit(const PhoneVerified()),
            PhoneAuthFailed(:final failure) => emit(
              state is EnterCode
                  ? (state as EnterCode).copyWith(failure: failure)
                  : EnterPhone(failure: failure),
            ),
          },
        );
  }

  Future<void> resend() async {
    final current = state;
    if (current is EnterCode) {
      await sendCode(current.phone, resendToken: current.resendToken);
    }
  }

  Future<void> confirm(String code) async {
    final current = state;
    if (current is! EnterCode || current.verifying) return;
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      emit(current.copyWith(failure: const ValidationFailure('code')));
      return;
    }
    emit(current.copyWith(verifying: true));
    final result = await _repository
        .confirmCode(verificationId: current.verificationId, smsCode: code)
        .run();
    result.match(
      (failure) => emit(current.copyWith(failure: failure)),
      (_) => emit(const PhoneVerified()),
    );
  }

  void changeNumber() {
    _verification?.cancel();
    emit(const EnterPhone());
  }

  @override
  Future<void> close() async {
    await _verification?.cancel();
    return super.close();
  }
}
