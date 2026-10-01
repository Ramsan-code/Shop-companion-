import 'package:fpdart/fpdart.dart';

import '../../../core/failure.dart';
import '../../../core/rbac/role.dart';
import 'session.dart';

/// Progress of a phone OTP sign-in (PRD C10, flow 7.1-1).
sealed class PhoneAuthEvent {
  const PhoneAuthEvent();
}

/// The SMS was sent; wait for the code (or for Android to read it).
final class CodeSent extends PhoneAuthEvent {
  const CodeSent(this.verificationId, {this.resendToken});

  final String verificationId;
  final int? resendToken;
}

/// Android read the SMS itself and the user is now signed in.
final class AutoVerified extends PhoneAuthEvent {
  const AutoVerified();
}

final class PhoneAuthFailed extends PhoneAuthEvent {
  const PhoneAuthFailed(this.failure);

  final Failure failure;
}

/// What an invite link turned into after `acceptInvite`.
class JoinedShop {
  const JoinedShop({required this.shopId, required this.role});

  final String shopId;
  final Role role;
}

abstract interface class AuthRepository {
  /// Signed out → signed in → shop membership, kept live from Firestore so a
  /// new phone restores everything after OTP (US8).
  Stream<SessionState> watchSession();

  /// Sends the OTP to [e164Phone]. The stream ends after [AutoVerified] or
  /// [PhoneAuthFailed]; after [CodeSent] it stays open for auto-read.
  Stream<PhoneAuthEvent> startPhoneSignIn(String e164Phone, {int? resendToken});

  AsyncResult<Unit> confirmCode({
    required String verificationId,
    required String smsCode,
  });

  /// `createShop` callable: the signed-in user becomes the owner.
  AsyncResult<Unit> createShop({required String name});

  /// `acceptInvite` callable for a `/invite/{token}` link.
  AsyncResult<JoinedShop> acceptInvite(String token);

  /// Records on the profile that a PIN exists (the PIN itself never leaves
  /// the phone).
  AsyncResult<Unit> markPinSet();

  AsyncResult<Unit> signOut();
}

/// Implemented by the fake backend only: jump into a role's shell.
abstract interface class DebugSignIn {
  AsyncResult<Unit> debugSignInAs(Role role);
}
