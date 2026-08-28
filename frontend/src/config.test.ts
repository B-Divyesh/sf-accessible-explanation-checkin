import { describe, expect, it } from 'vitest';
import { BILLING_BASE_URL, PRODUCT_SLUG } from './config';

describe('release billing configuration', () => {
  it('uses the production Sociobot billing origin by default', () => {
    expect(BILLING_BASE_URL).toBe('https://api.sociobot.in');
    expect(`${BILLING_BASE_URL}/api/v1/products/${PRODUCT_SLUG}/checkout`).toBe(
      'https://api.sociobot.in/api/v1/products/accessible-explanation-checkin/checkout',
    );
  });
});
