/**
 * Normalises a Sri Lankan mobile number to E.164 (+947XXXXXXXX).
 * Accepts 07XXXXXXXX, 7XXXXXXXX, 947XXXXXXXX and +947XXXXXXXX, with spaces or dashes.
 * Returns null for anything else (landlines and foreign numbers can't get OTP invites).
 */
export function normalizeLkMobile(input: string): string | null {
  const digits = input.replace(/[\s\-()]/g, '');
  const match = /^(?:\+94|0094|94|0)?(7\d{8})$/.exec(digits);
  return match ? `+94${match[1]}` : null;
}
