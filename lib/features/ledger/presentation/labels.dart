import '../../../app/l10n/app_localizations.dart';
import '../domain/entry_type.dart';
import '../domain/models.dart';

extension KinshipLabel on Kinship {
  String label(AppLocalizations l10n) => switch (this) {
    Kinship.annai => l10n.kinAnnai,
    Kinship.akka => l10n.kinAkka,
    Kinship.aiya => l10n.kinAiya,
    Kinship.amma => l10n.kinAmma,
    Kinship.thambi => l10n.kinThambi,
    Kinship.thangachi => l10n.kinThangachi,
    Kinship.maama => l10n.kinMaama,
  };
}

extension IncomeLabel on IncomeType {
  String label(AppLocalizations l10n) => switch (this) {
    IncomeType.farmer => l10n.incomeFarmer,
    IncomeType.dailyWage => l10n.incomeDailyWage,
    IncomeType.salaried => l10n.incomeSalaried,
    IncomeType.business => l10n.incomeBusiness,
    IncomeType.other => l10n.incomeOther,
  };
}

extension MethodLabel on PaymentMethod {
  String label(AppLocalizations l10n) => switch (this) {
    PaymentMethod.cash => l10n.methodCash,
    PaymentMethod.bank => l10n.methodBank,
    PaymentMethod.lankaqr => l10n.methodLankaqr,
    PaymentMethod.wallet => l10n.methodWallet,
  };
}

extension EntryTypeLabel on EntryType {
  String label(AppLocalizations l10n) => switch (this) {
    EntryType.credit => l10n.typeCredit,
    EntryType.payment => l10n.typePayment,
    EntryType.sale => l10n.typeSale,
    EntryType.expense || EntryType.purchase => l10n.typeExpense,
    EntryType.discount => l10n.typeDiscount,
  };
}

/// "Ravi அண்ணை" in Tamil, "Ravi annai" in English.
String customerTitle(AppLocalizations l10n, Customer c) =>
    c.kinship == null ? c.name : '${c.name} ${c.kinship!.label(l10n)}';
