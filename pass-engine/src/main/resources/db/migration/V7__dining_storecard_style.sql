-- Dining passes are store cards, not event tickets (fixes Movie Ticket UI).
UPDATE brands SET
  apple_style = 'storeCard',
  required_fields = '["restaurant", "booking_id"]'::jsonb,
  optional_fields = '["time", "party_size", "qr_data"]'::jsonb,
  updated_at = NOW()
WHERE id IN ('easydiner', 'zomato-dineout', 'swiggy-dineout');
