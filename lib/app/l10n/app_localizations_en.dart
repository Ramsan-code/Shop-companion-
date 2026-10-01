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

  @override
  String syncStale(int count) {
    return '$count not synced for over a day. Connect to the internet.';
  }

  @override
  String syncPending(int count) {
    return '$count waiting to sync';
  }

  @override
  String get syncOffline => 'Offline: saving on this phone';

  @override
  String get syncDone => 'All synced';

  @override
  String syncConflicts(int count) {
    return '$count entries were refused by the server. Check them with the owner.';
  }

  @override
  String get customersSearch => 'Search name, village or phone';

  @override
  String get addCustomer => 'Add customer';

  @override
  String get editCustomer => 'Edit customer';

  @override
  String get customerName => 'Name';

  @override
  String get customerPhone => 'Phone (optional)';

  @override
  String get customerVillage => 'Village (optional)';

  @override
  String get kinshipLabel => 'How you address them';

  @override
  String get kinNone => 'Name only';

  @override
  String get kinAnnai => 'annai';

  @override
  String get kinAkka => 'akka';

  @override
  String get kinAiya => 'aiya';

  @override
  String get kinAmma => 'amma';

  @override
  String get kinThambi => 'thambi';

  @override
  String get kinThangachi => 'thangachi';

  @override
  String get kinMaama => 'maama';

  @override
  String get incomeLabel => 'Main income';

  @override
  String get incomeFarmer => 'Farming';

  @override
  String get incomeDailyWage => 'Daily wage';

  @override
  String get incomeSalaried => 'Salary';

  @override
  String get incomeBusiness => 'Business';

  @override
  String get incomeOther => 'Other';

  @override
  String get payDayLabel => 'Usually paid on day (1–31, optional)';

  @override
  String get fromContacts => 'Pick from contacts';

  @override
  String get save => 'Save';

  @override
  String get noCustomers => 'No customers yet. Add your first one.';

  @override
  String get noResults => 'No one matches.';

  @override
  String get owes => 'Owes';

  @override
  String get settled => 'Settled';

  @override
  String get advance => 'Paid in advance';

  @override
  String get pendingSync => 'Waiting to sync';

  @override
  String get giveCredit => 'Give credit';

  @override
  String get recordPayment => 'Record payment';

  @override
  String get call => 'Call';

  @override
  String get amountLabel => 'Amount (Rs.)';

  @override
  String get dateLabel => 'Date';

  @override
  String get noteLabel => 'Note (optional)';

  @override
  String get methodCash => 'Cash';

  @override
  String get methodBank => 'Bank';

  @override
  String get methodLankaqr => 'LankaQR';

  @override
  String get methodWallet => 'Wallet';

  @override
  String settleWithDiscount(String amount) {
    return 'Settle and write off the remaining $amount';
  }

  @override
  String get entrySaved => 'Saved';

  @override
  String get errorAmount => 'Enter an amount, like 500 or 1250.50.';

  @override
  String get errorCustomerName => 'Enter a name.';

  @override
  String get errorPayDay => 'Use a day from 1 to 31.';

  @override
  String get history => 'History';

  @override
  String get noEntries => 'No entries yet.';

  @override
  String get entryDeleted => 'Deleted';

  @override
  String get editEntry => 'Edit entry';

  @override
  String get deleteEntry => 'Delete entry';

  @override
  String get deleteEntryConfirm =>
      'Delete this entry? The balance will be corrected and the deletion is logged.';

  @override
  String get delete => 'Delete';

  @override
  String get shareReceipt => 'Share receipt';

  @override
  String get receiptTitle => 'Payment receipt';

  @override
  String get receiptFrom => 'Received from';

  @override
  String get receiptBalance => 'Balance after this payment';

  @override
  String get receiptNo => 'Receipt no.';

  @override
  String get receiptMethod => 'Paid by';

  @override
  String get chooseCustomer => 'Choose a customer';

  @override
  String get typeDiscount => 'Discount';

  @override
  String get cannotEditEntry =>
      'Only the owner or partner can change this entry now.';

  @override
  String get voiceListening => 'Listening… say it like “Ravi annai 500 kadan”';

  @override
  String get voiceThinking => 'Working it out…';

  @override
  String voiceHeard(String text) {
    return 'Heard: “$text”';
  }

  @override
  String get voiceWhichCustomer => 'Which customer?';

  @override
  String voiceNewCustomer(String name) {
    return 'New customer: $name';
  }

  @override
  String get voiceSpeakAgain => 'Speak again';

  @override
  String get voiceSayYes => 'Say “சரி” or tap Save';

  @override
  String get voiceUnavailable =>
      'This phone can\'t understand Tamil speech right now. Type it below.';

  @override
  String get voiceNoSpeech =>
      'Didn\'t hear anything. Speak again or type below.';

  @override
  String get voicePermission => 'Allow the microphone to use voice entry.';

  @override
  String get voiceNetwork =>
      'No Tamil speech without internet on this phone. Type it below.';

  @override
  String get customerSearchLabel => 'Customer';

  @override
  String addAsNew(String name) {
    return 'Add “$name” as new';
  }

  @override
  String get whoToAskTitle => 'Who to ask today';

  @override
  String whoToAskSummary(int count, String amount) {
    return '$count people · $amount due';
  }

  @override
  String get whoToAskFallback =>
      'Your full list for today arrives at 6 AM. For now, the highest dues:';

  @override
  String get whoToAskEmpty => 'Nobody to ask today.';

  @override
  String get whoToAskPaid => 'Paid since this morning';

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get snooze => 'Later';

  @override
  String get snooze3Days => 'Ask in 3 days';

  @override
  String snoozePayDay(int day) {
    return 'Ask on pay day ($day)';
  }

  @override
  String get snoozed => 'Moved to later';

  @override
  String whatsAppNudge(String name, String shop, String amount) {
    return 'Hello $name, $shop shows $amount due on your account. Please pay when it suits you. Thank you.';
  }

  @override
  String get bandExcellent => 'Excellent';

  @override
  String get bandGood => 'Good';

  @override
  String get bandWatch => 'Watch';

  @override
  String get bandRisky => 'Risky';

  @override
  String trustScoreLabel(int score) {
    return 'Trust $score/100';
  }

  @override
  String get reasonNewCustomer => 'New customer';

  @override
  String reasonOverdue(int days) {
    return 'Oldest credit unpaid for $days days';
  }

  @override
  String reasonRegularPayer(int count) {
    return 'Paid $count times in 3 months';
  }

  @override
  String get reasonNoRecentPayment => 'No payment in 3 months';

  @override
  String reasonPaysMost(int pct) {
    return 'Pays back most of the credit ($pct%)';
  }

  @override
  String reasonPaysLittle(int pct) {
    return 'Pays back little of the credit ($pct%)';
  }

  @override
  String get reasonHighBalance => 'Owes much more than usual';

  @override
  String reasonLongCustomer(int months) {
    return 'Customer for $months months';
  }

  @override
  String get reasonSettled => 'Account settled';

  @override
  String reasonPayDay(int day) {
    return 'Pay day is the ${day}th: ask now';
  }

  @override
  String safeLimit(String amount) {
    return 'Safe credit limit: $amount';
  }

  @override
  String get safeLimitOverridden => 'Set by the owner';

  @override
  String get changeLimit => 'Change limit';

  @override
  String changeLimitTitle(String name) {
    return 'Safe credit limit for $name';
  }

  @override
  String useSuggestedLimit(String amount) {
    return 'Use the suggested limit ($amount)';
  }

  @override
  String overLimitWarning(String name, String after, String limit) {
    return 'This takes $name to $after, above the safe limit of $limit.';
  }

  @override
  String get giveAnyway => 'Give the credit anyway';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get reminderSection => 'Payment reminders';

  @override
  String get reminderConsent => 'Customer agreed to get reminders';

  @override
  String get reminderConsentHelp =>
      'Needed before any automatic message is sent (PDPA).';

  @override
  String get toneShopDefault => 'Shop default';

  @override
  String get toneGentle => 'Gentle';

  @override
  String get toneNormal => 'Normal';

  @override
  String get toneFirm => 'Firm';

  @override
  String get reminderLanguage => 'Message language';

  @override
  String get previewMessage => 'Preview the message';

  @override
  String get previewNeedsSave => 'Save the customer first to preview.';

  @override
  String get shareStatement => 'Share statement';

  @override
  String statementShareText(String name, String shop, String link) {
    return '$name, here is your account at $shop. You can check it, confirm it or pay with LankaQR: $link';
  }

  @override
  String get optedOutChip => 'Stopped reminders (STOP)';

  @override
  String get disputeChip => 'Disputed the statement';

  @override
  String get autoReminders => 'Send reminders automatically';

  @override
  String get autoRemindersHelp =>
      'WhatsApp first, SMS if no WhatsApp. 8 AM–8 PM only, at most one every 3 days per customer, only with their consent.';

  @override
  String get approvalMode => 'I approve each reminder first';

  @override
  String get defaultTone => 'Default tone';

  @override
  String get lankaQrTitle => 'Your LankaQR';

  @override
  String get lankaQrHelp =>
      'Shown on statements so customers can pay you directly.';

  @override
  String get lankaQrNotSet => 'Not set yet';

  @override
  String get scanLankaQr => 'Scan your LankaQR sticker';

  @override
  String get lankaQrInvalid =>
      'That is not a LankaQR payment code. Scan the shop\'s LankaQR sticker.';

  @override
  String get pendingApproval => 'Waiting for your approval';

  @override
  String get approveAll => 'Send all';

  @override
  String get approve => 'Send';

  @override
  String get recentReminders => 'Recent';

  @override
  String get noReminders => 'No reminders yet.';

  @override
  String get statusQueued => 'Queued';

  @override
  String get statusSent => 'Sent';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusRead => 'Read';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusSkipped => 'Not sent';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusPending => 'Waiting';

  @override
  String get viaSms => 'by SMS';

  @override
  String get remindersPlanNote =>
      'Automatic reminders are part of the Plus plan.';
}
