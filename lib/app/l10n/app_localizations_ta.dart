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
}
