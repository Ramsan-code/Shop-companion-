// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'கடை துணை';

  @override
  String get tabHome => 'முகப்பு';

  @override
  String get tabCustomers => 'வாடிக்கையாளர்';

  @override
  String get tabMic => 'பேசு';

  @override
  String get tabStock => 'சரக்கு';

  @override
  String get tabMore => 'மேலும்';

  @override
  String get tabEntry => 'பதிவு';

  @override
  String get tabCloseDay => 'நாள் முடிவு';

  @override
  String get loginTitle => 'உங்கள் தொலைபேசி இலக்கம்';

  @override
  String get phoneLabel => 'தொலைபேசி இலக்கம்';

  @override
  String get continueButton => 'தொடரவும்';

  @override
  String get setupTitle => 'உங்கள் கடையின் பெயர் என்ன?';

  @override
  String get shopNameLabel => 'கடையின் பெயர்';

  @override
  String get createShopButton => 'கடையைத் தொடங்கு';

  @override
  String get devSignInTitle => 'டெவலப்பர் உள்நுழைவு';

  @override
  String get devSignInBody =>
      'போலி பின்தளம்: திரைகளைப் பார்க்க ஒரு பங்கைத் தெரிவு செய்யுங்கள்.';

  @override
  String get roleOwner => 'உரிமையாளர்';

  @override
  String get rolePartner => 'பங்காளர்';

  @override
  String get roleHelper => 'உதவியாளர்';

  @override
  String comingInPhase(int phase) {
    return 'இந்தத் திரை கட்டம் $phase இல் உருவாக்கப்படும்.';
  }

  @override
  String get signOut => 'வெளியேறு';

  @override
  String get language => 'மொழி';

  @override
  String get micTitle => 'பதிவைச் சொல்லுங்கள் அல்லது எழுதுங்கள்';

  @override
  String get micHint => 'உதாரணம்: ரவி அண்ணை 500 கடன்';

  @override
  String get parsedCustomer => 'வாடிக்கையாளர்';

  @override
  String get parsedAmount => 'தொகை';

  @override
  String get parsedType => 'வகை';

  @override
  String get parsedUnknown => 'கேட்கவில்லை';

  @override
  String get typeCredit => 'கடன்';

  @override
  String get typePayment => 'பணம் வந்தது';

  @override
  String get typeSale => 'விற்பனை';

  @override
  String get typeExpense => 'செலவு';

  @override
  String signedInAs(String shop, String role) {
    return '$shop · $role';
  }

  @override
  String otpTitle(String phone) {
    return '$phone இலக்கத்துக்கு அனுப்பிய 6 இலக்கக் குறியீட்டை உள்ளிடுங்கள்';
  }

  @override
  String get otpLabel => 'குறியீடு';

  @override
  String get otpAutoRead => 'முடிந்தால் SMS ஐ நாமே வாசிப்போம்.';

  @override
  String get verifyButton => 'உறுதிப்படுத்து';

  @override
  String get resendCode => 'குறியீட்டை மீண்டும் அனுப்பு';

  @override
  String get changeNumber => 'இலக்கத்தை மாற்று';

  @override
  String get errorPhone =>
      'இலங்கை கைபேசி இலக்கத்தை உள்ளிடுங்கள் (உதா: 077 123 4567).';

  @override
  String get errorCode =>
      'குறியீடு சரியில்லை. SMS ஐப் பார்த்து மீண்டும் முயலுங்கள்.';

  @override
  String get errorExpired => 'இது காலாவதியாகிவிட்டது. மீண்டும் தொடங்குங்கள்.';

  @override
  String get errorRateLimit =>
      'அதிக முயற்சிகள். சிறிது நேரம் கழித்து முயலுங்கள்.';

  @override
  String get errorNetwork =>
      'இணைப்பு இல்லை. சிக்னலைப் பார்த்து மீண்டும் முயலுங்கள்.';

  @override
  String get errorGeneric => 'ஏதோ தவறு நடந்தது. மீண்டும் முயலுங்கள்.';

  @override
  String get pinSetupTitle => '4 இலக்க PIN ஒன்றைத் தெரிவு செய்யுங்கள்';

  @override
  String get pinSetupBody =>
      'இந்தத் தொலைபேசியில் செயலியைத் திறக்க இதைப் பயன்படுத்துவீர்கள்.';

  @override
  String get pinConfirmTitle => 'அதே PIN ஐ மீண்டும் உள்ளிடுங்கள்';

  @override
  String get pinMismatch =>
      'PIN கள் பொருந்தவில்லை. மீண்டும் தெரிவு செய்யுங்கள்.';

  @override
  String get lockTitle => 'உங்கள் PIN ஐ உள்ளிடுங்கள்';

  @override
  String pinWrong(int count) {
    return 'PIN தவறு. இன்னும் $count முயற்சிகள் உள்ளன.';
  }

  @override
  String get useFingerprint => 'கைரேகையைப் பயன்படுத்து';

  @override
  String get fingerprintReason => 'கடை துணையைத் திற';

  @override
  String get forgotPin =>
      'PIN மறந்துவிட்டதா? OTP மூலம் மீண்டும் உள்நுழையுங்கள்';

  @override
  String get joinTitle => 'ஒரு கடையில் சேர உங்களுக்கு அழைப்பு வந்துள்ளது';

  @override
  String get joinBody => 'இந்தக் கடைக்குப் பதிவுகள் செய்யச் சேருங்கள்.';

  @override
  String get joinButton => 'கடையில் சேர்';

  @override
  String get joinInvalid =>
      'இந்த அழைப்பு இப்போது செல்லாது. உரிமையாளரிடம் புதிய அழைப்பைக் கேளுங்கள்.';

  @override
  String get joinWrongPhone =>
      'இந்த அழைப்பு வேறு ஒரு தொலைபேசி இலக்கத்துக்கு அனுப்பப்பட்டது.';

  @override
  String get joinAlreadyMember => 'நீங்கள் ஏற்கனவே ஒரு கடையில் உள்ளீர்கள்.';

  @override
  String get startOwnShop => 'பதிலாக என் சொந்தக் கடையைத் தொடங்கு';

  @override
  String get membersTitle => 'உறுப்பினர்கள்';

  @override
  String get membersEmpty =>
      'இப்போது நீங்கள் மட்டும். ஒரு பங்காளர் அல்லது உதவியாளரை அழையுங்கள்.';

  @override
  String get inviteMember => 'அழை';

  @override
  String get inviteTitle => 'உங்கள் கடைக்கு ஒருவரை அழையுங்கள்';

  @override
  String get inviteSend => 'அழைப்பை உருவாக்கிப் பகிர்';

  @override
  String inviteShareText(String shop, String role, String phone, String link) {
    return '$shop கடை உங்களை $role ஆக கடை துணையில் சேர அழைக்கிறது. Play Store இல் செயலியை நிறுவி, உங்கள் தொலைபேசியில் ($phone) இந்த இணைப்பைத் திறவுங்கள்: $link';
  }

  @override
  String get inviteCreated =>
      'அழைப்பு உருவாக்கப்பட்டது. 7 நாட்கள் செல்லுபடியாகும்.';

  @override
  String get removeMember => 'நீக்கு';

  @override
  String removeConfirm(String phone) {
    return '$phone ஐக் கடையிலிருந்து நீக்கவா? உடனடியாக அணுகல் இழக்கப்படும்.';
  }

  @override
  String get cancel => 'ரத்து';

  @override
  String get errorPermission => 'இதைச் செய்ய உங்களுக்கு அனுமதி இல்லை.';

  @override
  String syncStale(int count) {
    return '$count பதிவுகள் ஒரு நாளுக்கு மேல் ஒத்திசைக்கப்படவில்லை. இணையத்துடன் இணையுங்கள்.';
  }

  @override
  String syncPending(int count) {
    return '$count ஒத்திசைக்கக் காத்திருக்கின்றன';
  }

  @override
  String get syncOffline =>
      'இணைப்பு இல்லை: இந்தத் தொலைபேசியில் சேமிக்கப்படுகிறது';

  @override
  String get syncDone => 'அனைத்தும் ஒத்திசைக்கப்பட்டன';

  @override
  String syncConflicts(int count) {
    return '$count பதிவுகளை சேவையகம் ஏற்கவில்லை. உரிமையாளருடன் சரிபாருங்கள்.';
  }

  @override
  String get customersSearch => 'பெயர், ஊர் அல்லது இலக்கம் தேடுக';

  @override
  String get addCustomer => 'வாடிக்கையாளரைச் சேர்';

  @override
  String get editCustomer => 'வாடிக்கையாளரைத் திருத்து';

  @override
  String get customerName => 'பெயர்';

  @override
  String get customerPhone => 'தொலைபேசி (விருப்பம்)';

  @override
  String get customerVillage => 'ஊர் (விருப்பம்)';

  @override
  String get kinshipLabel => 'எப்படி அழைப்பீர்கள்';

  @override
  String get kinNone => 'பெயர் மட்டும்';

  @override
  String get kinAnnai => 'அண்ணை';

  @override
  String get kinAkka => 'அக்கா';

  @override
  String get kinAiya => 'ஐயா';

  @override
  String get kinAmma => 'அம்மா';

  @override
  String get kinThambi => 'தம்பி';

  @override
  String get kinThangachi => 'தங்கச்சி';

  @override
  String get kinMaama => 'மாமா';

  @override
  String get incomeLabel => 'முக்கிய வருமானம்';

  @override
  String get incomeFarmer => 'விவசாயம்';

  @override
  String get incomeDailyWage => 'நாள் கூலி';

  @override
  String get incomeSalaried => 'சம்பளம்';

  @override
  String get incomeBusiness => 'வியாபாரம்';

  @override
  String get incomeOther => 'வேறு';

  @override
  String get payDayLabel => 'வழமையாகச் சம்பளம் வரும் திகதி (1–31, விருப்பம்)';

  @override
  String get fromContacts => 'தொடர்புகளிலிருந்து எடு';

  @override
  String get save => 'சேமி';

  @override
  String get noCustomers =>
      'இன்னும் வாடிக்கையாளர்கள் இல்லை. முதலாவதைச் சேருங்கள்.';

  @override
  String get noResults => 'பொருத்தம் இல்லை.';

  @override
  String get owes => 'செலுத்த வேண்டியது';

  @override
  String get settled => 'தீர்ந்தது';

  @override
  String get advance => 'முற்பணம்';

  @override
  String get pendingSync => 'ஒத்திசைக்கக் காத்திருக்கிறது';

  @override
  String get giveCredit => 'கடன் கொடு';

  @override
  String get recordPayment => 'பணம் பெற்றதைப் பதி';

  @override
  String get call => 'அழை';

  @override
  String get amountLabel => 'தொகை (ரூ.)';

  @override
  String get dateLabel => 'திகதி';

  @override
  String get noteLabel => 'குறிப்பு (விருப்பம்)';

  @override
  String get methodCash => 'காசு';

  @override
  String get methodBank => 'வங்கி';

  @override
  String get methodLankaqr => 'LankaQR';

  @override
  String get methodWallet => 'வொலட்';

  @override
  String settleWithDiscount(String amount) {
    return 'மீதி $amount ஐத் தள்ளுபடி செய்து கணக்கை முடி';
  }

  @override
  String get entrySaved => 'சேமிக்கப்பட்டது';

  @override
  String get errorAmount => 'தொகையை உள்ளிடுங்கள் (உதா: 500 அல்லது 1250.50).';

  @override
  String get errorCustomerName => 'பெயரை உள்ளிடுங்கள்.';

  @override
  String get errorPayDay => '1 முதல் 31 வரையான திகதியை உள்ளிடுங்கள்.';

  @override
  String get history => 'வரலாறு';

  @override
  String get noEntries => 'இன்னும் பதிவுகள் இல்லை.';

  @override
  String get entryDeleted => 'நீக்கப்பட்டது';

  @override
  String get editEntry => 'பதிவைத் திருத்து';

  @override
  String get deleteEntry => 'பதிவை நீக்கு';

  @override
  String get deleteEntryConfirm =>
      'இந்தப் பதிவை நீக்கவா? மீதி சரிசெய்யப்படும், நீக்கம் பதிவுசெய்யப்படும்.';

  @override
  String get delete => 'நீக்கு';

  @override
  String get shareReceipt => 'பற்றுச்சீட்டைப் பகிர்';

  @override
  String get receiptTitle => 'பணப் பற்றுச்சீட்டு';

  @override
  String get receiptFrom => 'பெற்றது';

  @override
  String get receiptBalance => 'இந்தக் கொடுப்பனவுக்குப் பின் மீதி';

  @override
  String get receiptNo => 'பற்றுச்சீட்டு இல.';

  @override
  String get receiptMethod => 'செலுத்திய முறை';

  @override
  String get chooseCustomer => 'வாடிக்கையாளரைத் தெரிவு செய்யுங்கள்';

  @override
  String get typeDiscount => 'தள்ளுபடி';

  @override
  String get cannotEditEntry =>
      'இப்போது இந்தப் பதிவை உரிமையாளர் அல்லது பங்காளர் மட்டுமே மாற்றலாம்.';

  @override
  String get voiceListening =>
      'கேட்கிறது… “ரவி அண்ணை 500 கடன்” என்பது போலச் சொல்லுங்கள்';

  @override
  String get voiceThinking => 'புரிந்துகொள்கிறது…';

  @override
  String voiceHeard(String text) {
    return 'கேட்டது: “$text”';
  }

  @override
  String get voiceWhichCustomer => 'எந்த வாடிக்கையாளர்?';

  @override
  String voiceNewCustomer(String name) {
    return 'புதிய வாடிக்கையாளர்: $name';
  }

  @override
  String get voiceSpeakAgain => 'மீண்டும் பேசு';

  @override
  String get voiceSayYes => '“சரி” என்று சொல்லுங்கள் அல்லது சேமி அழுத்துங்கள்';

  @override
  String get voiceUnavailable =>
      'இந்தத் தொலைபேசியால் இப்போது தமிழ்ப் பேச்சைப் புரிய முடியவில்லை. கீழே எழுதுங்கள்.';

  @override
  String get voiceNoSpeech =>
      'எதுவும் கேட்கவில்லை. மீண்டும் பேசுங்கள் அல்லது கீழே எழுதுங்கள்.';

  @override
  String get voicePermission => 'குரல் பதிவுக்கு ஒலிவாங்கியை அனுமதியுங்கள்.';

  @override
  String get voiceNetwork =>
      'இணையம் இல்லாமல் இந்தத் தொலைபேசியில் தமிழ்ப் பேச்சு இயங்காது. கீழே எழுதுங்கள்.';

  @override
  String get customerSearchLabel => 'வாடிக்கையாளர்';

  @override
  String addAsNew(String name) {
    return '“$name” ஐப் புதிதாகச் சேர்';
  }

  @override
  String get whoToAskTitle => 'இன்று கேட்க வேண்டியவர்கள்';

  @override
  String whoToAskSummary(int count, String amount) {
    return '$count பேர் · மொத்தம் $amount';
  }

  @override
  String get whoToAskFallback =>
      'இன்றைய முழுப் பட்டியல் காலை 6 மணிக்கு வரும். இப்போதைக்கு அதிக நிலுவை உள்ளவர்கள்:';

  @override
  String get whoToAskEmpty => 'இன்று கேட்க யாரும் இல்லை.';

  @override
  String get whoToAskPaid => 'இன்று காலையிலிருந்து செலுத்திவிட்டார்';

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get snooze => 'பின்னர்';

  @override
  String get snooze3Days => '3 நாட்களில் கேள்';

  @override
  String snoozePayDay(int day) {
    return 'சம்பள நாளில் கேள் ($day)';
  }

  @override
  String get snoozed => 'பின்னருக்கு மாற்றப்பட்டது';

  @override
  String whatsAppNudge(String name, String shop, String amount) {
    return 'வணக்கம் $name, $shop கடைக் கணக்கில் $amount நிலுவையாக உள்ளது. உங்களுக்கு வசதியான நேரத்தில் செலுத்துங்கள். நன்றி.';
  }

  @override
  String get bandExcellent => 'சிறந்தது';

  @override
  String get bandGood => 'நல்லது';

  @override
  String get bandWatch => 'கவனிக்க';

  @override
  String get bandRisky => 'ஆபத்து';

  @override
  String trustScoreLabel(int score) {
    return 'நம்பிக்கை $score/100';
  }

  @override
  String get reasonNewCustomer => 'புதிய வாடிக்கையாளர்';

  @override
  String reasonOverdue(int days) {
    return 'பழைய கடன் $days நாட்களாகச் செலுத்தப்படவில்லை';
  }

  @override
  String reasonRegularPayer(int count) {
    return '3 மாதங்களில் $count முறை செலுத்தினார்';
  }

  @override
  String get reasonNoRecentPayment => '3 மாதங்களாகச் செலுத்தவில்லை';

  @override
  String reasonPaysMost(int pct) {
    return 'கடனில் பெரும்பகுதியைத் திருப்பிச் செலுத்துகிறார் ($pct%)';
  }

  @override
  String reasonPaysLittle(int pct) {
    return 'கடனில் சிறிதளவே திருப்பிச் செலுத்துகிறார் ($pct%)';
  }

  @override
  String get reasonHighBalance => 'வழமையைவிட மிக அதிகம் நிலுவை';

  @override
  String reasonLongCustomer(int months) {
    return '$months மாதங்களாக வாடிக்கையாளர்';
  }

  @override
  String get reasonSettled => 'கணக்கு தீர்ந்துள்ளது';

  @override
  String reasonPayDay(int day) {
    return '$dayஆம் திகதி சம்பள நாள்: இப்போது கேளுங்கள்';
  }

  @override
  String safeLimit(String amount) {
    return 'பாதுகாப்பான கடன் வரம்பு: $amount';
  }

  @override
  String get safeLimitOverridden => 'உரிமையாளர் அமைத்தது';

  @override
  String get changeLimit => 'வரம்பை மாற்று';

  @override
  String changeLimitTitle(String name) {
    return '$name க்கான பாதுகாப்பான கடன் வரம்பு';
  }

  @override
  String useSuggestedLimit(String amount) {
    return 'பரிந்துரைத்த வரம்பைப் பயன்படுத்து ($amount)';
  }

  @override
  String overLimitWarning(String name, String after, String limit) {
    return 'இது $name இன் நிலுவையை $after ஆக்கும். பாதுகாப்பான வரம்பு $limit.';
  }

  @override
  String get giveAnyway => 'இருந்தாலும் கடன் கொடு';
}
