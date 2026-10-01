/**
 * dailyBackup (PRD C9, 10.3): a managed Firestore export to Cloud Storage
 * every night, kept 30 days. Pure helpers here; the scheduler is in
 * functions.ts.
 */

export const BACKUP_KEEP_DAYS = 30;

/** `backups/2026-10-01/` for a Colombo calendar day. */
export function backupPrefix(now: Date): string {
  const colombo = new Date(now.getTime() + 5.5 * 3_600_000);
  return `backups/${colombo.toISOString().slice(0, 10)}/`;
}

/** Backup folders older than [keepDays] (by the date in their name). */
export function expiredBackups(prefixes: string[], now: Date, keepDays = BACKUP_KEEP_DAYS): string[] {
  const cutoff = backupPrefix(new Date(now.getTime() - keepDays * 86_400_000)).slice(8, 18);
  return prefixes.filter((p) => {
    const m = /^backups\/(\d{4}-\d{2}-\d{2})\/$/.exec(p);
    return m != null && m[1]! < cutoff;
  });
}
