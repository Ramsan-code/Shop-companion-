import '../core/failure.dart';
import 'l10n/app_localizations.dart';

/// User-facing text for a [Failure]. Never shows the technical message.
String failureMessage(AppLocalizations l10n, Failure failure) =>
    switch (failure) {
      ValidationFailure(message: 'phone') => l10n.errorPhone,
      ValidationFailure(message: 'code') => l10n.errorCode,
      ExpiredFailure() => l10n.errorExpired,
      RateLimitFailure() => l10n.errorRateLimit,
      NetworkFailure() => l10n.errorNetwork,
      PermissionFailure() => l10n.errorPermission,
      _ => l10n.errorGeneric,
    };
