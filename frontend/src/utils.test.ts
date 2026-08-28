import { describe, expect, it } from 'vitest';
import { escapeHtml, formatDate, validRetention } from './utils';

describe('safe display utilities', () => {
  it('escapes submitted content', () => expect(escapeHtml('<img onerror=x>')).toBe('&lt;img onerror=x&gt;'));
  it('rejects invalid dates gracefully', () => expect(formatDate('bad')).toBe('Unknown date'));
  it('enforces tier retention ranges', () => { expect(validRetention(7, false)).toBe(true); expect(validRetention(8, false)).toBe(false); expect(validRetention(365, true)).toBe(true); });
});

