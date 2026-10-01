import { GoogleAuth } from 'google-auth-library';

/**
 * Speech-to-text adapter (PRD 8.1: external providers only behind adapter
 * modules, so the R0 benchmark winner can be swapped in without an app update).
 */
export interface RecognizeRequest {
  audio: Buffer;
  /** BCP-47, e.g. ta-LK. */
  languageCode: string;
  /** This shop's customer names, to bias recognition towards them. */
  phrases: string[];
}

export interface RecognizeResult {
  transcript: string;
  alternatives: string[];
  confidence: number | null;
}

export interface SpeechProvider {
  recognize(request: RecognizeRequest): Promise<RecognizeResult>;
}

interface GoogleRecognizeResponse {
  results?: { alternatives?: { transcript?: string; confidence?: number }[] }[];
}

/** Turns a Cloud Speech v1 response into one transcript plus alternatives. */
export function fromGoogleResponse(response: GoogleRecognizeResponse): RecognizeResult {
  const results = response.results ?? [];
  const transcript = results
    .map((r) => r.alternatives?.[0]?.transcript?.trim() ?? '')
    .filter(Boolean)
    .join(' ');
  // Alternatives only make sense for a single-utterance result.
  const alternatives =
    results.length === 1
      ? (results[0]!.alternatives ?? [])
          .slice(1)
          .map((a) => a.transcript?.trim() ?? '')
          .filter(Boolean)
      : [];
  const confidence = results.length === 1 ? (results[0]!.alternatives?.[0]?.confidence ?? null) : null;
  return { transcript, alternatives, confidence };
}

/** Google Cloud Speech-to-Text v1, AMR-WB 16 kHz clips from the app. */
export class GoogleSpeechProvider implements SpeechProvider {
  constructor(private readonly auth = new GoogleAuth({ scopes: 'https://www.googleapis.com/auth/cloud-platform' })) {}

  async recognize(request: RecognizeRequest): Promise<RecognizeResult> {
    const client = await this.auth.getClient();
    const response = await client.request<GoogleRecognizeResponse>({
      url: 'https://speech.googleapis.com/v1/speech:recognize',
      method: 'POST',
      data: {
        config: {
          encoding: 'AMR_WB',
          sampleRateHertz: 16000,
          languageCode: request.languageCode,
          maxAlternatives: 3,
          speechContexts: request.phrases.length > 0 ? [{ phrases: request.phrases.slice(0, 500) }] : [],
        },
        audio: { content: request.audio.toString('base64') },
      },
    });
    return fromGoogleResponse(response.data);
  }
}
