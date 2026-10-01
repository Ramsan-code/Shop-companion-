import { defineString } from 'firebase-functions/params';

/** Firebase Hosting origin serving /invite/{token} and /s/{token}. */
export const PUBLIC_BASE_URL = defineString('PUBLIC_BASE_URL', {
  description: 'Hosting origin for invite and statement links, e.g. https://shop-companion-prod.web.app',
});
