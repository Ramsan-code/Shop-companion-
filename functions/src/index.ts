/**
 * Cloud Functions entry point. Functions are added per phase in PLAN.md.
 *
 * Phase 1: createShop, inviteMember, acceptInvite, removeMember, expireInvites.
 * Phase 2: onEntryCreated, onEntryUpdated, editEntry, deleteEntry.
 * Phase 3: parseVoice.
 * Phase 4: recalcTrustScores (also reconciles balances), buildWhoToAsk, overrideLimit.
 * Phase 5: scheduleReminders, sendReminder, approveReminders, previewReminder,
 *          createStatement, statementApi, messagingWebhook.
 * Phase 6: onCashCounted (records the day's closing).
 * Phase 7: exportShop, eraseCustomer, deleteShop, deleteMyAccount, dailyBackup.
 */
import './setup.js';

export { acceptInvite, createShop, expireInvites, inviteMember, removeMember } from './members/callables.js';
export { deleteEntry, editEntry, onEntryCreated, onEntryUpdated } from './ledger/functions.js';
export { parseVoice } from './voice/functions.js';
export { buildWhoToAsk, overrideLimit, recalcTrustScores } from './collections/functions.js';
export {
  approveReminders,
  createStatement,
  messagingWebhook,
  previewReminder,
  scheduleReminders,
  sendReminder,
  statementApi,
} from './reminders/functions.js';
export { onCashCounted } from './closing/functions.js';
export { dailyBackup, deleteMyAccount, deleteShop, eraseCustomer, exportShop } from './data/functions.js';
