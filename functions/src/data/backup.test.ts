import { describe, expect, it } from 'vitest';

import { parseTemplateOverrides } from '../config/remote.js';
import { renderReminder, templateFor } from '../reminders/templates.js';
import { backupPrefix, expiredBackups } from './backup.js';

describe('dailyBackup helpers', () => {
  it('names the folder by the Colombo date', () => {
    // 20:00 UTC on 30 Sep is 01:30 on 1 Oct in Colombo.
    expect(backupPrefix(new Date('2026-09-30T20:00:00Z'))).toBe('backups/2026-10-01/');
  });

  it('keeps 30 days', () => {
    const now = new Date('2026-10-31T00:00:00+05:30');
    expect(
      expiredBackups(['backups/2026-09-30/', 'backups/2026-10-01/', 'backups/2026-10-30/', 'backups/other/'], now),
    ).toEqual(['backups/2026-09-30/']);
  });
});

describe('Remote Config reminder templates', () => {
  const params = { customerName: 'Ravi', shopName: 'Kumar Stores', amountCents: 150000, statementUrl: 'https://x/s/t' };

  it('parses only known template ids', () => {
    const o = parseTemplateOverrides(
      JSON.stringify({
        due_reminder_gentle_ta: { body: 'B', whatsappName: 'due_v2' },
        anything_else: { body: 'X' },
      }),
    );
    expect(o).toEqual({ due_reminder_gentle_ta: { body: 'B', whatsappName: 'due_v2' } });
    expect(parseTemplateOverrides('not json')).toEqual({});
    expect(parseTemplateOverrides('[1]')).toEqual({});
  });

  it('uses a valid override and its WhatsApp name', () => {
    const body = 'Hi {{1}}, {{2}}: {{3}}. {{4}} Reply STOP to stop.';
    const overrides = { due_reminder_normal_en: { body, whatsappName: 'due_reminder_normal_en_v2' } };
    expect(templateFor('normal', 'en', overrides).id).toBe('due_reminder_normal_en_v2');
    expect(renderReminder('normal', 'en', params, overrides)).toBe(
      'Hi Ravi, Kumar Stores: Rs. 1,500. https://x/s/t Reply STOP to stop.',
    );
  });

  it('ignores an override that drops a parameter or STOP', () => {
    const builtIn = renderReminder('gentle', 'en', params);
    for (const body of ['Hi {{1}} {{2}} {{3}} STOP', 'Hi {{1}} {{2}} {{3}} {{4}}']) {
      expect(renderReminder('gentle', 'en', params, { due_reminder_gentle_en: { body } })).toBe(builtIn);
    }
  });
});
