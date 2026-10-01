import { initializeApp } from 'firebase-admin/app';
import { setGlobalOptions } from 'firebase-functions/v2';

/**
 * Runs before any function is defined. Imported first by every module that
 * declares functions, because ES imports are evaluated before the importing
 * module's own body (a setGlobalOptions call in index.ts would run too late).
 */
initializeApp();

/** Same region as Firestore (PRD 8.1). Switch to asia-southeast1 if the PDPA
 * cross-border guidance points there; the app's `functionsRegion` must match. */
export const REGION = 'asia-south1';

setGlobalOptions({ region: REGION, maxInstances: 10 });
