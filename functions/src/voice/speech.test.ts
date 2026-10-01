import { describe, expect, it } from 'vitest';

import { fromGoogleResponse } from './speech.js';

describe('fromGoogleResponse', () => {
  it('takes the top transcript and the other alternatives', () => {
    expect(
      fromGoogleResponse({
        results: [
          {
            alternatives: [
              { transcript: ' ரவி அண்ணை 500 கடன் ', confidence: 0.91 },
              { transcript: 'ரவி அண்ணா 500 கடன்' },
            ],
          },
        ],
      }),
    ).toEqual({ transcript: 'ரவி அண்ணை 500 கடன்', alternatives: ['ரவி அண்ணா 500 கடன்'], confidence: 0.91 });
  });

  it('joins multi-part results and handles silence', () => {
    expect(
      fromGoogleResponse({ results: [{ alternatives: [{ transcript: 'ரவி' }] }, { alternatives: [{ transcript: '500 கடன்' }] }] })
        .transcript,
    ).toBe('ரவி 500 கடன்');
    expect(fromGoogleResponse({})).toEqual({ transcript: '', alternatives: [], confidence: null });
  });
});
