/**
 * Messaging adapters (PRD 8.1: external providers only from Cloud Functions,
 * through adapters, so a provider can change without an app update).
 */

export class MessagingError extends Error {
  constructor(
    message: string,
    /** The person can't receive this channel (e.g. no WhatsApp account). */
    readonly unreachable = false,
  ) {
    super(message);
  }
}

export interface TemplateMessage {
  /** E.164 without '+', e.g. 94771234567. */
  to: string;
  template: string;
  lang: 'ta' | 'en';
  bodyParams: string[];
  /** Quick-reply payloads, in button order (Confirm, Dispute). */
  buttonPayloads: string[];
}

export interface WhatsAppSender {
  sendTemplate(message: TemplateMessage): Promise<{ id: string }>;
}

export interface SmsSender {
  send(to: string, text: string): Promise<{ id: string }>;
}

/** WhatsApp error codes meaning "this number can't get WhatsApp messages". */
const UNREACHABLE = new Set([131026, 131030, 131049]);

/** Meta WhatsApp Business Cloud API, utility templates only (PRD C7). */
export class WhatsAppCloudApi implements WhatsAppSender {
  constructor(
    private readonly phoneNumberId: string,
    private readonly token: string,
    private readonly fetchImpl: typeof fetch = fetch,
  ) {}

  async sendTemplate(m: TemplateMessage): Promise<{ id: string }> {
    const response = await this.fetchImpl(`https://graph.facebook.com/v21.0/${this.phoneNumberId}/messages`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${this.token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        messaging_product: 'whatsapp',
        to: m.to,
        type: 'template',
        template: {
          name: m.template,
          language: { code: m.lang },
          components: [
            { type: 'body', parameters: m.bodyParams.map((text) => ({ type: 'text', text })) },
            ...m.buttonPayloads.map((payload, index) => ({
              type: 'button',
              sub_type: 'quick_reply',
              index: String(index),
              parameters: [{ type: 'payload', payload }],
            })),
          ],
        },
      }),
    });
    const json = (await response.json()) as { messages?: { id: string }[]; error?: { code?: number; message?: string } };
    if (!response.ok || !json.messages?.[0]) {
      const code = json.error?.code ?? response.status;
      throw new MessagingError(`whatsapp ${code}`, UNREACHABLE.has(code));
    }
    return { id: json.messages[0].id };
  }
}

/**
 * Notify.lk SMS gateway (a common Sri Lankan sender-ID gateway). One option
 * behind SmsSender; replace with the operator chosen for the pilot.
 */
export class NotifyLkSms implements SmsSender {
  constructor(
    private readonly userId: string,
    private readonly apiKey: string,
    private readonly senderId: string,
    private readonly fetchImpl: typeof fetch = fetch,
  ) {}

  async send(to: string, text: string): Promise<{ id: string }> {
    const url = new URL('https://app.notify.lk/api/v1/send');
    url.search = new URLSearchParams({
      user_id: this.userId,
      api_key: this.apiKey,
      sender_id: this.senderId,
      to,
      message: text,
      type: 'unicode', // Tamil
    }).toString();
    const response = await this.fetchImpl(url, { method: 'GET' });
    const json = (await response.json()) as { status?: string; data?: { message_id?: string | number } };
    if (!response.ok || json.status !== 'success') throw new MessagingError(`sms ${response.status}`);
    return { id: String(json.data?.message_id ?? '') };
  }
}
