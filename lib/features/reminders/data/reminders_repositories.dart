import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:fpdart/fpdart.dart';
import 'package:rxdart/rxdart.dart';

import '../../../core/failure.dart';
import '../../auth/data/firebase_errors.dart';
import '../../ledger/domain/models.dart';
import '../domain/reminders.dart';

class FirestoreRemindersRepository implements RemindersRepository {
  FirestoreRemindersRepository({required this._db, required this._functions});

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  @override
  Stream<List<Reminder>> watchReminders(String shopId) => _db
      .collection('shops/$shopId/reminders')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map(
        (snap) => [
          for (final doc in snap.docs)
            Reminder(
              id: doc.id,
              customerId: doc.data()['customerId'] as String? ?? '',
              status:
                  ReminderStatus.values.byWire(doc.data()['status']) ??
                  ReminderStatus.queued,
              channel: doc.data()['channel'] as String?,
              createdAt: (doc.data()['createdAt'] as Timestamp?)?.toDate(),
              sentAt: (doc.data()['sentAt'] as Timestamp?)?.toDate(),
            ),
        ],
      )
      .onErrorReturn(const []);

  AsyncResult<T> _call<T>(
    String name,
    Map<String, Object?> data,
    T Function(Map<String, dynamic>) read,
  ) => TaskEither.tryCatch(() async {
    final result = await _functions
        .httpsCallable(name)
        .call<Map<String, dynamic>>(data);
    return read(result.data);
  }, (e, _) => failureFromFirebase(e));

  @override
  AsyncResult<int> decide(
    String shopId,
    List<String> reminderIds, {
    required bool approve,
  }) => _call('approveReminders', {
    'shopId': shopId,
    'reminderIds': reminderIds,
    'approve': approve,
  }, (d) => d['updated'] as int? ?? 0);

  @override
  AsyncResult<String> preview(
    String shopId,
    String customerId,
    ReminderTone tone,
    ReminderLang lang,
  ) => _call('previewReminder', {
    'shopId': shopId,
    'customerId': customerId,
    'tone': tone.name,
    'lang': lang.name,
  }, (d) => d['text'] as String? ?? '');

  @override
  AsyncResult<String> statementLink(String shopId, String customerId) => _call(
    'createStatement',
    {'shopId': shopId, 'customerId': customerId},
    (d) => d['url'] as String,
  );

  @override
  Stream<ReminderSettings> watchSettings(String shopId) =>
      _db.doc('shops/$shopId').snapshots().map((doc) {
        final d = doc.data() ?? const {};
        final s = d['settings'] as Map<String, dynamic>? ?? const {};
        return ReminderSettings(
          autoReminders: s['autoReminders'] == true,
          approvalMode: s['approvalMode'] != false,
          tone: ReminderTone.values.byWire(s['tone']) ?? ReminderTone.gentle,
          lankaQrPayload: d['lankaQrPayload'] as String?,
          plan: d['plan'] as String? ?? 'free',
        );
      });

  @override
  Result<Unit> updateSettings(String shopId, ReminderSettings s) {
    unawaited(
      _db
          .doc('shops/$shopId')
          .update({
            'settings.autoReminders': s.autoReminders,
            'settings.approvalMode': s.approvalMode,
            'settings.tone': s.tone.name,
            'lankaQrPayload': s.lankaQrPayload,
          })
          .catchError((Object _) {}),
    );
    return right(unit);
  }
}

/// Fake backend and tests.
class InMemoryRemindersRepository implements RemindersRepository {
  InMemoryRemindersRepository({
    List<Reminder> reminders = const [],
    this._settings = const ReminderSettings(plan: 'pilot'),
  }) : _reminders = [...reminders];

  final List<Reminder> _reminders;
  ReminderSettings _settings;
  final previews = <(String, ReminderTone, ReminderLang)>[];
  final _changes = StreamController<void>.broadcast();

  ReminderSettings get settings => _settings;

  Stream<T> _watch<T>(T Function() read) => Stream.multi((controller) {
    controller.add(read());
    final sub = _changes.stream.listen((_) => controller.add(read()));
    // Don't hand back the cancel future: `.first` would wait on it.
    controller.onCancel = () => unawaited(sub.cancel());
  });

  @override
  Stream<List<Reminder>> watchReminders(String shopId) =>
      _watch(() => List.unmodifiable(_reminders));

  @override
  AsyncResult<int> decide(
    String shopId,
    List<String> reminderIds, {
    required bool approve,
  }) => TaskEither(() async {
    var n = 0;
    for (var i = 0; i < _reminders.length; i++) {
      final r = _reminders[i];
      if (!reminderIds.contains(r.id) ||
          r.status != ReminderStatus.pendingApproval) {
        continue;
      }
      _reminders[i] = Reminder(
        id: r.id,
        customerId: r.customerId,
        status: approve ? ReminderStatus.queued : ReminderStatus.cancelled,
        createdAt: r.createdAt,
      );
      n++;
    }
    _changes.add(null);
    return right(n);
  });

  @override
  AsyncResult<String> preview(
    String shopId,
    String customerId,
    ReminderTone tone,
    ReminderLang lang,
  ) => TaskEither(() async {
    previews.add((customerId, tone, lang));
    return right('[${tone.name}/${lang.name}] preview for $customerId');
  });

  @override
  AsyncResult<String> statementLink(String shopId, String customerId) =>
      TaskEither.of('https://shop-companion-dev.web.app/s/demo-$customerId');

  @override
  Stream<ReminderSettings> watchSettings(String shopId) =>
      _watch(() => _settings);

  @override
  Result<Unit> updateSettings(String shopId, ReminderSettings settings) {
    _settings = settings;
    _changes.add(null);
    return right(unit);
  }

  Future<void> dispose() => _changes.close();
}
