import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Registers this phone for the 06:00 Who To Ask push (PRD US2): asks for
/// notification permission and keeps users/{uid}.fcmTokens current.
abstract interface class PushRegistration {
  Future<void> register(String uid);

  /// The route to open when the app was started from a notification.
  Stream<String> get openedRoutes;

  Future<void> dispose();
}

class FirebasePushRegistration implements PushRegistration {
  FirebasePushRegistration(this._messaging, this._db);

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _db;
  StreamSubscription<String>? _refresh;
  final _routes = StreamController<String>.broadcast();
  StreamSubscription<RemoteMessage>? _opened;

  @override
  Stream<String> get openedRoutes => _routes.stream;

  @override
  Future<void> register(String uid) async {
    try {
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await _messaging.getToken();
      if (token != null) await _save(uid, token);
      await _refresh?.cancel();
      _refresh = _messaging.onTokenRefresh.listen((t) => _save(uid, t));
      _opened ??= FirebaseMessaging.onMessageOpenedApp.listen(_open);
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _open(initial);
    } on Exception {
      // No Google Play services or no network: try again next start.
    }
  }

  void _open(RemoteMessage message) {
    final route = message.data['route'];
    if (route is String && route.startsWith('/')) _routes.add(route);
  }

  Future<void> _save(String uid, String token) => _db
      .doc('users/$uid')
      .update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      })
      .catchError((Object _) {});

  @override
  Future<void> dispose() async {
    await _refresh?.cancel();
    await _opened?.cancel();
    await _routes.close();
  }
}

class NoPushRegistration implements PushRegistration {
  const NoPushRegistration();

  @override
  Future<void> register(String uid) async {}

  @override
  Stream<String> get openedRoutes => const Stream.empty();

  @override
  Future<void> dispose() async {}
}
