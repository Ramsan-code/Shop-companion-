import { getRemoteConfig } from 'firebase-admin/remote-config';
import { logger } from 'firebase-functions';

import type { TemplateOverrides } from '../reminders/templates.js';

/**
 * Server-side Remote Config (PRD 3, 8.1): reminder wording and feature
 * flags change without an app update or a deploy. Every value falls back
 * to the built-in default, so a missing or broken template never stops
 * reminders.
 */

const CACHE_MS = 5 * 60_000;
let cached: { at: number; values: RemoteValues } | null = null;

export interface RemoteValues {
  templates: TemplateOverrides;
}

export const DEFAULT_REMOTE: RemoteValues = { templates: {} };

/** `reminder_templates` is JSON: {"due_reminder_gentle_ta": {"body": "...", "whatsappName": "..."}}. */
export function parseTemplateOverrides(json: string | undefined): TemplateOverrides {
  if (!json) return {};
  try {
    const value: unknown = JSON.parse(json);
    if (typeof value !== 'object' || value === null || Array.isArray(value)) return {};
    const out: TemplateOverrides = {};
    for (const [id, v] of Object.entries(value as Record<string, unknown>)) {
      if (!/^due_reminder_(gentle|normal|firm)_(ta|en)$/.test(id) || typeof v !== 'object' || v === null) continue;
      const { body, whatsappName } = v as Record<string, unknown>;
      out[id] = {
        ...(typeof body === 'string' ? { body } : {}),
        ...(typeof whatsappName === 'string' ? { whatsappName } : {}),
      };
    }
    return out;
  } catch {
    return {};
  }
}

export async function loadRemote(now = Date.now()): Promise<RemoteValues> {
  if (cached && now - cached.at < CACHE_MS) return cached.values;
  let values = DEFAULT_REMOTE;
  if (process.env.FUNCTIONS_EMULATOR !== 'true') {
    try {
      const template = await getRemoteConfig().getServerTemplate();
      const config = template.evaluate();
      values = { templates: parseTemplateOverrides(config.getString('reminder_templates')) };
    } catch (e) {
      logger.warn('remote config unavailable; using defaults', { error: String(e) });
    }
  }
  cached = { at: now, values };
  return values;
}
