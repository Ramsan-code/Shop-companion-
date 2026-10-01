import { describe, expect, it } from 'vitest';

import { addressee, LANGS, renderReminder, TEMPLATES, TONES, templateParams, type Kinship } from './templates.js';

const params = {
  customerName: 'Ravi',
  kinship: 'annai' as Kinship,
  shopName: 'Selvarasa Stores',
  amountCents: 150000,
  statementUrl: 'https://sc.example/s/abc123',
};

describe('D3 reminder templates', () => {
  it('has one template per tone and language', () => {
    expect(TEMPLATES).toHaveLength(TONES.length * LANGS.length);
    expect(new Set(TEMPLATES.map((t) => t.id)).size).toBe(TEMPLATES.length);
  });

  it.each(TEMPLATES.map((t) => [t.id, t] as const))('%s uses all four parameters and offers STOP', (_, t) => {
    for (const p of ['{{1}}', '{{2}}', '{{3}}', '{{4}}']) expect(t.body).toContain(p);
    expect(t.body).toContain('STOP');
    // WhatsApp utility templates may not start or end with a parameter.
    expect(t.body.trimStart().startsWith('{{')).toBe(false);
    expect(t.body.trimEnd().endsWith('}}')).toBe(false);
  });

  it('inserts the kinship term in Tamil script for Tamil messages', () => {
    const text = renderReminder('gentle', 'ta', params);
    expect(text).toContain('Ravi அண்ணை');
    expect(text).toContain('Rs. 1,500');
    expect(text).toContain('https://sc.example/s/abc123');
    expect(text).not.toMatch(/\{\{\d\}\}/);
  });

  it('keeps the Tamil kinship word in English messages', () => {
    expect(renderReminder('firm', 'en', { ...params, kinship: 'thambi', customerName: 'Kumar' })).toContain(
      'Hello Kumar thambi,',
    );
  });

  it('works without a kinship term', () => {
    expect(addressee(' Kala ', undefined, 'ta')).toBe('Kala');
  });

  it('never sends a reminder for nothing owed', () => {
    expect(() => templateParams({ ...params, amountCents: 0 }, 'ta')).toThrow(RangeError);
  });

  it('tones differ, so the preview is meaningful', () => {
    const texts = TONES.map((tone) => renderReminder(tone, 'ta', params));
    expect(new Set(texts).size).toBe(TONES.length);
  });
});
