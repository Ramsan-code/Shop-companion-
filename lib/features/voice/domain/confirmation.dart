/// The spoken answer after the read-back "…சரியா?" (PRD US1: saved after
/// "sari" or one tap).
enum Confirmation { yes, no, unclear }

const _yes = {
  'சரி',
  'sari',
  'shari',
  'seri',
  'ஓம்',
  'om',
  'ohm',
  'ஆம்',
  'aam',
  'ஆமா',
  'aama',
  'ok',
  'okay',
  'yes',
  'சரி சரி',
};

const _no = {
  'இல்லை',
  'இல்ல',
  'illai',
  'illa',
  'no',
  'வேண்டாம்',
  'vendam',
  'வேணாம்',
  'venam',
  'பிழை',
  'pilai',
  'wrong',
};

Confirmation readConfirmation(String heard) {
  final words = heard
      .toLowerCase()
      .replaceAll(RegExp(r'''[.,!?'"]'''), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return Confirmation.unclear;
  // "இல்லை" anywhere wins: "சரி இல்லை" means not right.
  if (words.any(_no.contains)) return Confirmation.no;
  if (words.any(_yes.contains)) return Confirmation.yes;
  return Confirmation.unclear;
}
