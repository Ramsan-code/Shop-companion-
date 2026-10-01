import { formatLkr } from '../money.js';

/**
 * D3 respectful-tone reminder templates (PRD 4.2 rank 1).
 *
 * Each template is registered with Meta as a WhatsApp *utility* template with
 * positional parameters, and the same text is rendered locally for the
 * in-app preview and the SMS fallback.
 *
 * DRAFT: the Tamil text must be rewritten and community-tested by native
 * Sri Lankan Tamil writers before R1 (PRD R0 exit). Keep every template
 * strictly transactional (balance + statement link, no offers) so WhatsApp
 * does not reclassify it as marketing.
 */

export type Tone = 'gentle' | 'normal' | 'firm';
export type Lang = 'ta' | 'en';
export type Kinship = 'annai' | 'akka' | 'aiya' | 'amma' | 'thambi' | 'thangachi' | 'maama';

export const TONES: readonly Tone[] = ['gentle', 'normal', 'firm'];
export const LANGS: readonly Lang[] = ['ta', 'en'];

/** Kinship words as written in each language. English keeps the Tamil word. */
export const KINSHIP_TEXT: Record<Kinship, Record<Lang, string>> = {
  annai: { ta: 'அண்ணை', en: 'annai' },
  akka: { ta: 'அக்கா', en: 'akka' },
  aiya: { ta: 'ஐயா', en: 'aiya' },
  amma: { ta: 'அம்மா', en: 'amma' },
  thambi: { ta: 'தம்பி', en: 'thambi' },
  thangachi: { ta: 'தங்கச்சி', en: 'thangachi' },
  maama: { ta: 'மாமா', en: 'maama' },
};

/**
 * Positional parameters, in WhatsApp order:
 * {{1}} addressee ("Ravi அண்ணை"), {{2}} shop name, {{3}} amount, {{4}} statement link.
 */
export interface ReminderParams {
  customerName: string;
  kinship?: Kinship;
  shopName: string;
  amountCents: number;
  statementUrl: string;
}

export interface ReminderTemplate {
  /** Name registered with WhatsApp, e.g. `due_reminder_gentle_ta`. */
  id: string;
  tone: Tone;
  lang: Lang;
  body: string;
}

const STOP_TA = 'செய்திகளை நிறுத்த STOP என அனுப்புங்கள்.';
const STOP_EN = 'Reply STOP to stop these messages.';

const BODIES: Record<Lang, Record<Tone, string>> = {
  ta: {
    gentle:
      'வணக்கம் {{1}}, {{2}} கடைக் கணக்கில் {{3}} நிலுவையாக உள்ளது. ' +
      'உங்களுக்கு வசதியான நேரத்தில் செலுத்துங்கள். விபரம்: {{4}}\n' +
      `நன்றி. ${STOP_TA}`,
    normal:
      'வணக்கம் {{1}}, {{2}} கடைக் கணக்கில் {{3}} செலுத்த வேண்டியுள்ளது. ' +
      'இந்த வாரம் செலுத்த முடியுமா? விபரம்: {{4}}\n' +
      `நன்றி. ${STOP_TA}`,
    firm:
      'வணக்கம் {{1}}, {{2}} கடைக் கணக்கில் {{3}} சில காலமாக நிலுவையில் உள்ளது. ' +
      'தயவுசெய்து விரைவில் செலுத்துங்கள். விபரம்: {{4}}\n' +
      `நன்றி. ${STOP_TA}`,
  },
  en: {
    gentle:
      'Hello {{1}}, your account at {{2}} shows {{3}} due. ' +
      'Please pay whenever it suits you. Details: {{4}}\n' +
      `Thank you. ${STOP_EN}`,
    normal:
      'Hello {{1}}, {{3}} is due on your account at {{2}}. ' +
      'Could you pay this week? Details: {{4}}\n' +
      `Thank you. ${STOP_EN}`,
    firm:
      'Hello {{1}}, {{3}} has been due on your account at {{2}} for some time. ' +
      'Please pay soon. Details: {{4}}\n' +
      `Thank you. ${STOP_EN}`,
  },
};

export const TEMPLATES: readonly ReminderTemplate[] = LANGS.flatMap((lang) =>
  TONES.map((tone) => ({ id: `due_reminder_${tone}_${lang}`, tone, lang, body: BODIES[lang][tone] })),
);

export function templateFor(tone: Tone, lang: Lang): ReminderTemplate {
  const template = TEMPLATES.find((t) => t.tone === tone && t.lang === lang);
  if (!template) throw new Error(`no template for ${tone}/${lang}`);
  return template;
}

/** "Ravi அண்ணை" / "Ravi annai" / "Ravi". */
export function addressee(name: string, kinship: Kinship | undefined, lang: Lang): string {
  const trimmed = name.trim();
  return kinship ? `${trimmed} ${KINSHIP_TEXT[kinship][lang]}` : trimmed;
}

/** Parameter values in WhatsApp's positional order. */
export function templateParams(params: ReminderParams, lang: Lang): [string, string, string, string] {
  if (params.amountCents <= 0) throw new RangeError('nothing is owed');
  return [
    addressee(params.customerName, params.kinship, lang),
    params.shopName.trim(),
    formatLkr(params.amountCents),
    params.statementUrl,
  ];
}

/** Full text for the in-app tone preview and the SMS fallback. */
export function renderReminder(tone: Tone, lang: Lang, params: ReminderParams): string {
  const values = templateParams(params, lang);
  return templateFor(tone, lang).body.replace(/\{\{([1-4])\}\}/g, (_, i: string) => values[Number(i) - 1]!);
}
