import { randomBytes } from 'node:crypto';

import { FieldValue, type Firestore, Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import QRCode from 'qrcode';

import type { Pusher } from '../collections/handlers.js';
import { type Caller, requirePermission } from '../members/handlers.js';
import { balanceDelta, type EntryType } from '../ledger/balance.js';

/**
 * Customer statement link (PRD N8, US5, D8, D18): a page anyone with the
 * link can open without installing anything, showing what they owe, the
 * recent entries and the shop's LankaQR, with Confirm and Dispute.
 *
 * The token is the document ID: 192 random bits, unguessable. The page reads
 * it only through statementApi (Security Rules deny all client access), so a
 * snapshot taken at creation is all that is ever exposed.
 */

export const STATEMENT_TTL_MS = 30 * 86_400_000;
const MAX_LINES = 50;

export interface StatementLine {
  entryId: string;
  dateMillis: number;
  type: EntryType;
  amountCents: number;
}

export interface StatementSnapshot {
  shopName: string;
  customerName: string;
  kinship: string | null;
  balanceCents: number;
  lines: StatementLine[];
  lankaQrPayload: string | null;
}

/** Builds and stores a statement; returns its token. Used by the callable and by reminders. */
export async function issueStatement(db: Firestore, shopId: string, customerId: string, now: number): Promise<string> {
  const shop = db.collection('shops').doc(shopId);
  const [shopDoc, customer, entries] = await Promise.all([
    shop.get(),
    shop.collection('customers').doc(customerId).get(),
    shop.collection('entries').where('customerId', '==', customerId).get(),
  ]);
  if (!customer.exists) throw new HttpsError('not-found', 'No such customer.');
  const lines: StatementLine[] = entries.docs
    .map((d) => d.data())
    .filter((e) => e.deletedAt == null && balanceDelta(e.type as EntryType, e.amountCents as number) !== 0)
    .map((e) => ({
      entryId: e.clientId as string,
      dateMillis: ((e.txnDate ?? e.createdAt) as Timestamp).toMillis(),
      type: e.type as EntryType,
      amountCents: e.amountCents as number,
    }))
    .sort((a, b) => b.dateMillis - a.dateMillis)
    .slice(0, MAX_LINES);
  const snapshot: StatementSnapshot = {
    shopName: (shopDoc.get('name') as string | undefined) ?? '',
    customerName: (customer.get('name') as string | undefined) ?? '',
    kinship: (customer.get('kinshipTerm') as string | undefined) ?? null,
    balanceCents: (customer.get('balanceCents') as number | undefined) ?? 0,
    lines,
    lankaQrPayload: (shopDoc.get('lankaQrPayload') as string | undefined) ?? null,
  };
  const token = randomBytes(24).toString('base64url');
  await db.collection('statements').doc(token).create({
    shopId,
    customerId,
    snapshot,
    createdAt: FieldValue.serverTimestamp(),
    expiresAt: Timestamp.fromMillis(now + STATEMENT_TTL_MS),
    confirmedAt: null,
    disputedAt: null,
  });
  return token;
}

export const statementUrl = (baseUrl: string, token: string) => `${baseUrl.replace(/\/$/, '')}/s/${token}`;

/** createStatement callable: "Share statement" from the customer page. */
export async function createStatement(
  deps: { db: Firestore; baseUrl: string; now: () => number },
  caller: Caller,
  data: { shopId?: unknown; customerId?: unknown },
): Promise<{ url: string; expiresAt: string }> {
  const shopId = typeof data.shopId === 'string' ? data.shopId : '';
  const customerId = typeof data.customerId === 'string' ? data.customerId : '';
  if (!shopId || !customerId) throw new HttpsError('invalid-argument', 'shopId and customerId are required.');
  await requirePermission(deps.db, shopId, caller.uid, 'balance:read');
  const now = deps.now();
  const token = await issueStatement(deps.db, shopId, customerId, now);
  return { url: statementUrl(deps.baseUrl, token), expiresAt: new Date(now + STATEMENT_TTL_MS).toISOString() };
}

export class StatementGone extends Error {}

async function liveStatement(db: Firestore, token: string, now: number) {
  if (!/^[\w-]{20,64}$/.test(token)) throw new StatementGone();
  const doc = await db.collection('statements').doc(token).get();
  if (!doc.exists || (doc.get('expiresAt') as Timestamp).toMillis() <= now) throw new StatementGone();
  return doc;
}

/** GET /api/statement/{token}: the page's data, with the LankaQR as an SVG. */
export async function viewStatement(db: Firestore, token: string, now: number) {
  const doc = await liveStatement(db, token, now);
  const snapshot = doc.get('snapshot') as StatementSnapshot;
  const qrSvg = snapshot.lankaQrPayload
    ? await QRCode.toString(snapshot.lankaQrPayload, { type: 'svg', errorCorrectionLevel: 'M', margin: 2 })
    : null;
  return {
    ...snapshot,
    lankaQrPayload: undefined,
    qrSvg,
    confirmed: doc.get('confirmedAt') != null,
    disputed: doc.get('disputedAt') != null,
    expiresAt: (doc.get('expiresAt') as Timestamp).toDate().toISOString(),
  };
}

/**
 * Confirm or Dispute, from the page or a WhatsApp button (D18). Confirm
 * marks every entry on the statement as confirmed by the customer, which is
 * the dispute-proof record (PRD 4.2 rank 5). Dispute flags the customer and
 * tells the owner, without saying who on the lock screen.
 */
export async function statementAction(
  deps: { db: Firestore; push?: Pusher },
  token: string,
  action: 'confirm' | 'dispute',
  note: string | null,
  now: number,
): Promise<{ confirmed: boolean; disputed: boolean }> {
  const { db } = deps;
  const doc = await liveStatement(db, token, now);
  const shopId = doc.get('shopId') as string;
  const customerId = doc.get('customerId') as string;
  const shop = db.collection('shops').doc(shopId);
  const snapshot = doc.get('snapshot') as StatementSnapshot;
  const at = Timestamp.fromMillis(now);

  if (action === 'confirm') {
    if (doc.get('confirmedAt') == null && doc.get('disputedAt') == null) {
      const batch = db.batch();
      batch.update(doc.ref, { confirmedAt: at });
      for (const line of snapshot.lines) {
        batch.update(shop.collection('entries').doc(line.entryId), { confirmedAt: at });
      }
      batch.create(shop.collection('auditLogs').doc(), {
        actorUid: null,
        action: 'statement.confirm',
        entity: 'customer',
        entityId: customerId,
        before: null,
        after: { balanceCents: snapshot.balanceCents, lines: snapshot.lines.length },
        at: FieldValue.serverTimestamp(),
      });
      await batch.commit();
    }
    return { confirmed: true, disputed: doc.get('disputedAt') != null };
  }

  if (doc.get('disputedAt') == null) {
    const cleanNote = note?.trim().slice(0, 300) || null;
    const batch = db.batch();
    batch.update(doc.ref, { disputedAt: at, disputeNote: cleanNote });
    batch.update(shop.collection('customers').doc(customerId), { disputeOpenAt: at });
    batch.create(shop.collection('auditLogs').doc(), {
      actorUid: null,
      action: 'statement.dispute',
      entity: 'customer',
      entityId: customerId,
      before: null,
      after: { note: cleanNote },
      at: FieldValue.serverTimestamp(),
    });
    await batch.commit();
    await notifyOwnerOfDispute(deps, shopId);
  }
  return { confirmed: doc.get('confirmedAt') != null, disputed: true };
}

async function notifyOwnerOfDispute(deps: { db: Firestore; push?: Pusher }, shopId: string) {
  if (!deps.push) return;
  const shop = await deps.db.collection('shops').doc(shopId).get();
  const owner = await deps.db.collection('users').doc(shop.get('ownerUid') as string).get();
  const tokens = (owner.get('fcmTokens') as string[] | undefined) ?? [];
  if (tokens.length === 0) return;
  const tamil = (owner.get('locale') as string | undefined) !== 'en';
  await deps.push.send(tokens, {
    title: tamil ? 'ஒரு வாடிக்கையாளர் கணக்கை மறுத்துள்ளார்' : 'A customer disputed their statement',
    body: tamil ? 'பதிவுகளைப் பார்த்து அவருடன் பேசுங்கள்.' : 'Check the entries and talk to them.',
    data: { route: '/customers' },
  });
}
