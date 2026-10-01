import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ta'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop Companion'**
  String get appTitle;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get tabCustomers;

  /// No description provided for @tabMic.
  ///
  /// In en, this message translates to:
  /// **'Speak'**
  String get tabMic;

  /// No description provided for @tabStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get tabStock;

  /// No description provided for @tabMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get tabMore;

  /// No description provided for @tabEntry.
  ///
  /// In en, this message translates to:
  /// **'Entry'**
  String get tabEntry;

  /// No description provided for @tabCloseDay.
  ///
  /// In en, this message translates to:
  /// **'Close Day'**
  String get tabCloseDay;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Your phone number'**
  String get loginTitle;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneLabel;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'What is your shop called?'**
  String get setupTitle;

  /// No description provided for @shopNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Shop name'**
  String get shopNameLabel;

  /// No description provided for @createShopButton.
  ///
  /// In en, this message translates to:
  /// **'Start my shop'**
  String get createShopButton;

  /// No description provided for @devSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Developer sign-in'**
  String get devSignInTitle;

  /// No description provided for @devSignInBody.
  ///
  /// In en, this message translates to:
  /// **'Fake backend: pick a role to see its screens.'**
  String get devSignInBody;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @rolePartner.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get rolePartner;

  /// No description provided for @roleHelper.
  ///
  /// In en, this message translates to:
  /// **'Helper'**
  String get roleHelper;

  /// No description provided for @comingInPhase.
  ///
  /// In en, this message translates to:
  /// **'This screen is built in Phase {phase}.'**
  String comingInPhase(int phase);

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @micTitle.
  ///
  /// In en, this message translates to:
  /// **'Say or type an entry'**
  String get micTitle;

  /// No description provided for @micHint.
  ///
  /// In en, this message translates to:
  /// **'For example: Ravi annai 500 kadan'**
  String get micHint;

  /// No description provided for @parsedCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get parsedCustomer;

  /// No description provided for @parsedAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get parsedAmount;

  /// No description provided for @parsedType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get parsedType;

  /// No description provided for @parsedUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not heard'**
  String get parsedUnknown;

  /// No description provided for @typeCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit (kadan)'**
  String get typeCredit;

  /// No description provided for @typePayment.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get typePayment;

  /// No description provided for @typeSale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get typeSale;

  /// No description provided for @typeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get typeExpense;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'{shop} · {role}'**
  String signedInAs(String shop, String role);

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {phone}'**
  String otpTitle(String phone);

  /// No description provided for @otpLabel.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get otpLabel;

  /// No description provided for @otpAutoRead.
  ///
  /// In en, this message translates to:
  /// **'We will read the SMS for you if we can.'**
  String get otpAutoRead;

  /// No description provided for @verifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyButton;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Send the code again'**
  String get resendCode;

  /// No description provided for @changeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get changeNumber;

  /// No description provided for @errorPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a Sri Lankan mobile number, like 077 123 4567.'**
  String get errorPhone;

  /// No description provided for @errorCode.
  ///
  /// In en, this message translates to:
  /// **'That code is not right. Check the SMS and try again.'**
  String get errorCode;

  /// No description provided for @errorExpired.
  ///
  /// In en, this message translates to:
  /// **'This has expired. Please start again.'**
  String get errorExpired;

  /// No description provided for @errorRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait a little and try again.'**
  String get errorRateLimit;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your signal and try again.'**
  String get errorNetwork;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @pinSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a 4-digit PIN'**
  String get pinSetupTitle;

  /// No description provided for @pinSetupBody.
  ///
  /// In en, this message translates to:
  /// **'You will use it to open the app on this phone.'**
  String get pinSetupBody;

  /// No description provided for @pinConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the same PIN again'**
  String get pinConfirmTitle;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'The PINs did not match. Choose again.'**
  String get pinMismatch;

  /// No description provided for @lockTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get lockTitle;

  /// No description provided for @pinWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN. {count, plural, =1{1 try left} other{{count} tries left}}.'**
  String pinWrong(int count);

  /// No description provided for @useFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint'**
  String get useFingerprint;

  /// No description provided for @fingerprintReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock Shop Companion'**
  String get fingerprintReason;

  /// No description provided for @forgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN? Sign in again with OTP'**
  String get forgotPin;

  /// No description provided for @joinTitle.
  ///
  /// In en, this message translates to:
  /// **'You have been invited to a shop'**
  String get joinTitle;

  /// No description provided for @joinBody.
  ///
  /// In en, this message translates to:
  /// **'Join to record entries for this shop.'**
  String get joinBody;

  /// No description provided for @joinButton.
  ///
  /// In en, this message translates to:
  /// **'Join the shop'**
  String get joinButton;

  /// No description provided for @joinInvalid.
  ///
  /// In en, this message translates to:
  /// **'This invite is not valid any more. Ask the owner for a new one.'**
  String get joinInvalid;

  /// No description provided for @joinWrongPhone.
  ///
  /// In en, this message translates to:
  /// **'This invite was sent to a different phone number.'**
  String get joinWrongPhone;

  /// No description provided for @joinAlreadyMember.
  ///
  /// In en, this message translates to:
  /// **'You already belong to a shop.'**
  String get joinAlreadyMember;

  /// No description provided for @startOwnShop.
  ///
  /// In en, this message translates to:
  /// **'Start my own shop instead'**
  String get startOwnShop;

  /// No description provided for @membersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersTitle;

  /// No description provided for @membersEmpty.
  ///
  /// In en, this message translates to:
  /// **'Only you so far. Invite a partner or helper.'**
  String get membersEmpty;

  /// No description provided for @inviteMember.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get inviteMember;

  /// No description provided for @inviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite someone to your shop'**
  String get inviteTitle;

  /// No description provided for @inviteSend.
  ///
  /// In en, this message translates to:
  /// **'Create invite and share'**
  String get inviteSend;

  /// No description provided for @inviteShareText.
  ///
  /// In en, this message translates to:
  /// **'{shop} invites you to Shop Companion as {role}. Install the app from Play Store, then open this link from your phone ({phone}): {link}'**
  String inviteShareText(String shop, String role, String phone, String link);

  /// No description provided for @inviteCreated.
  ///
  /// In en, this message translates to:
  /// **'Invite created. It works for 7 days.'**
  String get inviteCreated;

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeMember;

  /// No description provided for @removeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {phone} from the shop? They will lose access straight away.'**
  String removeConfirm(String phone);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @errorPermission.
  ///
  /// In en, this message translates to:
  /// **'You are not allowed to do this.'**
  String get errorPermission;

  /// No description provided for @syncStale.
  ///
  /// In en, this message translates to:
  /// **'{count} not synced for over a day. Connect to the internet.'**
  String syncStale(int count);

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'{count} waiting to sync'**
  String syncPending(int count);

  /// No description provided for @syncOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline: saving on this phone'**
  String get syncOffline;

  /// No description provided for @syncDone.
  ///
  /// In en, this message translates to:
  /// **'All synced'**
  String get syncDone;

  /// No description provided for @syncConflicts.
  ///
  /// In en, this message translates to:
  /// **'{count} entries were refused by the server. Check them with the owner.'**
  String syncConflicts(int count);

  /// No description provided for @customersSearch.
  ///
  /// In en, this message translates to:
  /// **'Search name, village or phone'**
  String get customersSearch;

  /// No description provided for @addCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add customer'**
  String get addCustomer;

  /// No description provided for @editCustomer.
  ///
  /// In en, this message translates to:
  /// **'Edit customer'**
  String get editCustomer;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get customerName;

  /// No description provided for @customerPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get customerPhone;

  /// No description provided for @customerVillage.
  ///
  /// In en, this message translates to:
  /// **'Village (optional)'**
  String get customerVillage;

  /// No description provided for @kinshipLabel.
  ///
  /// In en, this message translates to:
  /// **'How you address them'**
  String get kinshipLabel;

  /// No description provided for @kinNone.
  ///
  /// In en, this message translates to:
  /// **'Name only'**
  String get kinNone;

  /// No description provided for @kinAnnai.
  ///
  /// In en, this message translates to:
  /// **'annai'**
  String get kinAnnai;

  /// No description provided for @kinAkka.
  ///
  /// In en, this message translates to:
  /// **'akka'**
  String get kinAkka;

  /// No description provided for @kinAiya.
  ///
  /// In en, this message translates to:
  /// **'aiya'**
  String get kinAiya;

  /// No description provided for @kinAmma.
  ///
  /// In en, this message translates to:
  /// **'amma'**
  String get kinAmma;

  /// No description provided for @kinThambi.
  ///
  /// In en, this message translates to:
  /// **'thambi'**
  String get kinThambi;

  /// No description provided for @kinThangachi.
  ///
  /// In en, this message translates to:
  /// **'thangachi'**
  String get kinThangachi;

  /// No description provided for @kinMaama.
  ///
  /// In en, this message translates to:
  /// **'maama'**
  String get kinMaama;

  /// No description provided for @incomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Main income'**
  String get incomeLabel;

  /// No description provided for @incomeFarmer.
  ///
  /// In en, this message translates to:
  /// **'Farming'**
  String get incomeFarmer;

  /// No description provided for @incomeDailyWage.
  ///
  /// In en, this message translates to:
  /// **'Daily wage'**
  String get incomeDailyWage;

  /// No description provided for @incomeSalaried.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get incomeSalaried;

  /// No description provided for @incomeBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get incomeBusiness;

  /// No description provided for @incomeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get incomeOther;

  /// No description provided for @payDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Usually paid on day (1–31, optional)'**
  String get payDayLabel;

  /// No description provided for @fromContacts.
  ///
  /// In en, this message translates to:
  /// **'Pick from contacts'**
  String get fromContacts;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @noCustomers.
  ///
  /// In en, this message translates to:
  /// **'No customers yet. Add your first one.'**
  String get noCustomers;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No one matches.'**
  String get noResults;

  /// No description provided for @owes.
  ///
  /// In en, this message translates to:
  /// **'Owes'**
  String get owes;

  /// No description provided for @settled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get settled;

  /// No description provided for @advance.
  ///
  /// In en, this message translates to:
  /// **'Paid in advance'**
  String get advance;

  /// No description provided for @pendingSync.
  ///
  /// In en, this message translates to:
  /// **'Waiting to sync'**
  String get pendingSync;

  /// No description provided for @giveCredit.
  ///
  /// In en, this message translates to:
  /// **'Give credit'**
  String get giveCredit;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get recordPayment;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (Rs.)'**
  String get amountLabel;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteLabel;

  /// No description provided for @methodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get methodCash;

  /// No description provided for @methodBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get methodBank;

  /// No description provided for @methodLankaqr.
  ///
  /// In en, this message translates to:
  /// **'LankaQR'**
  String get methodLankaqr;

  /// No description provided for @methodWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get methodWallet;

  /// No description provided for @settleWithDiscount.
  ///
  /// In en, this message translates to:
  /// **'Settle and write off the remaining {amount}'**
  String settleWithDiscount(String amount);

  /// No description provided for @entrySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get entrySaved;

  /// No description provided for @errorAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount, like 500 or 1250.50.'**
  String get errorAmount;

  /// No description provided for @errorCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get errorCustomerName;

  /// No description provided for @errorPayDay.
  ///
  /// In en, this message translates to:
  /// **'Use a day from 1 to 31.'**
  String get errorPayDay;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @noEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries yet.'**
  String get noEntries;

  /// No description provided for @entryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get entryDeleted;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get editEntry;

  /// No description provided for @deleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get deleteEntry;

  /// No description provided for @deleteEntryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry? The balance will be corrected and the deletion is logged.'**
  String get deleteEntryConfirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @shareReceipt.
  ///
  /// In en, this message translates to:
  /// **'Share receipt'**
  String get shareReceipt;

  /// No description provided for @receiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment receipt'**
  String get receiptTitle;

  /// No description provided for @receiptFrom.
  ///
  /// In en, this message translates to:
  /// **'Received from'**
  String get receiptFrom;

  /// No description provided for @receiptBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance after this payment'**
  String get receiptBalance;

  /// No description provided for @receiptNo.
  ///
  /// In en, this message translates to:
  /// **'Receipt no.'**
  String get receiptNo;

  /// No description provided for @receiptMethod.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get receiptMethod;

  /// No description provided for @chooseCustomer.
  ///
  /// In en, this message translates to:
  /// **'Choose a customer'**
  String get chooseCustomer;

  /// No description provided for @typeDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get typeDiscount;

  /// No description provided for @cannotEditEntry.
  ///
  /// In en, this message translates to:
  /// **'Only the owner or partner can change this entry now.'**
  String get cannotEditEntry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
