import { describe, expect, it } from 'vitest';

import { MessagingError, NotifyLkSms, WhatsAppCloudApi } from './providers.js';

function fakeFetch(status: number, json: unknown, calls: { url: string; init?: RequestInit }[]) {
  return (async (url: string | URL, init?: RequestInit) => {
    calls.push({ url: String(url), init });
    return new Response(JSON.stringify(json), { status });
  }) as typeof fetch;
}

describe('WhatsAppCloudApi', () => {
  it('sends a utility template with body parameters and quick-reply payloads', async () => {
    const calls: { url: string; init?: RequestInit }[] = [];
    const api = new WhatsAppCloudApi('123', 'tok', fakeFetch(200, { messages: [{ id: 'wamid.1' }] }, calls));
    const { id } = await api.sendTemplate({
      to: '94771234567',
      template: 'due_reminder_gentle_ta',
      lang: 'ta',
      bodyParams: ['Ravi அண்ணை', 'Shop', 'Rs. 500', 'https://x/s/t'],
      buttonPayloads: ['CONFIRM:t', 'DISPUTE:t'],
    });
    expect(id).toBe('wamid.1');
    expect(calls[0]!.url).toBe('https://graph.facebook.com/v21.0/123/messages');
    expect((calls[0]!.init!.headers as Record<string, string>).Authorization).toBe('Bearer tok');
    const body = JSON.parse(calls[0]!.init!.body as string);
    expect(body.template.name).toBe('due_reminder_gentle_ta');
    expect(body.template.components[0].parameters[0]).toEqual({ type: 'text', text: 'Ravi அண்ணை' });
    expect(body.template.components[2]).toEqual({
      type: 'button',
      sub_type: 'quick_reply',
      index: '1',
      parameters: [{ type: 'payload', payload: 'DISPUTE:t' }],
    });
  });

  it('marks "no WhatsApp on this number" as unreachable (SMS may follow)', async () => {
    const api = new WhatsAppCloudApi('1', 't', fakeFetch(400, { error: { code: 131026 } }, []));
    await expect(api.sendTemplate({ to: '9', template: 'x', lang: 'ta', bodyParams: [], buttonPayloads: [] })).rejects.toMatchObject({
      unreachable: true,
    });
    const other = new WhatsAppCloudApi('1', 't', fakeFetch(500, { error: { code: 1 } }, []));
    await expect(other.sendTemplate({ to: '9', template: 'x', lang: 'ta', bodyParams: [], buttonPayloads: [] })).rejects.toBeInstanceOf(
      MessagingError,
    );
  });
});

describe('NotifyLkSms', () => {
  it('sends Unicode (Tamil) SMS and reads the message id', async () => {
    const calls: { url: string }[] = [];
    const sms = new NotifyLkSms('u', 'k', 'SHOP', fakeFetch(200, { status: 'success', data: { message_id: 42 } }, calls));
    expect(await sms.send('94771234567', 'வணக்கம்')).toEqual({ id: '42' });
    const url = new URL(calls[0]!.url);
    expect(url.searchParams.get('type')).toBe('unicode');
    expect(url.searchParams.get('message')).toBe('வணக்கம்');
  });

  it('a gateway error is a MessagingError', async () => {
    const sms = new NotifyLkSms('u', 'k', 'S', fakeFetch(200, { status: 'error' }, []));
    await expect(sms.send('9', 'x')).rejects.toBeInstanceOf(MessagingError);
  });
});
