import { describe, expect, it } from 'vitest';

import { colomboHour, decideReminder, isStopReply, nextWindowStart } from './policy.js';

/** Builds a Date from a Colombo wall-clock time (UTC+05:30). */
const colombo = (iso: string) => new Date(`${iso}+05:30`);

const owing = { balanceCents: 50000, reminderConsent: true };

describe('sending window (08:00–20:00 Asia/Colombo)', () => {
  it('converts to Colombo time', () => {
    expect(colomboHour(new Date('2026-10-01T02:30:00Z'))).toBe(8);
  });

  it('sends inside the window', () => {
    expect(decideReminder(owing, colombo('2026-10-01T08:00:00'))).toEqual({ send: true });
    expect(decideReminder(owing, colombo('2026-10-01T19:59:00'))).toEqual({ send: true });
  });

  it('defers early-morning sends to 08:00 the same day', () => {
    expect(decideReminder(owing, colombo('2026-10-01T06:00:00'))).toEqual({
      send: false,
      reason: 'outside-window',
      retryAt: colombo('2026-10-01T08:00:00'),
    });
  });

  it('defers evening sends to 08:00 the next day', () => {
    expect(nextWindowStart(colombo('2026-10-01T20:00:00'))).toEqual(colombo('2026-10-02T08:00:00'));
    expect(nextWindowStart(colombo('2026-12-31T23:30:00'))).toEqual(colombo('2027-01-01T08:00:00'));
  });
});

describe('3-day cap, consent and STOP', () => {
  it('waits three days after the last reminder', () => {
    const decision = decideReminder(
      { ...owing, lastReminderAt: colombo('2026-10-01T09:00:00') },
      colombo('2026-10-03T10:00:00'),
    );
    expect(decision).toEqual({ send: false, reason: 'too-soon', retryAt: colombo('2026-10-04T09:00:00') });
  });

  it('moves a cap that ends at night into the next window', () => {
    const decision = decideReminder(
      { ...owing, lastReminderAt: colombo('2026-10-01T19:30:00') },
      colombo('2026-10-02T10:00:00'),
    );
    expect(decision).toMatchObject({ reason: 'too-soon', retryAt: colombo('2026-10-04T19:30:00') });
    const lateCap = decideReminder(
      { ...owing, lastReminderAt: colombo('2026-10-01T21:00:00') },
      colombo('2026-10-02T10:00:00'),
    );
    expect(lateCap).toMatchObject({ reason: 'too-soon', retryAt: colombo('2026-10-05T08:00:00') });
  });

  it('sends again once three days have passed', () => {
    expect(
      decideReminder({ ...owing, lastReminderAt: colombo('2026-10-01T09:00:00') }, colombo('2026-10-04T09:00:00')),
    ).toEqual({ send: true });
  });

  it('never sends after opt-out, without consent, or with nothing owed', () => {
    const noon = colombo('2026-10-01T12:00:00');
    expect(decideReminder({ ...owing, optedOutAt: noon }, noon)).toEqual({ send: false, reason: 'opted-out' });
    expect(decideReminder({ ...owing, reminderConsent: false }, noon)).toEqual({ send: false, reason: 'no-consent' });
    expect(decideReminder({ ...owing, balanceCents: 0 }, noon)).toEqual({ send: false, reason: 'nothing-owed' });
  });

  it.each(['STOP', 'stop', ' Stop. ', 'நிறுத்து', 'நிறுத்துங்கள்!', 'unsubscribe'])('treats "%s" as STOP', (text) => {
    expect(isStopReply(text)).toBe(true);
  });

  it.each(['stop sending tomorrow', 'ok', 'paid', ''])('does not treat "%s" as STOP', (text) => {
    expect(isStopReply(text)).toBe(false);
  });
});
