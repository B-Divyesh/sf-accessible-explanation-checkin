export const PRODUCT_SLUG = 'accessible-explanation-checkin';

// Production is the safe default. Staging may explicitly provide the pilot
// origin at build time; that choice cannot accidentally ship as a fallback.
export const BILLING_BASE_URL = import.meta.env.VITE_BILLING_BASE_URL || 'https://api.sociobot.in';
