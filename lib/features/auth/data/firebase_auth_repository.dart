import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:rxdart/rxdart.dart';

import '../../../core/failure.dart';
import '../../../core/rbac/role.dart';
import '../domain/auth_repository.dart';
import '../domain/session.dart';
import 'firebase_errors.dart';

/// Firebase phone OTP + the shop callables (PRD 6.1, 10.3).
///
/// The session comes from `users/{uid}.activeShopId` (written only by
/// functions), then the member and shop documents. Firestore's offline cache
/// keeps it working without signal once the phone has been online once.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required this._auth,
    required FirebaseFirestore firestore,
    required this._functions,
  }) : _db = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  @override
  Stream<SessionState> watchSession() => _auth.authStateChanges().switchMap((
    user,
  ) {
    if (user == null) return Stream.value(const SignedOut());
    final appUser = AppUser(uid: user.uid, phone: user.phoneNumber ?? '');
    final signedInNoShop = SignedIn(appUser);
    return _db
        .doc('users/${user.uid}')
        .snapshots()
        .map((doc) => doc.data()?['activeShopId'] as String?)
        .distinct()
        .switchMap((shopId) {
          if (shopId == null) return Stream.value(signedInNoShop);
          return _membership(user.uid, shopId).map(
            (m) =>
                m == null ? signedInNoShop : SignedIn(appUser, membership: m),
          );
        })
        // A removed member loses read access mid-stream; treat it as
        // "no shop" rather than an error.
        .onErrorReturn(signedInNoShop);
  });

  Stream<Membership?> _membership(String uid, String shopId) =>
      _db.doc('shops/$shopId/members/$uid').snapshots().switchMap((member) {
        final data = member.data();
        final role = Role.fromWire(data?['role'] as String? ?? '');
        if (data?['status'] != 'active' || role == null) {
          return Stream<Membership?>.value(null);
        }
        return _db
            .doc('shops/$shopId')
            .snapshots()
            .map<Membership?>(
              (shop) => Membership(
                shopId: shopId,
                shopName: shop.data()?['name'] as String? ?? '',
                role: role,
              ),
            );
      });

  @override
  Stream<PhoneAuthEvent> startPhoneSignIn(
    String e164Phone, {
    int? resendToken,
  }) {
    late final StreamController<PhoneAuthEvent> controller;
    controller = StreamController<PhoneAuthEvent>(
      onListen: () async {
        try {
          await _auth.verifyPhoneNumber(
            phoneNumber: e164Phone,
            forceResendingToken: resendToken,
            timeout: const Duration(seconds: 60),
            // SMS auto-read on Android: sign in without typing the code.
            verificationCompleted: (credential) async {
              try {
                await _auth.signInWithCredential(credential);
                await _ensureProfile();
                controller.add(const AutoVerified());
              } on Exception catch (e) {
                controller.add(PhoneAuthFailed(failureFromFirebase(e)));
              }
              await controller.close();
            },
            verificationFailed: (e) {
              controller.add(PhoneAuthFailed(failureFromFirebase(e)));
              controller.close();
            },
            codeSent: (verificationId, token) =>
                controller.add(CodeSent(verificationId, resendToken: token)),
            codeAutoRetrievalTimeout: (_) {},
          );
        } on Exception catch (e) {
          controller.add(PhoneAuthFailed(failureFromFirebase(e)));
          await controller.close();
        }
      },
    );
    return controller.stream;
  }

  @override
  AsyncResult<Unit> confirmCode({
    required String verificationId,
    required String smsCode,
  }) => _guard(() async {
    await _auth.signInWithCredential(
      PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      ),
    );
    await _ensureProfile();
  });

  /// Creates `users/{uid}` on first sign-in (rules allow only these fields).
  Future<void> _ensureProfile() async {
    final user = _auth.currentUser!;
    final ref = _db.doc('users/${user.uid}');
    if ((await ref.get()).exists) return;
    await ref.set({
      'phone': user.phoneNumber,
      'locale': 'ta',
      'pinSet': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  AsyncResult<Unit> createShop({required String name}) => _guard(() async {
    await _functions.httpsCallable('createShop').call<Object?>({'name': name});
    await _refreshClaims();
  });

  @override
  AsyncResult<JoinedShop> acceptInvite(String token) =>
      TaskEither.tryCatch(() async {
        final result = await _functions
            .httpsCallable('acceptInvite')
            .call<Map<String, dynamic>>({'token': token});
        await _refreshClaims();
        final role = Role.fromWire(result.data['role'] as String);
        if (role == null) throw StateError('unknown role');
        return JoinedShop(shopId: result.data['shopId'] as String, role: role);
      }, (e, _) => failureFromFirebase(e));

  /// PRD 6.1-4: the app force-refreshes the ID token after membership changes.
  Future<void> _refreshClaims() async => _auth.currentUser?.getIdToken(true);

  @override
  AsyncResult<Unit> markPinSet() => _guard(() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('signed out');
    await _db.doc('users/$uid').update({'pinSet': true});
  });

  @override
  AsyncResult<Unit> signOut() => _guard(_auth.signOut);

  AsyncResult<Unit> _guard(Future<void> Function() body) =>
      TaskEither.tryCatch(() async {
        await body();
        return unit;
      }, (e, _) => failureFromFirebase(e));
}
