import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/failure.dart';
import '../../ledger/domain/models.dart';

enum ReminderStatus {
  pendingApproval,
  queued,
  sent,
  delivered,
  read,
  failed,
  skipped,
  cancelled,
}

class Reminder extends Equatable {
  const Reminder({
    required this.id,
    required this.customerId,
    required this.status,
    this.channel,
    this.createdAt,
    this.sentAt,
  });

  final String id;
  final String customerId;
  final ReminderStatus status;

  /// whatsapp or sms, once sent.
  final String? channel;
  final DateTime? createdAt;
  final DateTime? sentAt;

  @override
  List<Object?> get props => [
    id,
    customerId,
    status,
    channel,
    createdAt,
    sentAt,
  ];
}

/// The reminder-related part of `shops/{shopId}` (PRD 10.1 settings).
class ReminderSettings extends Equatable {
  const ReminderSettings({
    this.autoReminders = false,
    this.approvalMode = true,
    this.tone = ReminderTone.gentle,
    this.lankaQrPayload,
    this.plan = 'free',
  });

  final bool autoReminders;

  /// The owner approves each automatic reminder before it goes (default on:
  /// PRD 13 risk "reminders hurt relationships").
  final bool approvalMode;
  final ReminderTone tone;
  final String? lankaQrPayload;
  final String plan;

  bool get planAllowsAutomatic => const {'pilot', 'plus', 'pro'}.contains(plan);

  ReminderSettings copyWith({
    bool? autoReminders,
    bool? approvalMode,
    ReminderTone? tone,
    String? lankaQrPayload,
  }) => ReminderSettings(
    autoReminders: autoReminders ?? this.autoReminders,
    approvalMode: approvalMode ?? this.approvalMode,
    tone: tone ?? this.tone,
    lankaQrPayload: lankaQrPayload ?? this.lankaQrPayload,
    plan: plan,
  );

  @override
  List<Object?> get props => [
    autoReminders,
    approvalMode,
    tone,
    lankaQrPayload,
    plan,
  ];
}

/// A LankaQR (EMVCo merchant-presented) payload: starts "000201", has a CRC.
bool looksLikeLankaQr(String payload) =>
    payload.startsWith('000201') &&
    payload.length >= 40 &&
    payload.length <= 512 &&
    payload.contains('6304');

abstract interface class RemindersRepository {
  Stream<List<Reminder>> watchReminders(String shopId);

  /// Send (approve) or cancel reminders waiting for approval.
  AsyncResult<int> decide(
    String shopId,
    List<String> reminderIds, {
    required bool approve,
  });

  /// The exact message, from the server's templates (PRD US3 tone preview).
  AsyncResult<String> preview(
    String shopId,
    String customerId,
    ReminderTone tone,
    ReminderLang lang,
  );

  /// A fresh statement link for sharing by hand (PRD N8, Free plan).
  AsyncResult<String> statementLink(String shopId, String customerId);

  Stream<ReminderSettings> watchSettings(String shopId);

  /// Owner only (Security Rules: shop:manage). A local write; works offline.
  Result<Unit> updateSettings(String shopId, ReminderSettings settings);
}
