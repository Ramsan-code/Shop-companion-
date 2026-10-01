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

  /// No description provided for @voiceListening.
  ///
  /// In en, this message translates to:
  /// **'Listening… say it like “Ravi annai 500 kadan”'**
  String get voiceListening;

  /// No description provided for @voiceThinking.
  ///
  /// In en, this message translates to:
  /// **'Working it out…'**
  String get voiceThinking;

  /// No description provided for @voiceHeard.
  ///
  /// In en, this message translates to:
  /// **'Heard: “{text}”'**
  String voiceHeard(String text);

  /// No description provided for @voiceWhichCustomer.
  ///
  /// In en, this message translates to:
  /// **'Which customer?'**
  String get voiceWhichCustomer;

  /// No description provided for @voiceNewCustomer.
  ///
  /// In en, this message translates to:
  /// **'New customer: {name}'**
  String voiceNewCustomer(String name);

  /// No description provided for @voiceSpeakAgain.
  ///
  /// In en, this message translates to:
  /// **'Speak again'**
  String get voiceSpeakAgain;

  /// No description provided for @voiceSayYes.
  ///
  /// In en, this message translates to:
  /// **'Say “சரி” or tap Save'**
  String get voiceSayYes;

  /// No description provided for @voiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This phone can\'t understand Tamil speech right now. Type it below.'**
  String get voiceUnavailable;

  /// No description provided for @voiceNoSpeech.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t hear anything. Speak again or type below.'**
  String get voiceNoSpeech;

  /// No description provided for @voicePermission.
  ///
  /// In en, this message translates to:
  /// **'Allow the microphone to use voice entry.'**
  String get voicePermission;

  /// No description provided for @voiceNetwork.
  ///
  /// In en, this message translates to:
  /// **'No Tamil speech without internet on this phone. Type it below.'**
  String get voiceNetwork;

  /// No description provided for @customerSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customerSearchLabel;

  /// No description provided for @addAsNew.
  ///
  /// In en, this message translates to:
  /// **'Add “{name}” as new'**
  String addAsNew(String name);

  /// No description provided for @whoToAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Who to ask today'**
  String get whoToAskTitle;

  /// No description provided for @whoToAskSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} people · {amount} due'**
  String whoToAskSummary(int count, String amount);

  /// No description provided for @whoToAskFallback.
  ///
  /// In en, this message translates to:
  /// **'Your full list for today arrives at 6 AM. For now, the highest dues:'**
  String get whoToAskFallback;

  /// No description provided for @whoToAskEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nobody to ask today.'**
  String get whoToAskEmpty;

  /// No description provided for @whoToAskPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid since this morning'**
  String get whoToAskPaid;

  /// No description provided for @whatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsApp;

  /// No description provided for @snooze.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get snooze;

  /// No description provided for @snooze3Days.
  ///
  /// In en, this message translates to:
  /// **'Ask in 3 days'**
  String get snooze3Days;

  /// No description provided for @snoozePayDay.
  ///
  /// In en, this message translates to:
  /// **'Ask on pay day ({day})'**
  String snoozePayDay(int day);

  /// No description provided for @snoozed.
  ///
  /// In en, this message translates to:
  /// **'Moved to later'**
  String get snoozed;

  /// No description provided for @whatsAppNudge.
  ///
  /// In en, this message translates to:
  /// **'Hello {name}, {shop} shows {amount} due on your account. Please pay when it suits you. Thank you.'**
  String whatsAppNudge(String name, String shop, String amount);

  /// No description provided for @bandExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get bandExcellent;

  /// No description provided for @bandGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get bandGood;

  /// No description provided for @bandWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get bandWatch;

  /// No description provided for @bandRisky.
  ///
  /// In en, this message translates to:
  /// **'Risky'**
  String get bandRisky;

  /// No description provided for @trustScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Trust {score}/100'**
  String trustScoreLabel(int score);

  /// No description provided for @reasonNewCustomer.
  ///
  /// In en, this message translates to:
  /// **'New customer'**
  String get reasonNewCustomer;

  /// No description provided for @reasonOverdue.
  ///
  /// In en, this message translates to:
  /// **'Oldest credit unpaid for {days} days'**
  String reasonOverdue(int days);

  /// No description provided for @reasonRegularPayer.
  ///
  /// In en, this message translates to:
  /// **'Paid {count} times in 3 months'**
  String reasonRegularPayer(int count);

  /// No description provided for @reasonNoRecentPayment.
  ///
  /// In en, this message translates to:
  /// **'No payment in 3 months'**
  String get reasonNoRecentPayment;

  /// No description provided for @reasonPaysMost.
  ///
  /// In en, this message translates to:
  /// **'Pays back most of the credit ({pct}%)'**
  String reasonPaysMost(int pct);

  /// No description provided for @reasonPaysLittle.
  ///
  /// In en, this message translates to:
  /// **'Pays back little of the credit ({pct}%)'**
  String reasonPaysLittle(int pct);

  /// No description provided for @reasonHighBalance.
  ///
  /// In en, this message translates to:
  /// **'Owes much more than usual'**
  String get reasonHighBalance;

  /// No description provided for @reasonLongCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer for {months} months'**
  String reasonLongCustomer(int months);

  /// No description provided for @reasonSettled.
  ///
  /// In en, this message translates to:
  /// **'Account settled'**
  String get reasonSettled;

  /// No description provided for @reasonPayDay.
  ///
  /// In en, this message translates to:
  /// **'Pay day is the {day}th: ask now'**
  String reasonPayDay(int day);

  /// No description provided for @safeLimit.
  ///
  /// In en, this message translates to:
  /// **'Safe credit limit: {amount}'**
  String safeLimit(String amount);

  /// No description provided for @safeLimitOverridden.
  ///
  /// In en, this message translates to:
  /// **'Set by the owner'**
  String get safeLimitOverridden;

  /// No description provided for @changeLimit.
  ///
  /// In en, this message translates to:
  /// **'Change limit'**
  String get changeLimit;

  /// No description provided for @changeLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Safe credit limit for {name}'**
  String changeLimitTitle(String name);

  /// No description provided for @useSuggestedLimit.
  ///
  /// In en, this message translates to:
  /// **'Use the suggested limit ({amount})'**
  String useSuggestedLimit(String amount);

  /// No description provided for @overLimitWarning.
  ///
  /// In en, this message translates to:
  /// **'This takes {name} to {after}, above the safe limit of {limit}.'**
  String overLimitWarning(String name, String after, String limit);

  /// No description provided for @giveAnyway.
  ///
  /// In en, this message translates to:
  /// **'Give the credit anyway'**
  String get giveAnyway;

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTitle;

  /// No description provided for @reminderSection.
  ///
  /// In en, this message translates to:
  /// **'Payment reminders'**
  String get reminderSection;

  /// No description provided for @reminderConsent.
  ///
  /// In en, this message translates to:
  /// **'Customer agreed to get reminders'**
  String get reminderConsent;

  /// No description provided for @reminderConsentHelp.
  ///
  /// In en, this message translates to:
  /// **'Needed before any automatic message is sent (PDPA).'**
  String get reminderConsentHelp;

  /// No description provided for @toneShopDefault.
  ///
  /// In en, this message translates to:
  /// **'Shop default'**
  String get toneShopDefault;

  /// No description provided for @toneGentle.
  ///
  /// In en, this message translates to:
  /// **'Gentle'**
  String get toneGentle;

  /// No description provided for @toneNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get toneNormal;

  /// No description provided for @toneFirm.
  ///
  /// In en, this message translates to:
  /// **'Firm'**
  String get toneFirm;

  /// No description provided for @reminderLanguage.
  ///
  /// In en, this message translates to:
  /// **'Message language'**
  String get reminderLanguage;

  /// No description provided for @previewMessage.
  ///
  /// In en, this message translates to:
  /// **'Preview the message'**
  String get previewMessage;

  /// No description provided for @previewNeedsSave.
  ///
  /// In en, this message translates to:
  /// **'Save the customer first to preview.'**
  String get previewNeedsSave;

  /// No description provided for @shareStatement.
  ///
  /// In en, this message translates to:
  /// **'Share statement'**
  String get shareStatement;

  /// No description provided for @statementShareText.
  ///
  /// In en, this message translates to:
  /// **'{name}, here is your account at {shop}. You can check it, confirm it or pay with LankaQR: {link}'**
  String statementShareText(String name, String shop, String link);

  /// No description provided for @optedOutChip.
  ///
  /// In en, this message translates to:
  /// **'Stopped reminders (STOP)'**
  String get optedOutChip;

  /// No description provided for @disputeChip.
  ///
  /// In en, this message translates to:
  /// **'Disputed the statement'**
  String get disputeChip;

  /// No description provided for @autoReminders.
  ///
  /// In en, this message translates to:
  /// **'Send reminders automatically'**
  String get autoReminders;

  /// No description provided for @autoRemindersHelp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp first, SMS if no WhatsApp. 8 AM–8 PM only, at most one every 3 days per customer, only with their consent.'**
  String get autoRemindersHelp;

  /// No description provided for @approvalMode.
  ///
  /// In en, this message translates to:
  /// **'I approve each reminder first'**
  String get approvalMode;

  /// No description provided for @defaultTone.
  ///
  /// In en, this message translates to:
  /// **'Default tone'**
  String get defaultTone;

  /// No description provided for @lankaQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Your LankaQR'**
  String get lankaQrTitle;

  /// No description provided for @lankaQrHelp.
  ///
  /// In en, this message translates to:
  /// **'Shown on statements so customers can pay you directly.'**
  String get lankaQrHelp;

  /// No description provided for @lankaQrNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set yet'**
  String get lankaQrNotSet;

  /// No description provided for @scanLankaQr.
  ///
  /// In en, this message translates to:
  /// **'Scan your LankaQR sticker'**
  String get scanLankaQr;

  /// No description provided for @lankaQrInvalid.
  ///
  /// In en, this message translates to:
  /// **'That is not a LankaQR payment code. Scan the shop\'s LankaQR sticker.'**
  String get lankaQrInvalid;

  /// No description provided for @pendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your approval'**
  String get pendingApproval;

  /// No description provided for @approveAll.
  ///
  /// In en, this message translates to:
  /// **'Send all'**
  String get approveAll;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get approve;

  /// No description provided for @recentReminders.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentReminders;

  /// No description provided for @noReminders.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet.'**
  String get noReminders;

  /// No description provided for @statusQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get statusQueued;

  /// No description provided for @statusSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get statusSent;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get statusRead;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @statusSkipped.
  ///
  /// In en, this message translates to:
  /// **'Not sent'**
  String get statusSkipped;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get statusPending;

  /// No description provided for @viaSms.
  ///
  /// In en, this message translates to:
  /// **'by SMS'**
  String get viaSms;

  /// No description provided for @remindersPlanNote.
  ///
  /// In en, this message translates to:
  /// **'Automatic reminders are part of the Plus plan.'**
  String get remindersPlanNote;

  /// No description provided for @catGrocery.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get catGrocery;

  /// No description provided for @catVegetables.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get catVegetables;

  /// No description provided for @catBakery.
  ///
  /// In en, this message translates to:
  /// **'Bakery'**
  String get catBakery;

  /// No description provided for @catPhoneCredit.
  ///
  /// In en, this message translates to:
  /// **'Phone reload'**
  String get catPhoneCredit;

  /// No description provided for @catOtherSale.
  ///
  /// In en, this message translates to:
  /// **'Other sale'**
  String get catOtherSale;

  /// No description provided for @catStockPurchase.
  ///
  /// In en, this message translates to:
  /// **'Stock bought'**
  String get catStockPurchase;

  /// No description provided for @catTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get catTransport;

  /// No description provided for @catElectricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get catElectricity;

  /// No description provided for @catWages.
  ///
  /// In en, this message translates to:
  /// **'Wages'**
  String get catWages;

  /// No description provided for @catRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get catRent;

  /// No description provided for @catOtherExpense.
  ///
  /// In en, this message translates to:
  /// **'Other expense'**
  String get catOtherExpense;

  /// No description provided for @recordSale.
  ///
  /// In en, this message translates to:
  /// **'Record a sale'**
  String get recordSale;

  /// No description provided for @recordExpense.
  ///
  /// In en, this message translates to:
  /// **'Record money spent'**
  String get recordExpense;

  /// No description provided for @chooseCategory.
  ///
  /// In en, this message translates to:
  /// **'What for?'**
  String get chooseCategory;

  /// No description provided for @paidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get paidBy;

  /// No description provided for @closeDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Close the day'**
  String get closeDayTitle;

  /// No description provided for @closeDayCreditGiven.
  ///
  /// In en, this message translates to:
  /// **'Credit given'**
  String get closeDayCreditGiven;

  /// No description provided for @closeDayCollected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get closeDayCollected;

  /// No description provided for @closeDaySpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get closeDaySpent;

  /// No description provided for @closeDayOpening.
  ///
  /// In en, this message translates to:
  /// **'Cash at start of day'**
  String get closeDayOpening;

  /// No description provided for @closeDayExpected.
  ///
  /// In en, this message translates to:
  /// **'Cash that should be in the drawer'**
  String get closeDayExpected;

  /// No description provided for @closeDayCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Cash counted (Rs.)'**
  String get closeDayCountLabel;

  /// No description provided for @closeDaySayCount.
  ///
  /// In en, this message translates to:
  /// **'Say the amount'**
  String get closeDaySayCount;

  /// No description provided for @closeDaySave.
  ///
  /// In en, this message translates to:
  /// **'Close the day'**
  String get closeDaySave;

  /// No description provided for @closeDayMatch.
  ///
  /// In en, this message translates to:
  /// **'Cash matches. Well done!'**
  String get closeDayMatch;

  /// No description provided for @closeDayShort.
  ///
  /// In en, this message translates to:
  /// **'{amount} short in the drawer'**
  String closeDayShort(String amount);

  /// No description provided for @closeDayOver.
  ///
  /// In en, this message translates to:
  /// **'{amount} extra in the drawer'**
  String closeDayOver(String amount);

  /// No description provided for @profitMirror.
  ///
  /// In en, this message translates to:
  /// **'Today you made about {amount}'**
  String profitMirror(String amount);

  /// No description provided for @profitMirrorLoss.
  ///
  /// In en, this message translates to:
  /// **'Today spending was {amount} more than the profit'**
  String profitMirrorLoss(String amount);

  /// No description provided for @profitMirrorHow.
  ///
  /// In en, this message translates to:
  /// **'An estimate: {margin}% of sales, minus what was spent.'**
  String profitMirrorHow(int margin);

  /// No description provided for @closeDayListen.
  ///
  /// In en, this message translates to:
  /// **'Hear the summary'**
  String get closeDayListen;

  /// No description provided for @closeDaySpoken.
  ///
  /// In en, this message translates to:
  /// **'Today: sales {sales}, collected {collected}, spent {spent}. Profit about {profit}.'**
  String closeDaySpoken(
    String sales,
    String collected,
    String spent,
    String profit,
  );

  /// No description provided for @rupeesSpoken.
  ///
  /// In en, this message translates to:
  /// **'{amount} rupees'**
  String rupeesSpoken(String amount);

  /// No description provided for @tomorrowTitle.
  ///
  /// In en, this message translates to:
  /// **'For tomorrow'**
  String get tomorrowTitle;

  /// No description provided for @tomorrowAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask {name} for {amount}'**
  String tomorrowAsk(String name, String amount);

  /// No description provided for @tomorrowRestock.
  ///
  /// In en, this message translates to:
  /// **'Buy more {item}'**
  String tomorrowRestock(String item);

  /// No description provided for @tomorrowNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing to follow up.'**
  String get tomorrowNothing;

  /// No description provided for @countSaved.
  ///
  /// In en, this message translates to:
  /// **'Count saved. The owner will see it.'**
  String get countSaved;

  /// No description provided for @helperCountHelp.
  ///
  /// In en, this message translates to:
  /// **'Count the cash in the drawer and enter it here.'**
  String get helperCountHelp;

  /// No description provided for @yourCount.
  ///
  /// In en, this message translates to:
  /// **'Your count: {amount}'**
  String yourCount(String amount);

  /// No description provided for @closingRecorded.
  ///
  /// In en, this message translates to:
  /// **'Saved for the shop'**
  String get closingRecorded;

  /// No description provided for @stockLow.
  ///
  /// In en, this message translates to:
  /// **'Running low'**
  String get stockLow;

  /// No description provided for @stockAll.
  ///
  /// In en, this message translates to:
  /// **'All items'**
  String get stockAll;

  /// No description provided for @stockEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items yet. Add what you sell most.'**
  String get stockEmpty;

  /// No description provided for @stockAdd.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get stockAdd;

  /// No description provided for @stockEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get stockEdit;

  /// No description provided for @stockName.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get stockName;

  /// No description provided for @stockUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit (kg, packet)'**
  String get stockUnit;

  /// No description provided for @stockQty.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get stockQty;

  /// No description provided for @stockLowAt.
  ///
  /// In en, this message translates to:
  /// **'Warn me at'**
  String get stockLowAt;

  /// No description provided for @stockCost.
  ///
  /// In en, this message translates to:
  /// **'Buying price (Rs.)'**
  String get stockCost;

  /// No description provided for @stockPrice.
  ///
  /// In en, this message translates to:
  /// **'Selling price (Rs.)'**
  String get stockPrice;

  /// No description provided for @stockLowCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items running low'**
  String stockLowCount(int count);

  /// No description provided for @stockAddOne.
  ///
  /// In en, this message translates to:
  /// **'Add one'**
  String get stockAddOne;

  /// No description provided for @stockTakeOne.
  ///
  /// In en, this message translates to:
  /// **'Take one away'**
  String get stockTakeOne;

  /// No description provided for @stockUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update stock'**
  String get stockUpdate;

  /// No description provided for @simpleMode.
  ///
  /// In en, this message translates to:
  /// **'Simple mode'**
  String get simpleMode;

  /// No description provided for @simpleModeHelp.
  ///
  /// In en, this message translates to:
  /// **'Big pictures. Tap the speaker on a button to hear what it does.'**
  String get simpleModeHelp;

  /// No description provided for @hearThis.
  ///
  /// In en, this message translates to:
  /// **'Hear this'**
  String get hearThis;

  /// No description provided for @whoToAskShort.
  ///
  /// In en, this message translates to:
  /// **'Who to ask'**
  String get whoToAskShort;

  /// No description provided for @helpCredit.
  ///
  /// In en, this message translates to:
  /// **'Give credit: write down what a customer takes on credit.'**
  String get helpCredit;

  /// No description provided for @helpPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment: write down money a customer paid back.'**
  String get helpPayment;

  /// No description provided for @helpSale.
  ///
  /// In en, this message translates to:
  /// **'Sale: write down cash sales.'**
  String get helpSale;

  /// No description provided for @helpExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense: write down money spent for the shop.'**
  String get helpExpense;

  /// No description provided for @helpMic.
  ///
  /// In en, this message translates to:
  /// **'Speak: say the entry, like Ravi annai five hundred credit.'**
  String get helpMic;

  /// No description provided for @helpCloseDay.
  ///
  /// In en, this message translates to:
  /// **'Close the day: count the cash and see today\'s profit.'**
  String get helpCloseDay;

  /// No description provided for @helpWhoToAsk.
  ///
  /// In en, this message translates to:
  /// **'Who to ask: people to ask for money today.'**
  String get helpWhoToAsk;

  /// No description provided for @helpStock.
  ///
  /// In en, this message translates to:
  /// **'Stock: see what is running low.'**
  String get helpStock;

  /// No description provided for @dataTitle.
  ///
  /// In en, this message translates to:
  /// **'Your data and privacy'**
  String get dataTitle;

  /// No description provided for @dataExport.
  ///
  /// In en, this message translates to:
  /// **'Download all shop data (Excel)'**
  String get dataExport;

  /// No description provided for @dataExportHelp.
  ///
  /// In en, this message translates to:
  /// **'Customers, entries, stock and day closings, plus a full copy (JSON). Free, always.'**
  String get dataExportHelp;

  /// No description provided for @dataExporting.
  ///
  /// In en, this message translates to:
  /// **'Preparing your file…'**
  String get dataExporting;

  /// No description provided for @duesReport.
  ///
  /// In en, this message translates to:
  /// **'Dues report (PDF)'**
  String get duesReport;

  /// No description provided for @duesReportHelp.
  ///
  /// In en, this message translates to:
  /// **'Everyone who owes, highest first, to print or share.'**
  String get duesReportHelp;

  /// No description provided for @duesReportTitle.
  ///
  /// In en, this message translates to:
  /// **'{shop}: dues on {date}'**
  String duesReportTitle(String shop, String date);

  /// No description provided for @duesTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} customers owe {amount} in total'**
  String duesTotal(int count, String amount);

  /// No description provided for @sharePdf.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get sharePdf;

  /// No description provided for @pageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String pageOf(int page, int total);

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Bring customers from another app'**
  String get importTitle;

  /// No description provided for @importHelp.
  ///
  /// In en, this message translates to:
  /// **'Khatabook, OkCredit or Shopbook: export to Excel or CSV there, then pick the file here. You see everything before it is saved.'**
  String get importHelp;

  /// No description provided for @importPickFile.
  ///
  /// In en, this message translates to:
  /// **'Pick an Excel or CSV file'**
  String get importPickFile;

  /// No description provided for @importSpeak.
  ///
  /// In en, this message translates to:
  /// **'Say customers one by one'**
  String get importSpeak;

  /// No description provided for @importSpeakHelp.
  ///
  /// In en, this message translates to:
  /// **'Say a name and what they owe, like \"Ravi annai 1500\". Tap Stop when done.'**
  String get importSpeakHelp;

  /// No description provided for @importStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get importStop;

  /// No description provided for @columnName.
  ///
  /// In en, this message translates to:
  /// **'Name column'**
  String get columnName;

  /// No description provided for @columnPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone column'**
  String get columnPhone;

  /// No description provided for @columnBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance column'**
  String get columnBalance;

  /// No description provided for @columnNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get columnNone;

  /// No description provided for @importFlipSign.
  ///
  /// In en, this message translates to:
  /// **'Balances are the other way round'**
  String get importFlipSign;

  /// No description provided for @importSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} customers · {amount} owed'**
  String importSummary(int count, String amount);

  /// No description provided for @importDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Already in your list'**
  String get importDuplicate;

  /// No description provided for @importNoName.
  ///
  /// In en, this message translates to:
  /// **'No name'**
  String get importNoName;

  /// No description provided for @importAdvance.
  ///
  /// In en, this message translates to:
  /// **'Paid in advance'**
  String get importAdvance;

  /// No description provided for @importSave.
  ///
  /// In en, this message translates to:
  /// **'Save {count} customers'**
  String importSave(int count);

  /// No description provided for @importDone.
  ///
  /// In en, this message translates to:
  /// **'{count} customers added'**
  String importDone(int count);

  /// No description provided for @importUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read that file. Export it again as Excel (.xlsx) or CSV.'**
  String get importUnreadable;

  /// No description provided for @importOpeningNote.
  ///
  /// In en, this message translates to:
  /// **'Opening balance (imported)'**
  String get importOpeningNote;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy notice'**
  String get privacyTitle;

  /// No description provided for @privacyWhatTitle.
  ///
  /// In en, this message translates to:
  /// **'What we keep'**
  String get privacyWhatTitle;

  /// No description provided for @privacyWhat.
  ///
  /// In en, this message translates to:
  /// **'Your phone number to sign in. Your shop\'s customers (name, phone if you add it, village, pay day), their credit and payments, sales, expenses, stock and day closings. Voice clips only when the phone can\'t understand you, deleted within a day.'**
  String get privacyWhat;

  /// No description provided for @privacyWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get privacyWhyTitle;

  /// No description provided for @privacyWhy.
  ///
  /// In en, this message translates to:
  /// **'Only to keep your shop\'s books, remind customers who agreed to reminders, and show who to ask. No ads, ever. We never sell or share data.'**
  String get privacyWhy;

  /// No description provided for @privacyWhoTitle.
  ///
  /// In en, this message translates to:
  /// **'Who sees it'**
  String get privacyWhoTitle;

  /// No description provided for @privacyWho.
  ///
  /// In en, this message translates to:
  /// **'Only people you add to your shop, each by their role: helpers never see profit or trust scores. A customer sees only their own statement, through a link you send.'**
  String get privacyWho;

  /// No description provided for @privacyKeepTitle.
  ///
  /// In en, this message translates to:
  /// **'How long'**
  String get privacyKeepTitle;

  /// No description provided for @privacyKeep.
  ///
  /// In en, this message translates to:
  /// **'As long as the shop uses the app. If you delete the shop, everything goes at once; nightly backups are kept 30 days and then deleted.'**
  String get privacyKeep;

  /// No description provided for @privacyRightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your rights'**
  String get privacyRightsTitle;

  /// No description provided for @privacyRights.
  ///
  /// In en, this message translates to:
  /// **'Download all your data here at any time, free. Erase a customer who owes nothing. Delete your account or the shop. Customers can reply STOP to any reminder.'**
  String get privacyRights;

  /// No description provided for @privacyContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get privacyContactTitle;

  /// No description provided for @privacyContact.
  ///
  /// In en, this message translates to:
  /// **'Data Protection Officer: privacy@shopcompanion.lk. Under Sri Lanka\'s Personal Data Protection Act No. 9 of 2022.'**
  String get privacyContact;

  /// No description provided for @eraseCustomer.
  ///
  /// In en, this message translates to:
  /// **'Erase this customer'**
  String get eraseCustomer;

  /// No description provided for @eraseCustomerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Erase {name} and their details? The amounts stay in your books without the name. This cannot be undone.'**
  String eraseCustomerConfirm(String name);

  /// No description provided for @eraseNeedsZero.
  ///
  /// In en, this message translates to:
  /// **'Settle the balance first: only a customer who owes nothing can be erased.'**
  String get eraseNeedsZero;

  /// No description provided for @customerErased.
  ///
  /// In en, this message translates to:
  /// **'Customer erased'**
  String get customerErased;

  /// No description provided for @erase.
  ///
  /// In en, this message translates to:
  /// **'Erase'**
  String get erase;

  /// No description provided for @deleteShop.
  ///
  /// In en, this message translates to:
  /// **'Delete this shop'**
  String get deleteShop;

  /// No description provided for @deleteShopHelp.
  ///
  /// In en, this message translates to:
  /// **'Deletes every customer, entry and file of the shop, for everyone. Download your data first.'**
  String get deleteShopHelp;

  /// No description provided for @deleteShopConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type {name} to confirm'**
  String deleteShopConfirm(String name);

  /// No description provided for @deleteShopMismatch.
  ///
  /// In en, this message translates to:
  /// **'That isn\'t the shop\'s name.'**
  String get deleteShopMismatch;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountHelp.
  ///
  /// In en, this message translates to:
  /// **'Removes you from the shop and deletes your login. The shop\'s books stay with the owner.'**
  String get deleteAccountHelp;

  /// No description provided for @deleteAccountOwner.
  ///
  /// In en, this message translates to:
  /// **'You own this shop: delete the shop first, then your account.'**
  String get deleteAccountOwner;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete your account? This cannot be undone.'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteConfirm;
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
