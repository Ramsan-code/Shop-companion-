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
  String get devSignInBody => 'Fake backend: pick a role to see its screens.';

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

  @override
  String otpTitle(String phone) {
    return 'Enter the 6-digit code sent to $phone';
  }

  @override
  String get otpLabel => 'Code';

  @override
  String get otpAutoRead => 'We will read the SMS for you if we can.';

  @override
  String get verifyButton => 'Verify';

  @override
  String get resendCode => 'Send the code again';

  @override
  String get changeNumber => 'Change number';

  @override
  String get errorPhone =>
      'Enter a Sri Lankan mobile number, like 077 123 4567.';

  @override
  String get errorCode =>
      'That code is not right. Check the SMS and try again.';

  @override
  String get errorExpired => 'This has expired. Please start again.';

  @override
  String get errorRateLimit => 'Too many tries. Wait a little and try again.';

  @override
  String get errorNetwork => 'No connection. Check your signal and try again.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get pinSetupTitle => 'Choose a 4-digit PIN';

  @override
  String get pinSetupBody => 'You will use it to open the app on this phone.';

  @override
  String get pinConfirmTitle => 'Enter the same PIN again';

  @override
  String get pinMismatch => 'The PINs did not match. Choose again.';

  @override
  String get lockTitle => 'Enter your PIN';

  @override
  String pinWrong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tries left',
      one: '1 try left',
    );
    return 'Wrong PIN. $_temp0.';
  }

  @override
  String get useFingerprint => 'Use fingerprint';

  @override
  String get fingerprintReason => 'Unlock Shop Companion';

  @override
  String get forgotPin => 'Forgot PIN? Sign in again with OTP';

  @override
  String get joinTitle => 'You have been invited to a shop';

  @override
  String get joinBody => 'Join to record entries for this shop.';

  @override
  String get joinButton => 'Join the shop';

  @override
  String get joinInvalid =>
      'This invite is not valid any more. Ask the owner for a new one.';

  @override
  String get joinWrongPhone =>
      'This invite was sent to a different phone number.';

  @override
  String get joinAlreadyMember => 'You already belong to a shop.';

  @override
  String get startOwnShop => 'Start my own shop instead';

  @override
  String get membersTitle => 'Members';

  @override
  String get membersEmpty => 'Only you so far. Invite a partner or helper.';

  @override
  String get inviteMember => 'Invite';

  @override
  String get inviteTitle => 'Invite someone to your shop';

  @override
  String get inviteSend => 'Create invite and share';

  @override
  String inviteShareText(String shop, String role, String phone, String link) {
    return '$shop invites you to Shop Companion as $role. Install the app from Play Store, then open this link from your phone ($phone): $link';
  }

  @override
  String get inviteCreated => 'Invite created. It works for 7 days.';

  @override
  String get removeMember => 'Remove';

  @override
  String removeConfirm(String phone) {
    return 'Remove $phone from the shop? They will lose access straight away.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get errorPermission => 'You are not allowed to do this.';
}
