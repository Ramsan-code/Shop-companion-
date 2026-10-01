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

  @override
  String get catGrocery => 'Groceries';

  @override
  String get catVegetables => 'Vegetables';

  @override
  String get catBakery => 'Bakery';

  @override
  String get catPhoneCredit => 'Phone reload';

  @override
  String get catOtherSale => 'Other sale';

  @override
  String get catStockPurchase => 'Stock bought';

  @override
  String get catTransport => 'Transport';

  @override
  String get catElectricity => 'Electricity';

  @override
  String get catWages => 'Wages';

  @override
  String get catRent => 'Rent';

  @override
  String get catOtherExpense => 'Other expense';

  @override
  String get recordSale => 'Record a sale';

  @override
  String get recordExpense => 'Record money spent';

  @override
  String get chooseCategory => 'What for?';

  @override
  String get paidBy => 'Paid by';

  @override
  String get closeDayTitle => 'Close the day';

  @override
  String get closeDayCreditGiven => 'Credit given';

  @override
  String get closeDayCollected => 'Collected';

  @override
  String get closeDaySpent => 'Spent';

  @override
  String get closeDayOpening => 'Cash at start of day';

  @override
  String get closeDayExpected => 'Cash that should be in the drawer';

  @override
  String get closeDayCountLabel => 'Cash counted (Rs.)';

  @override
  String get closeDaySayCount => 'Say the amount';

  @override
  String get closeDaySave => 'Close the day';

  @override
  String get closeDayMatch => 'Cash matches. Well done!';

  @override
  String closeDayShort(String amount) {
    return '$amount short in the drawer';
  }

  @override
  String closeDayOver(String amount) {
    return '$amount extra in the drawer';
  }

  @override
  String profitMirror(String amount) {
    return 'Today you made about $amount';
  }

  @override
  String profitMirrorLoss(String amount) {
    return 'Today spending was $amount more than the profit';
  }

  @override
  String profitMirrorHow(int margin) {
    return 'An estimate: $margin% of sales, minus what was spent.';
  }

  @override
  String get closeDayListen => 'Hear the summary';

  @override
  String closeDaySpoken(
    String sales,
    String collected,
    String spent,
    String profit,
  ) {
    return 'Today: sales $sales, collected $collected, spent $spent. Profit about $profit.';
  }

  @override
  String rupeesSpoken(String amount) {
    return '$amount rupees';
  }

  @override
  String get tomorrowTitle => 'For tomorrow';

  @override
  String tomorrowAsk(String name, String amount) {
    return 'Ask $name for $amount';
  }

  @override
  String tomorrowRestock(String item) {
    return 'Buy more $item';
  }

  @override
  String get tomorrowNothing => 'Nothing to follow up.';

  @override
  String get countSaved => 'Count saved. The owner will see it.';

  @override
  String get helperCountHelp =>
      'Count the cash in the drawer and enter it here.';

  @override
  String yourCount(String amount) {
    return 'Your count: $amount';
  }

  @override
  String get closingRecorded => 'Saved for the shop';

  @override
  String get stockLow => 'Running low';

  @override
  String get stockAll => 'All items';

  @override
  String get stockEmpty => 'No items yet. Add what you sell most.';

  @override
  String get stockAdd => 'Add item';

  @override
  String get stockEdit => 'Edit item';

  @override
  String get stockName => 'Item name';

  @override
  String get stockUnit => 'Unit (kg, packet)';

  @override
  String get stockQty => 'Quantity';

  @override
  String get stockLowAt => 'Warn me at';

  @override
  String get stockCost => 'Buying price (Rs.)';

  @override
  String get stockPrice => 'Selling price (Rs.)';

  @override
  String stockLowCount(int count) {
    return '$count items running low';
  }

  @override
  String get stockAddOne => 'Add one';

  @override
  String get stockTakeOne => 'Take one away';

  @override
  String get stockUpdate => 'Update stock';

  @override
  String get simpleMode => 'Simple mode';

  @override
  String get simpleModeHelp =>
      'Big pictures. Tap the speaker on a button to hear what it does.';

  @override
  String get hearThis => 'Hear this';

  @override
  String get whoToAskShort => 'Who to ask';

  @override
  String get helpCredit =>
      'Give credit: write down what a customer takes on credit.';

  @override
  String get helpPayment => 'Payment: write down money a customer paid back.';

  @override
  String get helpSale => 'Sale: write down cash sales.';

  @override
  String get helpExpense => 'Expense: write down money spent for the shop.';

  @override
  String get helpMic =>
      'Speak: say the entry, like Ravi annai five hundred credit.';

  @override
  String get helpCloseDay =>
      'Close the day: count the cash and see today\'s profit.';

  @override
  String get helpWhoToAsk => 'Who to ask: people to ask for money today.';

  @override
  String get helpStock => 'Stock: see what is running low.';

  @override
  String get dataTitle => 'Your data and privacy';

  @override
  String get dataExport => 'Download all shop data (Excel)';

  @override
  String get dataExportHelp =>
      'Customers, entries, stock and day closings, plus a full copy (JSON). Free, always.';

  @override
  String get dataExporting => 'Preparing your file…';

  @override
  String get duesReport => 'Dues report (PDF)';

  @override
  String get duesReportHelp =>
      'Everyone who owes, highest first, to print or share.';

  @override
  String duesReportTitle(String shop, String date) {
    return '$shop: dues on $date';
  }

  @override
  String duesTotal(int count, String amount) {
    return '$count customers owe $amount in total';
  }

  @override
  String get sharePdf => 'Share PDF';

  @override
  String pageOf(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String get importTitle => 'Bring customers from another app';

  @override
  String get importHelp =>
      'Khatabook, OkCredit or Shopbook: export to Excel or CSV there, then pick the file here. You see everything before it is saved.';

  @override
  String get importPickFile => 'Pick an Excel or CSV file';

  @override
  String get importSpeak => 'Say customers one by one';

  @override
  String get importSpeakHelp =>
      'Say a name and what they owe, like \"Ravi annai 1500\". Tap Stop when done.';

  @override
  String get importStop => 'Stop';

  @override
  String get columnName => 'Name column';

  @override
  String get columnPhone => 'Phone column';

  @override
  String get columnBalance => 'Balance column';

  @override
  String get columnNone => 'None';

  @override
  String get importFlipSign => 'Balances are the other way round';

  @override
  String importSummary(int count, String amount) {
    return '$count customers · $amount owed';
  }

  @override
  String get importDuplicate => 'Already in your list';

  @override
  String get importNoName => 'No name';

  @override
  String get importAdvance => 'Paid in advance';

  @override
  String importSave(int count) {
    return 'Save $count customers';
  }

  @override
  String importDone(int count) {
    return '$count customers added';
  }

  @override
  String get importUnreadable =>
      'Couldn\'t read that file. Export it again as Excel (.xlsx) or CSV.';

  @override
  String get importOpeningNote => 'Opening balance (imported)';

  @override
  String get privacyTitle => 'Privacy notice';

  @override
  String get privacyWhatTitle => 'What we keep';

  @override
  String get privacyWhat =>
      'Your phone number to sign in. Your shop\'s customers (name, phone if you add it, village, pay day), their credit and payments, sales, expenses, stock and day closings. Voice clips only when the phone can\'t understand you, deleted within a day.';

  @override
  String get privacyWhyTitle => 'Why';

  @override
  String get privacyWhy =>
      'Only to keep your shop\'s books, remind customers who agreed to reminders, and show who to ask. No ads, ever. We never sell or share data.';

  @override
  String get privacyWhoTitle => 'Who sees it';

  @override
  String get privacyWho =>
      'Only people you add to your shop, each by their role: helpers never see profit or trust scores. A customer sees only their own statement, through a link you send.';

  @override
  String get privacyKeepTitle => 'How long';

  @override
  String get privacyKeep =>
      'As long as the shop uses the app. If you delete the shop, everything goes at once; nightly backups are kept 30 days and then deleted.';

  @override
  String get privacyRightsTitle => 'Your rights';

  @override
  String get privacyRights =>
      'Download all your data here at any time, free. Erase a customer who owes nothing. Delete your account or the shop. Customers can reply STOP to any reminder.';

  @override
  String get privacyContactTitle => 'Contact';

  @override
  String get privacyContact =>
      'Data Protection Officer: privacy@shopcompanion.lk. Under Sri Lanka\'s Personal Data Protection Act No. 9 of 2022.';

  @override
  String get eraseCustomer => 'Erase this customer';

  @override
  String eraseCustomerConfirm(String name) {
    return 'Erase $name and their details? The amounts stay in your books without the name. This cannot be undone.';
  }

  @override
  String get eraseNeedsZero =>
      'Settle the balance first: only a customer who owes nothing can be erased.';

  @override
  String get customerErased => 'Customer erased';

  @override
  String get erase => 'Erase';

  @override
  String get deleteShop => 'Delete this shop';

  @override
  String get deleteShopHelp =>
      'Deletes every customer, entry and file of the shop, for everyone. Download your data first.';

  @override
  String deleteShopConfirm(String name) {
    return 'Type $name to confirm';
  }

  @override
  String get deleteShopMismatch => 'That isn\'t the shop\'s name.';

  @override
  String get deleteAccount => 'Delete my account';

  @override
  String get deleteAccountHelp =>
      'Removes you from the shop and deletes your login. The shop\'s books stay with the owner.';

  @override
  String get deleteAccountOwner =>
      'You own this shop: delete the shop first, then your account.';

  @override
  String get deleteAccountConfirm =>
      'Delete your account? This cannot be undone.';

  @override
  String get deleteConfirm => 'Delete';
}
