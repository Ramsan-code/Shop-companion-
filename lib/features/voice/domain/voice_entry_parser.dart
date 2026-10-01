import 'package:equatable/equatable.dart';

import 'entry_type.dart';
import 'tamil_numbers.dart';

/// What the parser understood from one spoken or typed phrase.
///
/// Nothing is saved from this directly: the confirm sheet reads it back and
/// the owner says "sari" or taps to save (PRD C1).
class ParsedEntry extends Equatable {
  const ParsedEntry({
    this.customerName,
    this.kinshipTerm,
    this.amountCents,
    this.type,
    this.ambiguousAmount = false,
  });

  /// As heard, title-cased when romanised. Phase 3 matches it against the
  /// shop's customer list by phonetic key.
  final String? customerName;

  /// Canonical kinship word: annai, akka, aiya, amma, thambi, thangachi, maama.
  final String? kinshipTerm;
  final int? amountCents;
  final EntryType? type;

  /// More than one separate number was heard ("Ravi 500 Kumar 200").
  final bool ambiguousAmount;

  bool get isComplete =>
      customerName != null && amountCents != null && type != null;

  @override
  List<Object?> get props => [
    customerName,
    kinshipTerm,
    amountCents,
    type,
    ambiguousAmount,
  ];
}

/// Rule-based v0 parser for phrases like "Ravi annai 500 kadan" or
/// "ரவி அண்ணை ஐநூறு கடன்" (PRD C1, US1).
///
/// It runs fully offline. The `parseVoice` callable (Phase 3) is the server
/// fallback when this returns an incomplete result.
class VoiceEntryParser {
  const VoiceEntryParser();

  static const Map<String, EntryType> _typeWords = {
    // credit: kadan / baaki
    'கடன்': EntryType.credit, 'கடனா': EntryType.credit,
    'பாக்கி': EntryType.credit, 'kadan': EntryType.credit,
    'kadhan': EntryType.credit, 'kaadan': EntryType.credit,
    'baaki': EntryType.credit, 'baki': EntryType.credit,
    'credit': EntryType.credit,
    // payment received
    'தந்தார்': EntryType.payment, 'தந்தாங்க': EntryType.payment,
    'கொடுத்தார்': EntryType.payment, 'கட்டினார்': EntryType.payment,
    'செலுத்தினார்': EntryType.payment, 'வரவு': EntryType.payment,
    'thanthar': EntryType.payment, 'thandhar': EntryType.payment,
    'kuduthar': EntryType.payment, 'kuduththar': EntryType.payment,
    'kattinar': EntryType.payment, 'varavu': EntryType.payment,
    'payment': EntryType.payment, 'paid': EntryType.payment,
    // sale
    'விற்பனை': EntryType.sale, 'viyabaaram': EntryType.sale,
    'virpanai': EntryType.sale, 'sale': EntryType.sale,
    // expense
    'செலவு': EntryType.expense, 'selavu': EntryType.expense,
    'chelavu': EntryType.expense, 'expense': EntryType.expense,
  };

  static const Map<String, String> _kinshipWords = {
    'அண்ணை': 'annai',
    'அண்ணா': 'annai',
    'அண்ணன்': 'annai',
    'annai': 'annai',
    'anna': 'annai',
    'annan': 'annai',
    'anne': 'annai',
    'அக்கா': 'akka',
    'akka': 'akka',
    'akkaa': 'akka',
    'ஐயா': 'aiya',
    'aiya': 'aiya',
    'ayya': 'aiya',
    'aiyaa': 'aiya',
    'அம்மா': 'amma',
    'amma': 'amma',
    'ammaa': 'amma',
    'தம்பி': 'thambi',
    'thambi': 'thambi',
    'tambi': 'thambi',
    'தங்கச்சி': 'thangachi',
    'thangachi': 'thangachi',
    'மாமா': 'maama',
    'maama': 'maama',
    'mama': 'maama',
  };

  /// Words that carry no meaning for the entry.
  static const Set<String> _fillers = {
    'ரூபா',
    'ரூபாய்',
    'ரூ',
    'rupa',
    'rupaa',
    'rupai',
    'rupees',
    'rs',
    'ru',
    'lkr',
    'சரி',
    'sari',
    'please',
    'ok',
    'okay',
    'க்கு',
    'ku',
    'kku',
    'எழுது',
    'eluthu',
    'ezhuthu',
    'போடு',
    'podu',
  };

  static final _digitAmount = RegExp(
    r'^(?:rs\.?|ரூ\.?)?(\d{1,3}(?:,\d{3})+|\d+)(?:\.(\d{1,2}))?(.*)$',
  );

  ParsedEntry parse(String phrase) {
    final tokens = _tokenize(phrase);

    EntryType? type;
    String? kinship;
    int? kinshipIndex;
    final nameTokens = <({int index, String text})>[];
    final numberGroups = <List<int>>[];
    var fractionCents = 0;
    var lastWasNumber = false;

    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      final digits = _digitAmount.firstMatch(token);
      if (digits != null) {
        final whole = int.parse(digits.group(1)!.replaceAll(',', ''));
        _addNumber(numberGroups, whole, continueGroup: lastWasNumber);
        final fraction = digits.group(2);
        if (fraction != null) {
          fractionCents = int.parse(fraction.padRight(2, '0'));
        }
        lastWasNumber = true;
        // "500க்கு", "500kadan": the suffix may still mean something.
        final rest = digits.group(3)!;
        if (rest.isNotEmpty) {
          final restType = _typeWords[rest];
          if (restType != null) {
            type ??= restType;
            lastWasNumber = false;
          }
        }
        continue;
      }

      final number = tamilNumberWords[token];
      if (number != null) {
        _addNumber(numberGroups, number, continueGroup: lastWasNumber);
        lastWasNumber = true;
        continue;
      }
      lastWasNumber = false;

      final tokenType = _typeWords[token];
      if (tokenType != null) {
        type ??= tokenType;
        continue;
      }

      final kin = _kinshipWords[token];
      if (kin != null) {
        if (kinship == null) {
          kinship = kin;
          kinshipIndex = i;
        }
        continue;
      }

      if (_fillers.contains(token)) continue;

      nameTokens.add((index: i, text: _stripDative(token)));
    }

    return ParsedEntry(
      customerName: _pickName(nameTokens, kinshipIndex),
      kinshipTerm: kinship,
      amountCents: numberGroups.isEmpty
          ? null
          : combineNumberValues(numberGroups.first) * 100 + fractionCents,
      type: type,
      ambiguousAmount: numberGroups.length > 1,
    );
  }

  static void _addNumber(
    List<List<int>> groups,
    int value, {
    required bool continueGroup,
  }) {
    if (continueGroup && groups.isNotEmpty) {
      groups.last.add(value);
    } else {
      groups.add([value]);
    }
  }

  static List<String> _tokenize(String phrase) => phrase
      .toLowerCase()
      // Keep digits' separators; drop other punctuation.
      .replaceAll(RegExp(r'''[!?;:"'()\[\]{}–—-]'''), ' ')
      .replaceAll(RegExp(r'(?<!\d)[.,]|[.,](?!\d)'), ' ')
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();

  /// "ரவிக்கு" → "ரவி", "ravikku" → "ravi" (dative "to Ravi").
  static String _stripDative(String token) {
    for (final suffix in const ['க்கு', 'kku']) {
      if (token.endsWith(suffix) && token.length - suffix.length >= 2) {
        return token.substring(0, token.length - suffix.length);
      }
    }
    return token;
  }

  /// With a kinship word, the name is the run of words just before it
  /// ("Ravi annai"); otherwise every leftover word.
  static String? _pickName(
    List<({int index, String text})> tokens,
    int? kinshipIndex,
  ) {
    if (tokens.isEmpty) return null;
    var picked = tokens;
    if (kinshipIndex != null) {
      final before = <({int index, String text})>[];
      var expected = kinshipIndex - 1;
      for (final t in tokens.reversed) {
        if (t.index == expected) {
          before.insert(0, t);
          expected--;
        } else if (t.index < expected) {
          break;
        }
      }
      if (before.isNotEmpty) picked = before;
    }
    return picked.map((t) => _titleCase(t.text)).join(' ');
  }

  static String _titleCase(String word) {
    final first = word.codeUnitAt(0);
    final isLatin = first >= 0x61 && first <= 0x7A;
    return isLatin ? word[0].toUpperCase() + word.substring(1) : word;
  }
}
