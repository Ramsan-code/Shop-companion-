/**
 * When a reminder may be sent (PRD C7, section 11 Messaging, TRCSL rules):
 * 08:00–20:00 Sri Lanka time, at most one per customer per 3 days, only with
 * consent, never after STOP, and only while something is owed.
 */

/** Sri Lanka is UTC+05:30 all year (no daylight saving). */
const COLOMBO_OFFSET_MS = (5 * 60 + 30) * 60_000;
const HOUR_MS = 3_600_000;

export const WINDOW_START_HOUR = 8;
export const WINDOW_END_HOUR = 20;
export const MIN_GAP_MS = 3 * 24 * HOUR_MS;

export interface ReminderCandidate {
  balanceCents: number;
  reminderConsent: boolean;
  optedOutAt?: Date | null;
  lastReminderAt?: Date | null;
}

export type Decision =
  | { send: true }
  | { send: false; reason: 'nothing-owed' | 'no-consent' | 'opted-out' }
  | { send: false; reason: 'too-soon' | 'outside-window'; retryAt: Date };

/** Hour of day (0–23) in Colombo. */
export function colomboHour(at: Date): number {
  return new Date(at.getTime() + COLOMBO_OFFSET_MS).getUTCHours();
}

/** The next moment at or after `at` that falls inside the sending window. */
export function nextWindowStart(at: Date): Date {
  const hour = colomboHour(at);
  if (hour >= WINDOW_START_HOUR && hour < WINDOW_END_HOUR) return at;
  const local = new Date(at.getTime() + COLOMBO_OFFSET_MS);
  const startLocal = Date.UTC(local.getUTCFullYear(), local.getUTCMonth(), local.getUTCDate(), WINDOW_START_HOUR);
  const dayMs = 24 * HOUR_MS;
  const start = hour >= WINDOW_END_HOUR ? startLocal + dayMs : startLocal;
  return new Date(start - COLOMBO_OFFSET_MS);
}

export function decideReminder(candidate: ReminderCandidate, now: Date): Decision {
  if (candidate.balanceCents <= 0) return { send: false, reason: 'nothing-owed' };
  if (candidate.optedOutAt) return { send: false, reason: 'opted-out' };
  if (!candidate.reminderConsent) return { send: false, reason: 'no-consent' };

  if (candidate.lastReminderAt) {
    const earliest = candidate.lastReminderAt.getTime() + MIN_GAP_MS;
    if (now.getTime() < earliest) {
      return { send: false, reason: 'too-soon', retryAt: nextWindowStart(new Date(earliest)) };
    }
  }

  const windowStart = nextWindowStart(now);
  if (windowStart.getTime() !== now.getTime()) {
    return { send: false, reason: 'outside-window', retryAt: windowStart };
  }
  return { send: true };
}

const STOP_WORDS = new Set(['stop', 'unsubscribe', 'நிறுத்து', 'நிறுத்தவும்', 'நிறுத்துங்கள்']);

/** True for a STOP reply in English or Tamil, ignoring case and punctuation. */
export function isStopReply(text: string): boolean {
  const normalized = text
    .trim()
    .toLowerCase()
    .replace(/[.!,\s]+$/u, '');
  return STOP_WORDS.has(normalized);
}
