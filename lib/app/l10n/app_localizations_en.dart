// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Shop Companion';

  @override
  String get tabHome => 'Home';

  @override
  String get tabCustomers => 'Customers';

  @override
  String get tabMic => 'Speak';

  @override
  String get tabStock => 'Stock';

  @override
  String get tabMore => 'More';

  @override
  String get tabEntry => 'Entry';

  @override
  String get tabCloseDay => 'Close Day';

  @override
  String get loginTitle => 'Your phone number';

  @override
  String get phoneLabel => 'Phone number';

  @override
  String get continueButton => 'Continue';

  @override
  String get setupTitle => 'What is your shop called?';

  @override
  String get shopNameLabel => 'Shop name';

  @override
  String get createShopButton => 'Start my shop';

  @override
  String get devSignInTitle => 'Developer sign-in';

  @override
  String get devSignInBody =>
      'Phone OTP arrives in Phase 1. Pick a role to see its screens.';

  @override
  String get roleOwner => 'Owner';

  @override
  String get rolePartner => 'Partner';

  @override
  String get roleHelper => 'Helper';

  @override
  String comingInPhase(int phase) {
    return 'This screen is built in Phase $phase.';
  }

  @override
  String get signOut => 'Sign out';

  @override
  String get language => 'Language';

  @override
  String get micTitle => 'Say or type an entry';

  @override
  String get micHint => 'For example: Ravi annai 500 kadan';

  @override
  String get parsedCustomer => 'Customer';

  @override
  String get parsedAmount => 'Amount';

  @override
  String get parsedType => 'Type';

  @override
  String get parsedUnknown => 'Not heard';

  @override
  String get typeCredit => 'Credit (kadan)';

  @override
  String get typePayment => 'Payment received';

  @override
  String get typeSale => 'Sale';

  @override
  String get typeExpense => 'Expense';

  @override
  String signedInAs(String shop, String role) {
    return '$shop · $role';
  }
}
