import '../setup.js';

import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { HttpsError, onCall, type CallableRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { PUBLIC_BASE_URL } from '../params.js';
import * as handlers from './handlers.js';



// App Check (Play Integrity) blocks calls from modified apps and scripts.
// The emulator can't verify tokens, so it is only enforced when deployed.
const callableOptions = { enforceAppCheck: process.env.FUNCTIONS_EMULATOR !== 'true' };

function deps(): handlers.Deps {
  return { db: getFirestore(), auth: getAuth(), now: () => new Date(), inviteBaseUrl: PUBLIC_BASE_URL.value() };
}

function caller(request: CallableRequest): handlers.Caller {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
  return { uid: request.auth.uid, phone: request.auth.token.phone_number };
}

type Data = Record<string, unknown>;

export const createShop = onCall<Data>(callableOptions, (req) => handlers.createShop(deps(), caller(req), req.data));
export const inviteMember = onCall<Data>(callableOptions, (req) => handlers.inviteMember(deps(), caller(req), req.data));
export const acceptInvite = onCall<Data>(callableOptions, (req) => handlers.acceptInvite(deps(), caller(req), req.data));
export const removeMember = onCall<Data>(callableOptions, (req) => handlers.removeMember(deps(), caller(req), req.data));

export const expireInvites = onSchedule({ schedule: 'every 6 hours', timeZone: 'Asia/Colombo' }, async () => {
  await handlers.expireInvites(deps());
});
