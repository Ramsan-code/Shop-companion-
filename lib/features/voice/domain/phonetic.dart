/// A sound-alike key for a name, the same for Tamil script and the ways
/// speech engines and people romanise it: "ரவி", "Ravi" and "Ravee" all give
/// "rv"; "கண்ணன்" and "Kannan" give "kn".
///
/// Consonants map to broad classes (Tamil has one letter for k/g, t/d, p/b,
/// s/ch/j), vowels are dropped except a leading one, repeats collapse.
/// Stored on customers as `phoneticKeys` (PRD 10.1) and used to match the
/// heard name to the shop's own customer list.
String phoneticKey(String name) {
  final out = StringBuffer();
  for (final word in name.trim().toLowerCase().split(RegExp(r'\s+'))) {
    if (word.isEmpty) continue;
    out.write(_isTamil(word) ? _tamilKey(word) : _latinKey(word));
  }
  return _collapse(out.toString());
}

/// One key per word too, so "Ravi" finds "Ravi Kumar".
List<String> phoneticKeys(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  return {
    phoneticKey(name),
    for (final w in words) phoneticKey(w),
  }.where((k) => k.isNotEmpty).toList();
}

bool _isTamil(String s) => s.runes.any((r) => r >= 0x0B80 && r <= 0x0BFF);

const _tamilConsonants = {
  'க': 'k',
  'ங': 'n',
  'ச': 's',
  'ஞ': 'n',
  'ட': 't',
  'ண': 'n',
  'த': 't',
  'ந': 'n',
  'ப': 'p',
  'ம': 'm',
  'ய': 'y',
  'ர': 'r',
  'ல': 'l',
  'வ': 'v',
  'ழ': 'l',
  'ள': 'l',
  'ற': 'r',
  'ன': 'n',
  'ஜ': 's',
  'ஷ': 's',
  'ஸ': 's',
  'ஹ': 'h',
};

String _tamilKey(String word) {
  final out = StringBuffer();
  final chars = word.split('');
  for (var i = 0; i < chars.length; i++) {
    final c = chars[i];
    final consonant = _tamilConsonants[c];
    if (consonant != null) {
      out.write(consonant);
    } else if (i == 0 && _isIndependentVowel(c)) {
      out.write('a');
    }
    // Vowel signs, the pulli (virama) and anything else carry no consonant.
  }
  return out.toString();
}

bool _isIndependentVowel(String c) {
  final r = c.runes.first;
  return r >= 0x0B85 && r <= 0x0B94;
}

/// In Tamil names a romanised "ng" is ங்க (Thangarasa = தங்கராசா) and "nj"
/// is ஞ்ச (Anjali = அஞ்சலி), so each keeps both sounds.
const _digraphs = {
  'th': 't',
  'dh': 't',
  'ch': 's',
  'sh': 's',
  'zh': 'l',
  'ng': 'nk',
  'nj': 'ns',
  'kh': 'k',
  'gh': 'k',
  'bh': 'p',
  'ph': 'p',
};

const _latin = {
  'k': 'k',
  'g': 'k',
  'q': 'k',
  'c': 's',
  'j': 's',
  'z': 's',
  's': 's',
  'x': 's',
  't': 't',
  'd': 't',
  'p': 'p',
  'b': 'p',
  'f': 'p',
  'm': 'm',
  'n': 'n',
  'y': 'y',
  'r': 'r',
  'l': 'l',
  'v': 'v',
  'w': 'v',
  'h': 'h',
};

String _latinKey(String word) {
  final letters = word.replaceAll(RegExp('[^a-z]'), '');
  final out = StringBuffer();
  var i = 0;
  if (letters.isNotEmpty && 'aeiou'.contains(letters[0])) out.write('a');
  while (i < letters.length) {
    if (i + 1 < letters.length) {
      final pair = _digraphs[letters.substring(i, i + 2)];
      if (pair != null) {
        out.write(pair);
        i += 2;
        continue;
      }
    }
    final mapped = _latin[letters[i]];
    if (mapped != null) out.write(mapped);
    i++;
  }
  return out.toString();
}

String _collapse(String s) {
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i == 0 || s[i] != s[i - 1]) out.write(s[i]);
  }
  return out.toString();
}

/// Edit distance, for near-miss keys ("rvi" heard as "rp").
int editDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      current[j] = [
        previous[j] + 1,
        current[j - 1] + 1,
        previous[j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
    }
    previous = current;
  }
  return previous[b.length];
}
