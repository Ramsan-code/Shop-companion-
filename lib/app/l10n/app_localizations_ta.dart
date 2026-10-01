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
      'தொலைபேசி OTP கட்டம் 1 இல் வரும். திரைகளைப் பார்க்க ஒரு பங்கைத் தெரிவு செய்யுங்கள்.';

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
}
