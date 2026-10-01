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

  @override
  String get remindersTitle => 'நினைவூட்டல்கள்';

  @override
  String get reminderSection => 'பண நினைவூட்டல்கள்';

  @override
  String get reminderConsent => 'நினைவூட்டல்கள் பெற வாடிக்கையாளர் சம்மதித்தார்';

  @override
  String get reminderConsentHelp =>
      'தானியங்கி செய்தி அனுப்ப முன் இது தேவை (தனிநபர் தரவுச் சட்டம்).';

  @override
  String get toneShopDefault => 'கடை வழமை';

  @override
  String get toneGentle => 'மென்மை';

  @override
  String get toneNormal => 'சாதாரண';

  @override
  String get toneFirm => 'உறுதி';

  @override
  String get reminderLanguage => 'செய்தி மொழி';

  @override
  String get previewMessage => 'செய்தியை முன்னோட்டம் பார்';

  @override
  String get previewNeedsSave =>
      'முன்னோட்டத்துக்கு முதலில் வாடிக்கையாளரைச் சேமியுங்கள்.';

  @override
  String get shareStatement => 'கணக்கு அறிக்கையைப் பகிர்';

  @override
  String statementShareText(String name, String shop, String link) {
    return '$name, $shop கடையில் உங்கள் கணக்கு இதோ. பார்க்கவும், உறுதிப்படுத்தவும், LankaQR மூலம் செலுத்தவும்: $link';
  }

  @override
  String get optedOutChip => 'நினைவூட்டல்களை நிறுத்தினார் (STOP)';

  @override
  String get disputeChip => 'கணக்கை மறுத்துள்ளார்';

  @override
  String get autoReminders => 'நினைவூட்டல்களைத் தானாக அனுப்பு';

  @override
  String get autoRemindersHelp =>
      'முதலில் WhatsApp, இல்லையெனில் SMS. காலை 8 – இரவு 8 மட்டும், ஒருவருக்கு 3 நாட்களுக்கு ஒன்று மட்டும், சம்மதத்துடன் மட்டும்.';

  @override
  String get approvalMode =>
      'ஒவ்வொரு நினைவூட்டலையும் முதலில் நான் அனுமதிப்பேன்';

  @override
  String get defaultTone => 'வழமையான தொனி';

  @override
  String get lankaQrTitle => 'உங்கள் LankaQR';

  @override
  String get lankaQrHelp =>
      'வாடிக்கையாளர்கள் நேரடியாகச் செலுத்த கணக்கு அறிக்கையில் காட்டப்படும்.';

  @override
  String get lankaQrNotSet => 'இன்னும் அமைக்கவில்லை';

  @override
  String get scanLankaQr => 'உங்கள் LankaQR ஸ்டிக்கரை ஸ்கேன் செய்';

  @override
  String get lankaQrInvalid =>
      'இது LankaQR கட்டணக் குறியீடு அல்ல. கடையின் LankaQR ஸ்டிக்கரை ஸ்கேன் செய்யுங்கள்.';

  @override
  String get pendingApproval => 'உங்கள் அனுமதிக்குக் காத்திருக்கின்றன';

  @override
  String get approveAll => 'அனைத்தையும் அனுப்பு';

  @override
  String get approve => 'அனுப்பு';

  @override
  String get recentReminders => 'அண்மையவை';

  @override
  String get noReminders => 'இன்னும் நினைவூட்டல்கள் இல்லை.';

  @override
  String get statusQueued => 'வரிசையில்';

  @override
  String get statusSent => 'அனுப்பப்பட்டது';

  @override
  String get statusDelivered => 'கிடைத்தது';

  @override
  String get statusRead => 'வாசிக்கப்பட்டது';

  @override
  String get statusFailed => 'தோல்வி';

  @override
  String get statusSkipped => 'அனுப்பவில்லை';

  @override
  String get statusCancelled => 'ரத்து';

  @override
  String get statusPending => 'காத்திருக்கிறது';

  @override
  String get viaSms => 'SMS மூலம்';

  @override
  String get remindersPlanNote =>
      'தானியங்கி நினைவூட்டல்கள் Plus திட்டத்தில் உள்ளன.';

  @override
  String get catGrocery => 'மளிகை';

  @override
  String get catVegetables => 'மரக்கறி';

  @override
  String get catBakery => 'பேக்கரி';

  @override
  String get catPhoneCredit => 'ரீலோட்';

  @override
  String get catOtherSale => 'வேறு விற்பனை';

  @override
  String get catStockPurchase => 'சரக்கு வாங்கியது';

  @override
  String get catTransport => 'போக்குவரத்து';

  @override
  String get catElectricity => 'மின்சாரம்';

  @override
  String get catWages => 'சம்பளம்';

  @override
  String get catRent => 'வாடகை';

  @override
  String get catOtherExpense => 'வேறு செலவு';

  @override
  String get recordSale => 'விற்பனை பதிவு';

  @override
  String get recordExpense => 'செலவு பதிவு';

  @override
  String get chooseCategory => 'எதற்கு?';

  @override
  String get paidBy => 'எப்படி?';

  @override
  String get closeDayTitle => 'இன்றைய கணக்கு முடிவு';

  @override
  String get closeDayCreditGiven => 'கொடுத்த கடன்';

  @override
  String get closeDayCollected => 'வந்த பணம்';

  @override
  String get closeDaySpent => 'செலவு';

  @override
  String get closeDayOpening => 'காலையில் இருந்த காசு';

  @override
  String get closeDayExpected => 'பெட்டியில் இருக்க வேண்டிய காசு';

  @override
  String get closeDayCountLabel => 'எண்ணிய காசு (ரூ.)';

  @override
  String get closeDaySayCount => 'தொகையைச் சொல்லுங்கள்';

  @override
  String get closeDaySave => 'நாளை முடி';

  @override
  String get closeDayMatch => 'காசு சரியாக இருக்கிறது. நன்று!';

  @override
  String closeDayShort(String amount) {
    return 'பெட்டியில் $amount குறைவு';
  }

  @override
  String closeDayOver(String amount) {
    return 'பெட்டியில் $amount அதிகம்';
  }

  @override
  String profitMirror(String amount) {
    return 'இன்று சுமார் $amount இலாபம்';
  }

  @override
  String profitMirrorLoss(String amount) {
    return 'இன்று இலாபத்தை விட செலவு $amount அதிகம்';
  }

  @override
  String profitMirrorHow(int margin) {
    return 'இது கணிப்பு: விற்பனையில் $margin%, செலவு கழித்து.';
  }

  @override
  String get closeDayListen => 'சுருக்கத்தைக் கேளுங்கள்';

  @override
  String closeDaySpoken(
    String sales,
    String collected,
    String spent,
    String profit,
  ) {
    return 'இன்று விற்பனை $sales. வந்த பணம் $collected. செலவு $spent. இலாபம் சுமார் $profit.';
  }

  @override
  String rupeesSpoken(String amount) {
    return '$amount ரூபா';
  }

  @override
  String get tomorrowTitle => 'நாளைக்கு';

  @override
  String tomorrowAsk(String name, String amount) {
    return '$name இடம் $amount கேளுங்கள்';
  }

  @override
  String tomorrowRestock(String item) {
    return '$item வாங்க வேண்டும்';
  }

  @override
  String get tomorrowNothing => 'பின்தொடர எதுவும் இல்லை.';

  @override
  String get countSaved => 'எண்ணிக்கை சேமிக்கப்பட்டது. உரிமையாளர் பார்ப்பார்.';

  @override
  String get helperCountHelp => 'பெட்டியிலுள்ள காசை எண்ணி இங்கே பதியுங்கள்.';

  @override
  String yourCount(String amount) {
    return 'உங்கள் எண்ணிக்கை: $amount';
  }

  @override
  String get closingRecorded => 'கடைக்குச் சேமிக்கப்பட்டது';

  @override
  String get stockLow => 'குறைவாக உள்ளது';

  @override
  String get stockAll => 'எல்லாப் பொருட்களும்';

  @override
  String get stockEmpty =>
      'இன்னும் பொருட்கள் இல்லை. அதிகம் விற்பவற்றைச் சேருங்கள்.';

  @override
  String get stockAdd => 'பொருள் சேர்';

  @override
  String get stockEdit => 'பொருளைத் திருத்து';

  @override
  String get stockName => 'பொருளின் பெயர்';

  @override
  String get stockUnit => 'அளவு (kg, பக்கற்)';

  @override
  String get stockQty => 'எண்ணிக்கை';

  @override
  String get stockLowAt => 'இந்த அளவில் எச்சரி';

  @override
  String get stockCost => 'வாங்கும் விலை (ரூ.)';

  @override
  String get stockPrice => 'விற்கும் விலை (ரூ.)';

  @override
  String stockLowCount(int count) {
    return '$count பொருட்கள் குறைவு';
  }

  @override
  String get stockAddOne => 'ஒன்று கூட்டு';

  @override
  String get stockTakeOne => 'ஒன்று குறை';

  @override
  String get stockUpdate => 'சரக்கு மாற்று';

  @override
  String get simpleMode => 'எளிய முறை';

  @override
  String get simpleModeHelp =>
      'பெரிய படங்கள். ஒரு பொத்தானின் ஒலிக்குறியைத் தொட்டால் அது என்ன செய்யும் என்று சொல்லும்.';

  @override
  String get hearThis => 'கேளுங்கள்';

  @override
  String get whoToAskShort => 'யாரிடம் கேட்பது';

  @override
  String get helpCredit =>
      'கடன் கொடுத்தல்: வாடிக்கையாளர் கடனாக எடுப்பதைப் பதியுங்கள்.';

  @override
  String get helpPayment =>
      'பணம் வந்தது: வாடிக்கையாளர் திருப்பித் தந்த பணத்தைப் பதியுங்கள்.';

  @override
  String get helpSale => 'விற்பனை: காசு விற்பனையைப் பதியுங்கள்.';

  @override
  String get helpExpense => 'செலவு: கடைக்குச் செலவழித்த பணத்தைப் பதியுங்கள்.';

  @override
  String get helpMic => 'பேசு: ரவி அண்ணை ஐநூறு கடன் என்று சொல்லுங்கள்.';

  @override
  String get helpCloseDay =>
      'நாள் முடிவு: காசை எண்ணி, இன்றைய இலாபத்தைப் பாருங்கள்.';

  @override
  String get helpWhoToAsk => 'யாரிடம் கேட்பது: இன்று பணம் கேட்க வேண்டியவர்கள்.';

  @override
  String get helpStock => 'சரக்கு: குறைவாக உள்ளவற்றைப் பாருங்கள்.';

  @override
  String get dataTitle => 'உங்கள் தரவும் தனியுரிமையும்';

  @override
  String get dataExport => 'கடையின் எல்லாத் தரவையும் பெறுக (Excel)';

  @override
  String get dataExportHelp =>
      'வாடிக்கையாளர், பதிவுகள், சரக்கு, நாள் முடிவுகள், முழுப் பிரதி (JSON). எப்போதும் இலவசம்.';

  @override
  String get dataExporting => 'கோப்பு தயாராகிறது…';

  @override
  String get duesReport => 'நிலுவை அறிக்கை (PDF)';

  @override
  String get duesReportHelp =>
      'நிலுவை உள்ள அனைவரும், அதிகம் முதலில். அச்சிட அல்லது பகிர.';

  @override
  String duesReportTitle(String shop, String date) {
    return '$shop: $date நிலுவை';
  }

  @override
  String duesTotal(int count, String amount) {
    return '$count வாடிக்கையாளர்கள், மொத்தம் $amount';
  }

  @override
  String get sharePdf => 'PDF பகிர்';

  @override
  String pageOf(int page, int total) {
    return 'பக்கம் $page / $total';
  }

  @override
  String get importTitle => 'வேறு செயலியிலிருந்து வாடிக்கையாளர்கள்';

  @override
  String get importHelp =>
      'Khatabook, OkCredit அல்லது Shopbook இல் Excel/CSV ஆக ஏற்றுமதி செய்து, அந்தக் கோப்பை இங்கே தெரிவு செய்யுங்கள். சேமிக்கும் முன் எல்லாவற்றையும் பார்க்கலாம்.';

  @override
  String get importPickFile => 'Excel அல்லது CSV கோப்பைத் தெரிவு செய்';

  @override
  String get importSpeak => 'வாடிக்கையாளர்களை ஒவ்வொருவராகச் சொல்லுங்கள்';

  @override
  String get importSpeakHelp =>
      'பெயரும் நிலுவையும் சொல்லுங்கள், உதாரணம் \"ரவி அண்ணை ஆயிரத்து ஐநூறு\". முடிந்ததும் நிறுத்துங்கள்.';

  @override
  String get importStop => 'நிறுத்து';

  @override
  String get columnName => 'பெயர் நெடுவரிசை';

  @override
  String get columnPhone => 'தொலைபேசி நெடுவரிசை';

  @override
  String get columnBalance => 'நிலுவை நெடுவரிசை';

  @override
  String get columnNone => 'இல்லை';

  @override
  String get importFlipSign => 'நிலுவை எதிர்த்திசையில் உள்ளது';

  @override
  String importSummary(int count, String amount) {
    return '$count வாடிக்கையாளர் · நிலுவை $amount';
  }

  @override
  String get importDuplicate => 'ஏற்கனவே பட்டியலில் உள்ளார்';

  @override
  String get importNoName => 'பெயர் இல்லை';

  @override
  String get importAdvance => 'முற்பணம்';

  @override
  String importSave(int count) {
    return '$count வாடிக்கையாளர்களைச் சேமி';
  }

  @override
  String importDone(int count) {
    return '$count வாடிக்கையாளர்கள் சேர்க்கப்பட்டனர்';
  }

  @override
  String get importUnreadable =>
      'அந்தக் கோப்பைப் படிக்க முடியவில்லை. மீண்டும் Excel (.xlsx) அல்லது CSV ஆக ஏற்றுமதி செய்யுங்கள்.';

  @override
  String get importOpeningNote => 'ஆரம்ப நிலுவை (இறக்குமதி)';

  @override
  String get privacyTitle => 'தனியுரிமை அறிவிப்பு';

  @override
  String get privacyWhatTitle => 'எதை வைத்திருக்கிறோம்';

  @override
  String get privacyWhat =>
      'உள்நுழைய உங்கள் தொலைபேசி இலக்கம். உங்கள் கடையின் வாடிக்கையாளர்கள் (பெயர், நீங்கள் சேர்த்தால் தொலைபேசி, ஊர், சம்பள நாள்), அவர்களின் கடன், பணம், விற்பனை, செலவு, சரக்கு, நாள் முடிவுகள். தொலைபேசிக்கு உங்கள் குரல் புரியாதபோது மட்டும் குரல் பதிவு; ஒரு நாளுக்குள் அழிக்கப்படும்.';

  @override
  String get privacyWhyTitle => 'ஏன்';

  @override
  String get privacyWhy =>
      'உங்கள் கடைக் கணக்குகளை வைத்திருக்கவும், சம்மதித்த வாடிக்கையாளர்களுக்கு நினைவூட்டவும், யாரிடம் கேட்பது என்று காட்டவும் மட்டுமே. விளம்பரம் ஒருபோதும் இல்லை. தரவை விற்பதோ பகிர்வதோ இல்லை.';

  @override
  String get privacyWhoTitle => 'யார் பார்க்கலாம்';

  @override
  String get privacyWho =>
      'நீங்கள் கடையில் சேர்த்தவர்கள் மட்டும், அவரவர் பங்குக்கு ஏற்ப: உதவியாளர்கள் இலாபத்தையோ நம்பிக்கை மதிப்பெண்ணையோ பார்க்க முடியாது. வாடிக்கையாளர் நீங்கள் அனுப்பும் இணைப்பில் தன் கணக்கை மட்டும் பார்க்கலாம்.';

  @override
  String get privacyKeepTitle => 'எவ்வளவு காலம்';

  @override
  String get privacyKeep =>
      'கடை செயலியைப் பயன்படுத்தும் வரை. கடையை நீக்கினால் எல்லாம் உடனே நீங்கும்; இரவுக் காப்புப் பிரதிகள் 30 நாட்களில் அழிக்கப்படும்.';

  @override
  String get privacyRightsTitle => 'உங்கள் உரிமைகள்';

  @override
  String get privacyRights =>
      'எப்போதும் இங்கே உங்கள் எல்லாத் தரவையும் இலவசமாகப் பெறலாம். நிலுவை இல்லாத வாடிக்கையாளரை அழிக்கலாம். உங்கள் கணக்கையோ கடையையோ நீக்கலாம். வாடிக்கையாளர்கள் எந்த நினைவூட்டலுக்கும் STOP என்று பதில் அனுப்பலாம்.';

  @override
  String get privacyContactTitle => 'தொடர்பு';

  @override
  String get privacyContact =>
      'தரவுப் பாதுகாப்பு அலுவலர்: privacy@shopcompanion.lk. இலங்கையின் தனிப்பட்ட தரவுப் பாதுகாப்புச் சட்டம் இல. 9, 2022 இன் கீழ்.';

  @override
  String get eraseCustomer => 'இந்த வாடிக்கையாளரை அழி';

  @override
  String eraseCustomerConfirm(String name) {
    return '$name உம் அவர் விபரங்களும் அழிக்கப்படும். தொகைகள் பெயரின்றிக் கணக்கில் இருக்கும். இதை மீளப்பெற முடியாது.';
  }

  @override
  String get eraseNeedsZero =>
      'முதலில் நிலுவையைத் தீர்க்கவும்: நிலுவை இல்லாதவரை மட்டுமே அழிக்கலாம்.';

  @override
  String get customerErased => 'வாடிக்கையாளர் அழிக்கப்பட்டார்';

  @override
  String get erase => 'அழி';

  @override
  String get deleteShop => 'இந்தக் கடையை நீக்கு';

  @override
  String get deleteShopHelp =>
      'கடையின் எல்லா வாடிக்கையாளர், பதிவுகள், கோப்புகள் எல்லோருக்கும் நீக்கப்படும். முதலில் தரவைப் பதிவிறக்குங்கள்.';

  @override
  String deleteShopConfirm(String name) {
    return 'உறுதிப்படுத்த $name என்று எழுதுங்கள்';
  }

  @override
  String get deleteShopMismatch => 'அது கடையின் பெயர் அல்ல.';

  @override
  String get deleteAccount => 'என் கணக்கை நீக்கு';

  @override
  String get deleteAccountHelp =>
      'உங்களைக் கடையிலிருந்து நீக்கி, உங்கள் உள்நுழைவை அழிக்கும். கடைக் கணக்குகள் உரிமையாளரிடம் இருக்கும்.';

  @override
  String get deleteAccountOwner =>
      'நீங்கள் இந்தக் கடையின் உரிமையாளர்: முதலில் கடையை நீக்கி, பின் கணக்கை நீக்குங்கள்.';

  @override
  String get deleteAccountConfirm =>
      'உங்கள் கணக்கை நீக்கவா? இதை மீளப்பெற முடியாது.';

  @override
  String get deleteConfirm => 'நீக்கு';
}
