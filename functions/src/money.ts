/** Formats integer cents as `Rs. 1,500` or `Rs. 1,500.50` for messages. */
export function formatLkr(cents: number): string {
  if (!Number.isInteger(cents)) throw new RangeError('cents must be an integer');
  const sign = cents < 0 ? '-' : '';
  const abs = Math.abs(cents);
  const rupees = Math.trunc(abs / 100).toLocaleString('en-US');
  const fraction = abs % 100;
  return `${sign}Rs. ${rupees}${fraction === 0 ? '' : `.${String(fraction).padStart(2, '0')}`}`;
}
