import { FieldValue, type Firestore, Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

import type { Caller } from '../members/handlers.js';
import { entriesByCustomer, loadShopLedger, reconcileShop } from '../ledger/handlers.js';
import { formatLkr } from '../money.js';
import {
  type Band,
  type Candidate,
  DEFAULT_NEW_CUSTOMER_LIMIT_CENTS,
  type Reason,
  rankWhoToAsk,
  safeCreditLimit,
  trustScore,
  type WhoToAskItem,
} from './scoring.js';

const shopRef = (db: Firestore, shopId: string) => db.collection('shops').doc(shopId);
const scoreRef = (db: Firestore, shopId: string, customerId: string) =>
  shopRef(db, shopId).collection('customers').doc(customerId).collection('private').doc('score');

/** Colombo calendar date (UTC+05:30) as yyyy-mm-dd: the insights doc ID. */
export function colomboDate(millis: number): string {
  return new Date(millis + 5.5 * 3_600_000).toISOString().slice(0, 10);
}

/**
 * Nightly (recalcTrustScores, PRD 10.3): one read of the shop's entries
 * reconciles every balance, then writes each customer's Trust Score, plain
 * reasons and Safe Credit Limit to customers/{id}/private/score (a separate
 * document so Helpers can be blocked from it, PRD 6).
 *
 * A manual override set by the owner is kept; the effective limit is
 * `creditLimitCents` = override ?? computed.
 */
export async function nightlyShop(db: Firestore, shopId: string, now: number): Promise<{ corrected: number; scored: number }> {
  const loaded = await loadShopLedger(db, shopId);
  const { corrected, balances } = await reconcileShop(db, shopId, loaded);
  const byCustomer = entriesByCustomer(loaded.entries);
  const shop = await shopRef(db, shopId).get();
  const newCustomerLimit =
    (shop.get('settings.newCustomerLimitCents') as number | undefined) ?? DEFAULT_NEW_CUSTOMER_LIMIT_CENTS;

  const refs = loaded.customers.docs.map((c) => scoreRef(db, shopId, c.id));
  const existing = refs.length ? await db.getAll(...refs) : [];
  let batch = db.batch();
  let ops = 0;
  let scored = 0;
  for (const [i, customer] of loaded.customers.docs.entries()) {
    const balance = balances.get(customer.id) ?? { balanceCents: 0, oldestUnpaidMillis: null };
    const entries = byCustomer.get(customer.id) ?? [];
    const trust = trustScore({ now, ...balance, entries });
    const computedLimitCents = safeCreditLimit({ now, band: trust.band, entries, newCustomerLimitCents: newCustomerLimit });
    const previous = existing[i]?.data();
    const overrideLimitCents = (previous?.overrideLimitCents as number | null | undefined) ?? null;
    const next = {
      trustScore: trust.score,
      trustBand: trust.band,
      reasons: trust.reasons,
      computedLimitCents,
      overrideLimitCents,
      creditLimitCents: overrideLimitCents ?? computedLimitCents,
    };
    const unchanged =
      previous != null &&
      Object.entries(next).every(([k, v]) => JSON.stringify(previous[k] ?? null) === JSON.stringify(v));
    if (unchanged) continue;
    batch.set(refs[i]!, { ...next, updatedAt: FieldValue.serverTimestamp() });
    scored++;
    if (++ops >= 400) {
      await batch.commit();
      batch = db.batch();
      ops = 0;
    }
  }
  if (ops > 0) await batch.commit();
  return { corrected, scored };
}

/** Sends one notification to a set of devices; returns tokens that are dead. */
export interface Pusher {
  send(tokens: string[], message: { title: string; body: string; data: Record<string, string> }): Promise<string[]>;
}

export interface WhoToAskInsight {
  date: string;
  count: number;
  totalDueCents: number;
  whoToAsk: WhoToAskItem[];
}

/**
 * 06:00 Asia/Colombo (buildWhoToAsk, PRD D5, US2): rank who to ask today,
 * save it to insights/{date} (not readable by Helpers) and push a summary to
 * the Owner's and Partners' phones. The push carries a count and total only,
 * no names or per-customer amounts on the lock screen (PDPA).
 */
export async function buildWhoToAskForShop(
  deps: { db: Firestore; push: Pusher },
  shopId: string,
  now: number,
): Promise<WhoToAskInsight> {
  const { db } = deps;
  const shop = shopRef(db, shopId);
  const owing = await shop.collection('customers').where('balanceCents', '>', 0).get();
  const [scores, states] = await Promise.all([
    owing.empty ? Promise.resolve([]) : db.getAll(...owing.docs.map((c) => scoreRef(db, shopId, c.id))),
    shop.collection('collectState').get(),
  ]);
  const stateById = new Map(states.docs.map((d) => [d.id, d.data()]));
  const millis = (v: unknown) => (v instanceof Timestamp ? v.toMillis() : null);

  const candidates: Candidate[] = owing.docs.map((c, i) => {
    const score = scores[i]?.data();
    const state = stateById.get(c.id);
    return {
      customerId: c.id,
      name: (c.get('name') as string | undefined) ?? '',
      kinship: (c.get('kinshipTerm') as string | undefined) ?? null,
      balanceCents: c.get('balanceCents') as number,
      oldestUnpaidMillis: millis(c.get('oldestUnpaidAt')),
      payDay: (c.get('payDay') as number | undefined) ?? null,
      score: (score?.trustScore as number | undefined) ?? null,
      band: (score?.trustBand as Band | undefined) ?? null,
      reasons: (score?.reasons as Reason[] | undefined) ?? [],
      snoozedUntilMillis: millis(state?.snoozedUntil),
      lastContactMillis: millis(state?.lastActionAt),
    };
  });

  const whoToAsk = rankWhoToAsk(candidates, now);
  const insight: WhoToAskInsight = {
    date: colomboDate(now),
    count: whoToAsk.length,
    totalDueCents: whoToAsk.reduce((s, x) => s + x.balanceCents, 0),
    whoToAsk,
  };
  await shop
    .collection('insights')
    .doc(insight.date)
    .set({ ...insight, generatedAt: FieldValue.serverTimestamp() }, { merge: true });

  if (insight.count > 0) await notifyManagers(deps, shopId, insight);
  return insight;
}

async function notifyManagers(deps: { db: Firestore; push: Pusher }, shopId: string, insight: WhoToAskInsight) {
  const { db } = deps;
  const members = await shopRef(db, shopId).collection('members').where('status', '==', 'active').get();
  const managers = members.docs.filter((m) => ['owner', 'partner'].includes(m.get('role') as string));
  if (managers.length === 0) return;
  const users = await db.getAll(...managers.map((m) => db.collection('users').doc(m.id)));
  for (const user of users) {
    const tokens = (user.get('fcmTokens') as string[] | undefined) ?? [];
    if (tokens.length === 0) continue;
    const tamil = (user.get('locale') as string | undefined) !== 'en';
    const total = formatLkr(insight.totalDueCents);
    const dead = await deps.push.send(tokens, {
      title: tamil ? 'இன்று கேட்க வேண்டியவர்கள்' : 'Who to ask today',
      body: tamil ? `${insight.count} பேர் · மொத்தம் ${total}` : `${insight.count} people · ${total} due`,
      data: { route: '/home', date: insight.date },
    });
    if (dead.length > 0) await user.ref.update({ fcmTokens: FieldValue.arrayRemove(...dead) });
  }
}

/**
 * overrideLimit (PRD 10.3, 6): Owner always; Partner when the shop allows it
 * (settings.partnerCanOverrideLimit). null clears the override.
 */
export async function overrideLimit(
  db: Firestore,
  caller: Caller,
  data: { shopId?: unknown; customerId?: unknown; limitCents?: unknown },
): Promise<{ creditLimitCents: number | null }> {
  const shopId = typeof data.shopId === 'string' ? data.shopId : '';
  const customerId = typeof data.customerId === 'string' ? data.customerId : '';
  const limit = data.limitCents;
  if (!shopId || !customerId) throw new HttpsError('invalid-argument', 'shopId and customerId are required.');
  if (limit !== null && (!Number.isInteger(limit) || (limit as number) < 0 || (limit as number) > 1_000_000_000)) {
    throw new HttpsError('invalid-argument', 'limitCents must be a whole number of cents, or null.');
  }

  const shop = shopRef(db, shopId);
  const [member, shopDoc] = await Promise.all([shop.collection('members').doc(caller.uid).get(), shop.get()]);
  if (!member.exists || member.get('status') !== 'active') throw new HttpsError('permission-denied', 'Not a member.');
  const role = member.get('role') as string;
  const perms = ((await db.collection('roles').doc(role).get()).get('permissions') as string[] | undefined) ?? [];
  const allowed =
    perms.includes('limit:override') || (role === 'partner' && shopDoc.get('settings.partnerCanOverrideLimit') === true);
  if (!allowed) throw new HttpsError('permission-denied', 'Only the owner can change credit limits.');

  return db.runTransaction(async (tx) => {
    const customer = await tx.get(shop.collection('customers').doc(customerId));
    if (!customer.exists) throw new HttpsError('not-found', 'No such customer.');
    const ref = scoreRef(db, shopId, customerId);
    const score = await tx.get(ref);
    const computed = (score.get('computedLimitCents') as number | undefined) ?? null;
    const before = (score.get('creditLimitCents') as number | undefined) ?? null;
    const override = limit as number | null;
    const effective = override ?? computed;
    tx.set(ref, { overrideLimitCents: override, creditLimitCents: effective, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
    tx.create(shop.collection('auditLogs').doc(), {
      actorUid: caller.uid,
      action: 'limit.override',
      entity: 'customer',
      entityId: customerId,
      before: { creditLimitCents: before },
      after: { creditLimitCents: effective, overrideLimitCents: override },
      at: FieldValue.serverTimestamp(),
    });
    return { creditLimitCents: effective };
  });
}
