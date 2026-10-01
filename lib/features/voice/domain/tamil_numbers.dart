/// Spoken number words in Sri Lankan Tamil, in Tamil script and in the
/// romanised forms speech engines often return.
///
/// Values of 100, 1000 and 100000 act as multipliers ("ஐந்து நூறு" = 500,
/// "இரண்டு ஆயிரம்" = 2000); everything else adds. Joining forms such as
/// "ஆயிரத்து" (as in "ஆயிரத்து ஐநூறு", 1500) behave like the base word.
///
/// v0 lexicon for the R0 benchmark. Native speakers extend it from the
/// benchmark misses; anything missing still works through digits or keypad.
const Map<String, int> tamilNumberWords = {
  // 1–10
  'ஒன்று': 1, 'ஒரு': 1, 'onru': 1, 'ondru': 1, 'oru': 1,
  'இரண்டு': 2, 'ரெண்டு': 2, 'irandu': 2, 'rendu': 2, 'randu': 2,
  'மூன்று': 3, 'மூணு': 3, 'moonru': 3, 'munru': 3, 'moonu': 3,
  'நான்கு': 4, 'நாலு': 4, 'naangu': 4, 'naanku': 4, 'naalu': 4,
  'ஐந்து': 5, 'அஞ்சு': 5, 'ainthu': 5, 'aindhu': 5, 'anju': 5,
  'ஆறு': 6, 'aaru': 6,
  'ஏழு': 7, 'ezhu': 7, 'elu': 7,
  'எட்டு': 8, 'ettu': 8,
  'ஒன்பது': 9, 'onpathu': 9, 'onbathu': 9,
  'பத்து': 10, 'pathu': 10, 'paththu': 10,
  // tens
  'இருபது': 20, 'irupathu': 20, 'irubathu': 20,
  'முப்பது': 30, 'muppathu': 30,
  'நாற்பது': 40, 'narpathu': 40, 'naarpathu': 40,
  'ஐம்பது': 50, 'aimpathu': 50, 'ambathu': 50, 'aimbathu': 50,
  'அறுபது': 60, 'arupathu': 60,
  'எழுபது': 70, 'ezhupathu': 70, 'elupathu': 70,
  'எண்பது': 80, 'enpathu': 80, 'enbathu': 80,
  'தொண்ணூறு': 90, 'thonnooru': 90, 'thonnuru': 90,
  // hundreds (with joining forms)
  'நூறு': 100, 'நூற்று': 100, 'நூற்றி': 100, 'nooru': 100, 'nuru': 100,
  'nootru': 100, 'nootri': 100,
  'இருநூறு': 200, 'இருநூற்று': 200, 'இருநூற்றி': 200, 'irunooru': 200,
  'முந்நூறு': 300, 'முந்நூற்று': 300, 'munnooru': 300,
  'நானூறு': 400, 'நானூற்று': 400, 'naanooru': 400,
  'ஐநூறு': 500, 'ஐந்நூறு': 500, 'ஐநூற்று': 500, 'ஐந்நூற்று': 500,
  'ainooru': 500, 'ainnooru': 500, 'anjooru': 500, 'anjuru': 500,
  'அறுநூறு': 600, 'அறுநூற்று': 600, 'arunooru': 600,
  'எழுநூறு': 700, 'எழுநூற்று': 700, 'ezhunooru': 700,
  'எண்ணூறு': 800, 'எண்ணூற்று': 800, 'ennooru': 800,
  'தொள்ளாயிரம்': 900, 'தொள்ளாயிரத்து': 900, 'thollayiram': 900,
  // thousands
  'ஆயிரம்': 1000, 'ஆயிரத்து': 1000, 'ஆயிரத்தி': 1000,
  'aayiram': 1000, 'ayiram': 1000, 'aayirathu': 1000, 'aayiraththu': 1000,
  'இரண்டாயிரம்': 2000, 'ரெண்டாயிரம்': 2000, 'இரண்டாயிரத்து': 2000,
  'rendaayiram': 2000, 'rendayiram': 2000,
  'மூவாயிரம்': 3000, 'மூவாயிரத்து': 3000, 'moovaayiram': 3000,
  'நாலாயிரம்': 4000, 'நான்காயிரம்': 4000, 'naalaayiram': 4000,
  'ஐயாயிரம்': 5000, 'ஐயாயிரத்து': 5000, 'aiyaayiram': 5000, 'aiyayiram': 5000,
  'பத்தாயிரம்': 10000, 'pathaayiram': 10000, 'pathayiram': 10000,
  'லட்சம்': 100000, 'இலட்சம்': 100000, 'latcham': 100000,
  'laksham': 100000, 'lakh': 100000,
  // English, because shopkeepers mix them in
  'hundred': 100, 'thousand': 1000,
};

/// Words worth exactly 100, 1000 or 100000 multiply what came before them.
const Set<int> _multipliers = {100, 1000, 100000};

/// Folds a run of number values into one amount.
///
/// `[2, 1000, 500]` → 2500; `[1000, 500]` → 1500; `[5, 100]` → 500.
int combineNumberValues(List<int> values) {
  var total = 0;
  var current = 0;
  for (final v in values) {
    if (_multipliers.contains(v)) {
      final scaled = (current == 0 ? 1 : current) * v;
      if (v == 100) {
        // "ஐந்து நூறு": hundreds stay open for tens and units that follow.
        current = scaled;
      } else {
        total += scaled;
        current = 0;
      }
    } else {
      current += v;
    }
  }
  return total + current;
}
