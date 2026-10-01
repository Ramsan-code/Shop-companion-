/// Sri Lankan mobile numbers (PRD 2: launch market). Mirrors
/// `functions/src/phone.ts` so the app rejects what the server would.
///
/// Accepts 07XXXXXXXX, 7XXXXXXXX, 947XXXXXXXX and +947XXXXXXXX with spaces
/// or dashes, and returns +947XXXXXXXX, or null.
String? normalizeLkMobile(String input) {
  final digits = input.replaceAll(RegExp(r'[\s\-()]'), '');
  final match = RegExp(r'^(?:\+94|0094|94|0)?(7\d{8})$').firstMatch(digits);
  return match == null ? null : '+94${match.group(1)}';
}
